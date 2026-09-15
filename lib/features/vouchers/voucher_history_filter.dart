import 'mikhmon_batch_comment.dart';

class VoucherHistoryFilter {
  const VoucherHistoryFilter();

  static const all = '__all__';

  List<String> profiles(Iterable<Map<String, Object?>> rows) =>
      _distinct(rows, 'profile');

  List<String> comments(Iterable<Map<String, Object?>> rows) =>
      _distinct(rows, 'comment');

  List<Map<String, Object?>> apply(
    Iterable<Map<String, Object?>> rows, {
    String query = '',
    String profile = all,
    String comment = all,
  }) {
    final needle = query.trim().toLowerCase();
    return rows.where((row) {
      final rowProfile = _text(row['profile']);
      final rowComment = _text(row['comment']);
      if (profile != all && rowProfile != profile) return false;
      if (comment != all && rowComment != comment) return false;
      if (needle.isEmpty) return true;
      return [
        row['username'],
        row['profile'],
        row['comment'],
        row['created_at'],
      ].any((value) => _text(value).toLowerCase().contains(needle));
    }).toList();
  }

  /// Mikhmon utilise notamment `vc-123-MM.dd.yy-commentaire` et
  /// `up-123-MM.dd.yy-commentaire` pour identifier un lot de tickets.
  bool isMikhmonComment(String value) =>
      const MikhmonBatchComment().matches(value);

  List<String> _distinct(Iterable<Map<String, Object?>> rows, String key) {
    final values = rows
        .map((row) => _text(row[key]))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  String _text(Object? value) => (value ?? '').toString().trim();
}
