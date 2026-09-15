class VoucherGenerationBatchResult {
  final int requested;
  final int generated;
  final String? error;

  const VoucherGenerationBatchResult({
    required this.requested,
    required this.generated,
    this.error,
  });

  int get failed => requested - generated;
  bool get complete => generated == requested && error == null;
}
