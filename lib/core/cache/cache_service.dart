import 'dart:async';
import 'dart:convert';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/v_intent.dart';
import '../../app/constants.dart';

class CacheService {
  static final instance = CacheService._();
  CacheService._();

  Database? _db;

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final dbPath = p.join(await getDatabasesPath(), 'vanimitra.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cache_entries (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            trigger   TEXT NOT NULL,
            resolved  TEXT NOT NULL,
            type      TEXT NOT NULL,
            confirmed INTEGER NOT NULL DEFAULT 0,
            hit_count INTEGER NOT NULL DEFAULT 0,
            UNIQUE(trigger, type)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS command_log (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            transcript  TEXT,
            intent      TEXT,
            params_json TEXT,
            success     INTEGER,
            source      TEXT,
            latency_ms  INTEGER,
            language    TEXT,
            ts          INTEGER
          )
        ''');
      },
    );
  }

  // ─── Contact Import ───────────────────────────────────────────────────────
  Future<void> importContactsIfNeeded() async {
    final db = _db;
    if (db == null) return;

    // Only import once — check if any contact entries exist
    final existing = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM cache_entries WHERE type='contact'");
    final cnt = (existing.first['cnt'] as int? ?? 0);
    if (cnt > 0) return;

    final status = await Permission.contacts.request();
    if (!status.isGranted) return;

    try {
      final contacts = await ContactsService.getContacts(withThumbnails: false);
      final batch = db.batch();
      for (final c in contacts) {
        final name = (c.displayName ?? '').trim();
        if (name.isEmpty) continue;
        for (final phone in c.phones ?? <Item>[]) {
          final number = (phone.value ?? '').replaceAll(RegExp(r'\s+'), '');
          if (number.isEmpty) continue;
          batch.insert(
            'cache_entries',
            {
              'trigger': name.toLowerCase(),
              'resolved': number,
              'type': 'contact',
              'confirmed': 0,
              'hit_count': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // contacts not critical
    }
  }

  // ─── Resolve ──────────────────────────────────────────────────────────────
  Future<String?> resolve(String trigger, String type) async {
    final db = _db;
    if (db == null) return null;

    final key = _normalise(trigger);
    final rows = await db.query(
      'cache_entries',
      columns: ['resolved'],
      where: 'trigger = ? AND type = ?',
      whereArgs: [key, type],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    // bump hit count
    await db.rawUpdate(
      'UPDATE cache_entries SET hit_count = hit_count + 1 WHERE trigger = ? AND type = ?',
      [key, type],
    );
    return rows.first['resolved'] as String?;
  }

  // ─── Propose ──────────────────────────────────────────────────────────────
  Future<void> propose(
    String trigger,
    String resolved,
    String type,
    String language, {
    bool confirmed = false,
  }) async {
    final db = _db;
    if (db == null) return;

    await db.insert(
      'cache_entries',
      {
        'trigger': _normalise(trigger),
        'resolved': resolved,
        'type': type,
        'confirmed': confirmed ? 1 : 0,
        'hit_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Confirm ──────────────────────────────────────────────────────────────
  Future<void> confirm(String trigger, String type) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      'cache_entries',
      {'confirmed': 1},
      where: 'trigger = ? AND type = ?',
      whereArgs: [_normalise(trigger), type],
    );
  }

  // ─── Cache Context for LLM ───────────────────────────────────────────────
  Future<String> getContextString({int limit = 8}) async {
    final db = _db;
    if (db == null) return '';

    final rows = await db.query(
      'cache_entries',
      columns: ['trigger', 'resolved', 'type'],
      where: 'confirmed = 1',
      orderBy: 'hit_count DESC',
      limit: limit.clamp(1, VConstants.cacheContextLimit),
    );
    if (rows.isEmpty) return '';

    // Compact JSON string injected before user message in LLM prompt
    final list = rows
        .map((r) => '{"t":"${r['trigger']}","r":"${r['resolved']}","k":"${r['type']}"}')
        .join(',');
    return '\nCached mappings: [$list]\n';
  }

  // ─── Log ──────────────────────────────────────────────────────────────────
  Future<void> log(
    String transcript,
    VIntent intent,
    Map<String, dynamic> params,
    bool success,
    String source,
    int latencyMs,
    String language,
  ) async {
    final db = _db;
    if (db == null) return;
    await db.insert('command_log', {
      'transcript': transcript,
      'intent': intent.toJsonKey(),
      'params_json': jsonEncode(params),
      'success': success ? 1 : 0,
      'source': source,
      'latency_ms': latencyMs,
      'language': language,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Failures (for personalisation fine-tune trigger) ─────────────────────
  Future<List<Map<String, dynamic>>> getFailures({int limit = 100}) async {
    final db = _db;
    if (db == null) return [];
    return db.query(
      'command_log',
      where: 'success = 0',
      orderBy: 'ts DESC',
      limit: limit,
    );
  }

  // ─── Evict ────────────────────────────────────────────────────────────────
  Future<void> evict() async {
    final db = _db;
    if (db == null) return;

    // Keep only the top N entries by hit count
    await db.rawDelete('''
      DELETE FROM cache_entries WHERE id NOT IN (
        SELECT id FROM cache_entries ORDER BY hit_count DESC LIMIT ${VConstants.maxCacheEntries}
      )
    ''');
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _normalise(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
