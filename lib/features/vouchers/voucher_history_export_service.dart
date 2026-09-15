class VoucherHistoryExportService {
  const VoucherHistoryExportService();
  String _q(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';
  String csv(List<Map<String, Object?>> rows, String currency) {
    final b = StringBuffer()
      ..writeln(
        'Username,Profile,Comment,Validity,Selling Price,Currency,Created At',
      );
    for (final r in rows) {
      b.writeln(
        [
          r['username'],
          r['profile'],
          r['comment'],
          r['validity'],
          r['selling_price'],
          currency,
          r['created_at'],
        ].map(_q).join(','),
      );
    }
    return b.toString();
  }
}
