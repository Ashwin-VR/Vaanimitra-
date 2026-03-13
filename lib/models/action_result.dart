// STUB — lib/models/action_result.dart
// Owner: Lead. Replace with production implementation.

class ActionResult {
  final bool success;
  final String? detail;
  final String? error;
  final bool needsClarification;
  final List<String>? options;

  const ActionResult._({
    required this.success,
    this.detail,
    this.error,
    this.needsClarification = false,
    this.options,
  });

  factory ActionResult.ok({String? detail}) {
    return ActionResult._(success: true, detail: detail);
  }

  factory ActionResult.fail(String error) {
    return ActionResult._(success: false, error: error);
  }

  factory ActionResult.clarify(List<String> options) {
    return ActionResult._(
      success: false,
      needsClarification: true,
      options: options,
    );
  }

  @override
  String toString() =>
      'ActionResult(success: $success, detail: $detail, error: $error, needsClarification: $needsClarification, options: $options)';
}
