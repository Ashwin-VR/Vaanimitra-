// DEV 2 — implement per PDR Section 9.10
import 'dart:async';
import '../../models/parsed_command.dart';
import '../../models/action_result.dart';

class MappingProposal {
  final String trigger;
  final String resolved;
  final String type;
  const MappingProposal({required this.trigger, required this.resolved, required this.type});
}

class PersonalisationService {
  static final instance = PersonalisationService._();
  PersonalisationService._();
  final _controller = StreamController<MappingProposal>.broadcast();
  Stream<MappingProposal> get proposalStream => _controller.stream;
  Future<void> onCommandCompleted(ParsedCommand cmd, ActionResult result) async {}
  Future<bool> shouldFinetune() async => false;
}
