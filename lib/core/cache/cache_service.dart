// DEV 2 — implement per PDR Section 9.6
import '../../models/v_intent.dart';
class CacheService {
  static final instance = CacheService._();
  CacheService._();
  Future<void> init() async {}
  Future<void> importContactsIfNeeded() async {}
  Future<String?> resolve(String trigger, String type) async => null;
  Future<void> propose(String trigger, String resolved, String type, String language, {bool confirmed = false}) async {}
  Future<void> confirm(String trigger, String type) async {}
  Future<String> getContextString({int limit = 8}) async => '';
  Future<void> log(String transcript, VIntent intent, Map<String, dynamic> params, bool success, String source, int latencyMs, String language) async {}
  Future<List<Map<String, dynamic>>> getFailures({int limit = 100}) async => [];
  Future<void> evict() async {}
}
