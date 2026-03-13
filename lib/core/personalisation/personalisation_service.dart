import 'dart:async';
import '../../models/parsed_command.dart';
import '../../models/v_intent.dart';
import '../../models/action_result.dart';
import '../cache/cache_service.dart';

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
  static final instance = PersonalisationService._();
  PersonalisationService._();

  final _controller = StreamController<MappingProposal>.broadcast();
  Stream<MappingProposal> get proposalStream => _controller.stream;

  int _failureCount = 0;

  /// Called by DialogueController after every successful execution.
  /// If the command came from LLM + succeeded → propose a mapping so the
  /// rule engine can learn it next time.
  Future<void> onCommandCompleted(
    ParsedCommand cmd,
    ActionResult result,
  ) async {
    if (!result.success) {
      _failureCount++;
      return;
    }

    // Only learn from LLM-sourced commands — rule-engine hits already have
    // explicit mappings.
    if (cmd.source != 'llm') return;

    // Extract a learnable trigger → resolved pair based on intent type.
    String? trigger;
    String? resolved;
    String? type;

    switch (cmd.intent.toJsonKey()) {
      case 'CALL_CONTACT':
        trigger = cmd.params['contact']?.toString();
        resolved = cmd.params['contact']?.toString();
        type = 'contact';
        break;
      case 'OPEN_APP':
        trigger = cmd.params['app']?.toString();
        resolved = cmd.params['app']?.toString();
        type = 'app';
        break;
      case 'NAVIGATE':
        trigger = cmd.params['destination']?.toString();
        resolved = cmd.params['destination']?.toString();
        type = 'place';
        break;
      case 'SEND_WHATSAPP':
        trigger = cmd.params['contact']?.toString();
        resolved = cmd.params['contact']?.toString();
        type = 'contact';
        break;
      default:
        return; // nothing learnable for simple intents
    }

    if (trigger == null || trigger.isEmpty || resolved == null) return;

    // Persist as unconfirmed proposal
    await CacheService.instance.propose(
      trigger,
      resolved,
      type!,
      cmd.language,
      confirmed: false,
    );

    // Emit to UI so the MappingProposalSheet can ask the user to confirm
    _controller.add(MappingProposal(
      trigger: trigger,
      resolved: resolved,
      type: type,
    ));
  }

  /// Returns true when we have accumulated enough failures to trigger
  /// fine-tuning (checked by AppInitializer on next boot).
  Future<bool> shouldFinetune() async {
    final failures = await CacheService.instance.getFailures(limit: 1000);
    return failures.length >= 50; // VConstants.minFailuresForFinetune
  }
}
