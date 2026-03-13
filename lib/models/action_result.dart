class ActionResult {
  final bool success;
  final String? detail;
  final String? error;

  ActionResult.ok({this.detail}) : success = true, error = null;
  ActionResult.fail(String this.error) : success = false, detail = null;
}
