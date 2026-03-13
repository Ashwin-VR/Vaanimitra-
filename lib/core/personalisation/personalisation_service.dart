// STUB — lib/core/personalisation/personalisation_service.dart
// Owner: Dev 2. Replace with production implementation.
// Emits an empty stream until Dev 2 wires the personalisation engine.

class MappingProposal {
  final String trigger;
  final String resolved;
  final String type;

  const MappingProposal({
    required this.trigger,
    required this.resolved,
    required this.type,
  });
}

class PersonalisationService {
  static final instance = PersonalisationService._internal();
  PersonalisationService._internal();

  /// STUB: never emits. Dev 2 replaces with real proposal stream.
  Stream<MappingProposal> get proposalStream => const Stream.empty();
}
