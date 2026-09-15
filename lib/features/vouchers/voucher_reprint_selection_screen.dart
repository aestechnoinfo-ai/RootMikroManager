import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/database/app_database.dart';
import 'voucher_print_layout.dart';
import 'voucher_template_settings.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherReprintSelectionScreen extends StatefulWidget {
  const VoucherReprintSelectionScreen({super.key});
  @override
  State<VoucherReprintSelectionScreen> createState() => _S();
}

class _S extends State<VoucherReprintSelectionScreen> {
  bool loading = true;
  final selected = <int>{};
  List<Map<String, Object?>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.instance.db;
    rows = await VoucherHistoryRepository(
      db,
    ).read(RouterSession.instance.activeRouter?.id, limit: 500);
    if (mounted) setState(() => loading = false);
  }

  Map<String, String> voucher(Map<String, Object?> r) => {
    'username': '${r['username'] ?? ''}',
    'password': '${r['password'] ?? ''}',
    'profile': '${r['profile'] ?? ''}',
    'selling-price': '${r['selling_price'] ?? '0'}',
    'validity': '${r['validity'] ?? ''}',
    'comment': '${r['comment'] ?? ''}',
    'hotspot-name': '${r['hotspot_name'] ?? ''}',
  };
  Future<void> printSelected(VoucherPrintLayout layout) async {
    final chosen = rows
        .where((r) => selected.contains(r['id'] as int?))
        .map(voucher)
        .toList();
    if (chosen.isEmpty) return;
    final settings = await VoucherTemplateSettings.load();
    if (!mounted) return;
    await AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: chosen,
        layout: layout,
        templateSettings: settings,
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Réimpression sélective'),
      actions: [
        PopupMenuButton<VoucherPrintLayout>(
          enabled: selected.isNotEmpty,
          onSelected: printSelected,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: VoucherPrintLayout.standard,
              child: Text('Default'),
            ),
            PopupMenuItem(value: VoucherPrintLayout.qr, child: Text('QR')),
            PopupMenuItem(
              value: VoucherPrintLayout.small,
              child: Text('Small / Thermal'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.mikhmonCode,
              child: Text('Compact Code'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.mikhmonCredentials,
              child: Text('Compact ID + Pass'),
            ),
          ],
          icon: const Icon(Icons.print_outlined),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => setState(
                      () => selected.addAll(
                        rows.map((e) => e['id']).whereType<int>(),
                      ),
                    ),
                    child: const Text('Tout sélectionner'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => setState(selected.clear),
                    child: const Text('Effacer sélection'),
                  ),
                  Chip(label: Text('${selected.length} sélectionné(s)')),
                ],
              ),
              const SizedBox(height: 8),
              for (final r in rows)
                CheckboxListTile(
                  value: selected.contains(r['id']),
                  onChanged: (v) => setState(() {
                    final id = r['id'] as int?;
                    if (id == null) return;
                    if (v == true)
                      selected.add(id);
                    else
                      selected.remove(id);
                  }),
                  title: Text('${r['username'] ?? '—'}'),
                  subtitle: Text(
                    '${r['profile'] ?? '—'} • ${r['created_at'] ?? ''}',
                  ),
                ),
            ],
          ),
  );
}
