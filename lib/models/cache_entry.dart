class CacheEntry {
  final int? id;
  final String trigger;
  final String resolved;
  final String type;        // 'contact'|'location'|'app_alias'|'shortcut'
  final String language;    // 'en'|'hi'|'ta'|'any'
  final int useCount;
  final DateTime lastUsed;
  final bool confirmed;

  const CacheEntry({
    this.id,
    required this.trigger,
    required this.resolved,
    required this.type,
    required this.language,
    required this.useCount,
    required this.lastUsed,
    required this.confirmed,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'trigger'   : trigger,
    'resolved'  : resolved,
    'type'      : type,
    'language'  : language,
    'use_count' : useCount,
    'last_used' : lastUsed.millisecondsSinceEpoch,
    'confirmed' : confirmed ? 1 : 0,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  };

  factory CacheEntry.fromMap(Map<String, dynamic> map) => CacheEntry(
    id       : map['id'],
    trigger  : map['trigger'],
    resolved : map['resolved'],
    type     : map['type'],
    language : map['language'],
    useCount : map['use_count'],
    lastUsed : DateTime.fromMillisecondsSinceEpoch(map['last_used']),
    confirmed: map['confirmed'] == 1,
  );

  CacheEntry copyWith({
    int? id, String? trigger, String? resolved, String? type,
    String? language, int? useCount, DateTime? lastUsed, bool? confirmed,
  }) => CacheEntry(
    id       : id       ?? this.id,
    trigger  : trigger  ?? this.trigger,
    resolved : resolved ?? this.resolved,
    type     : type     ?? this.type,
    language : language ?? this.language,
    useCount : useCount ?? this.useCount,
    lastUsed : lastUsed ?? this.lastUsed,
    confirmed: confirmed ?? this.confirmed,
  );
}
