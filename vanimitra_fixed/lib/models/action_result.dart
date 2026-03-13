// STUB — lib/models/action_result.dart
// Owner: Lead. Replace with production implementation.

class ActionResult {
  final bool success;
  final String? detail;
  final String? error;

  const ActionResult._({
    required this.success,
    this.detail,
    this.error,
  });

  factory ActionResult.ok({String? detail}) {
    return ActionResult._(success: true, detail: detail);
  }

  factory ActionResult.fail(String error) {
    return ActionResult._(success: false, error: error);
  }

  @override
  String toString() =>
      'ActionResult(success: $success, detail: $detail, error: $error)';
}
