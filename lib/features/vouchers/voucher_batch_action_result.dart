class VoucherBatchItemResult {
  final String username;
  final bool success;
  final String message;

  const VoucherBatchItemResult({
    required this.username,
    required this.success,
    required this.message,
  });
}

class VoucherBatchActionResult {
  final List<VoucherBatchItemResult> items;
  const VoucherBatchActionResult(this.items);

  int get successCount => items.where((e) => e.success).length;
  int get failureCount => items.where((e) => !e.success).length;
  bool get hasFailures => failureCount > 0;
}
