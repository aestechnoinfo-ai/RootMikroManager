import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_history_filter.dart';

void main() {
  const filter = VoucherHistoryFilter();
  final rows = <Map<String, Object?>>[
    {
      'username': 'alpha',
      'profile': '1h',
      'comment': 'vc-123-09.05.26-kiosque',
      'created_at': '2026-09-05',
    },
    {
      'username': 'beta',
      'profile': '1j',
      'comment': 'lot école',
      'created_at': '2026-09-04',
    },
  ];

  test('filtre exactement par profil et commentaire de lot', () {
    expect(
      filter
          .apply(rows, profile: '1h', comment: 'vc-123-09.05.26-kiosque')
          .single['username'],
      'alpha',
    );
  });

  test('la recherche inclut le commentaire', () {
    expect(filter.apply(rows, query: 'école').single['username'], 'beta');
  });

  test('reconnait les marqueurs de lots Mikhmon', () {
    expect(filter.isMikhmonComment('vc-123-09.05.26-kiosque'), isTrue);
    expect(filter.isMikhmonComment('up-987-09.05.26'), isTrue);
    expect(filter.isMikhmonComment('vc-456-ancienne-version'), isTrue);
    expect(filter.isMikhmonComment('VC-111-09.05.26-PROMO'), isTrue);
    expect(filter.isMikhmonComment('lot local'), isFalse);
  });
}
