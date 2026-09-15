class VoucherLifecycleActionResult {
  final String username;
  final int cookiesRemoved;
  final int sessionsRemoved;
  final int schedulersRemoved;
  final bool userRemoved;
  final bool countersReset;
  final String? error;

  const VoucherLifecycleActionResult({
    required this.username,
    this.cookiesRemoved = 0,
    this.sessionsRemoved = 0,
    this.schedulersRemoved = 0,
    this.userRemoved = false,
    this.countersReset = false,
    this.error,
  });

  bool get success => error == null;
}
