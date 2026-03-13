// DEV 3 — implement per PDR Section 11.2 (all 15 intents)
import '../../models/parsed_command.dart';
import '../../models/action_result.dart';

class ActionExecutor {
  static final instance = ActionExecutor._();
  ActionExecutor._();

  Future<ActionResult> processIntent(ParsedCommand cmd) async {
    // TODO: implement routing to all 15 intent handlers
    // Each handler: speak BEFORE → execute → speak OK or FAIL
    return ActionResult.fail('not implemented');
  }
}
