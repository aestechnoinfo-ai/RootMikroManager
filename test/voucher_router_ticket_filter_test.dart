import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_router_ticket_filter.dart';

void main() {
  const filter = VoucherRouterTicketFilter();
  const rows = [
    {
      '.id': '*1',
      'name': 'alpha',
      'profile': '1h',
      'comment': 'vc-123-09.06.26-kiosque',
      'uptime': '0s',
    },
    {
      '.id': '*2',
      'name': 'beta',
      'profile': '1j',
      'comment': 'lot école',
      'uptime': '2h',
    },
  ];

  test('filtre exactement par profil et commentaire', () {
    expect(
      filter
          .apply(rows, profile: '1h', comment: 'vc-123-09.06.26-kiosque')
          .single['name'],
      'alpha',
    );
  });

  test('reconnait Mikhmon et distingue utilisé de non utilisé', () {
    expect(filter.isMikhmonComment(rows.first['comment']!), isTrue);
    expect(filter.isMikhmonComment('up-321-format-officiel'), isTrue);
    expect(filter.isUnused(rows.first), isTrue);
    expect(filter.isUnused(rows.last), isFalse);
  });
}
