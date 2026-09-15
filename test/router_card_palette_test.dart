import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_mikro_manager/data/models/router_model.dart';
import 'package:root_mikro_manager/features/routers/router_card_palette.dart';

void main() {
  const first = RouterModel(
    id: 1,
    name: 'Routeur A',
    host: '192.168.88.1',
    port: 8728,
    username: 'admin',
  );
  const second = RouterModel(
    id: 2,
    name: 'Routeur B',
    host: '10.0.0.1',
    port: 8728,
    username: 'admin',
  );

  test('la couleur calculée reste stable pour chaque routeur', () {
    expect(
      RouterCardPalette.colorFor(first, Brightness.light),
      RouterCardPalette.colorFor(first, Brightness.light),
    );
    expect(
      RouterCardPalette.colorFor(first, Brightness.light),
      isNot(RouterCardPalette.colorFor(second, Brightness.light)),
    );
  });

  test('une couleur enregistrée reste prioritaire', () {
    const router = RouterModel(
      id: 3,
      name: 'Routeur personnalisé',
      host: 'router.example',
      port: 8728,
      username: 'admin',
      colorValue: 0xFF123456,
    );
    expect(
      RouterCardPalette.colorFor(router, Brightness.light),
      const Color(0xFF123456),
    );
  });

  test('les palettes claire et sombre sont adaptées au thème', () {
    expect(
      RouterCardPalette.colorFor(first, Brightness.light),
      isNot(RouterCardPalette.colorFor(first, Brightness.dark)),
    );
  });
}
