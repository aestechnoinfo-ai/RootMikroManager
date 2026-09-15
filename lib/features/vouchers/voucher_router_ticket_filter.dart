import 'mikhmon_batch_comment.dart';

class VoucherRouterTicketFilter {
  const VoucherRouterTicketFilter();
  static const all = '__all__';

  List<Map<String, String>> apply(
    Iterable<Map<String, String>> rows, {
    String query = '',
    String profile = all,
    String comment = all,
  }) {
    final needle = query.trim().toLowerCase();
    return rows.where((row) {
      if (profile != all && (row['profile'] ?? '') != profile) return false;
      if (comment != all && (row['comment'] ?? '') != comment) return false;
      if (needle.isEmpty) return true;
      return [
        'name',
        'profile',
        'comment',
        'server',
      ].any((key) => (row[key] ?? '').toLowerCase().contains(needle));
    }).toList();
  }

  List<String> values(Iterable<Map<String, String>> rows, String key) {
    final result = rows
        .map((row) => (row[key] ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  bool isMikhmonComment(String value) =>
      const MikhmonBatchComment().matches(value);

  bool isUnused(Map<String, String> row) {
    final uptime = (row['uptime'] ?? '').trim().toLowerCase();
    return uptime.isEmpty || uptime == '0s' || uptime == '00:00:00';
  }
}
