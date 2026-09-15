import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/features/vouchers/rootmikromanager_voucher_generator.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_batch_validator.dart';
import 'package:root_mikro_manager/features/vouchers/voucher_generation_validator.dart';

void main() {
  test('la limite de lot est alignée sur Mikhmon à 560', () {
    const validator = VoucherBatchValidator();
    expect(validator.quantity('560'), isNull);
    expect(validator.quantity('561'), contains('560'));
  });

  test(
    '560 codes numériques de longueur 3 sont refusés sans risque de doublon',
    () {
      final issues = VoucherGenerationValidator.validate(
        quantity: 560,
        length: 3,
        characterMode: 'num',
        prefix: '',
        suffix: '',
        profile: '3h',
        server: 'all',
        timeLimit: '',
        dataLimit: '',
      );
      expect(issues, contains(contains('512 codes distincts')));
    },
  );

  test('les alphabets générés excluent les caractères ambigus de Mikhmon', () {
    final generator = RootMikroManagerVoucherGenerator();
    for (final mode in [
      'lower',
      'upper',
      'upplow',
      'mix',
      'mix1',
      'mix2',
      'num',
    ]) {
      final value = generator.generate(length: 8, characterMode: mode);
      expect(value, hasLength(8));
      expect(value, isNot(contains(RegExp(r'[01OQoq]'))));
    }
  });
}
