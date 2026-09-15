import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/database/app_database.dart';
import '../../core/settings/app_currency_settings.dart';
import 'voucher_print_layout.dart';
import 'voucher_template_settings.dart';
import 'voucher_history_filter.dart';
import '../../core/routeros/router_session.dart';
import 'voucher_history_repository.dart';

class VoucherReprintFilterScreen extends StatefulWidget {
  const VoucherReprintFilterScreen({super.key});
  @override
  State<VoucherReprintFilterScreen> createState() => _S();
}

class _S extends State<VoucherReprintFilterScreen> {
  final search = TextEditingController();
  bool loading = true;
  String currency = '';
  String profile = VoucherHistoryFilter.all;
  String comment = VoucherHistoryFilter.all;
  final filter = const VoucherHistoryFilter();
  List<Map<String, Object?>> rows = [];
  final selected = <int>{};
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.instance.db;
    final x = await Future.wait([
      VoucherHistoryRepository(
        db,
      ).read(RouterSession.instance.activeRouter?.id, limit: 1000),
      AppCurrencySettings.load(),
    ]);
    rows = x[0] as List<Map<String, Object?>>;
    currency = x[1] as String;
    if (mounted) setState(() => loading = false);
  }

  List<String> get profiles => filter.profiles(rows);
  List<Map<String, Object?>> get commentSource =>
      profile == VoucherHistoryFilter.all
      ? rows
      : rows
            .where((row) => (row['profile'] ?? '').toString() == profile)
            .toList();
  List<String> get comments => filter.comments(commentSource);
  int commentCount(String value) => commentSource
      .where((row) => (row['comment'] ?? '').toString().trim() == value)
      .length;
  List<Map<String, Object?>> get shown {
    return filter.apply(
      rows,
      query: search.text,
      profile: profile,
      comment: comment,
    );
  }

  Map<String, String> toVoucher(Map<String, Object?> r) => {
    'username': '${r['username'] ?? ''}',
    'password': '${r['password'] ?? ''}',
    'profile': '${r['profile'] ?? ''}',
    'selling-price': '${r['selling_price'] ?? '0'}',
    'validity': '${r['validity'] ?? ''}',
    'comment': '${r['comment'] ?? ''}',
    'hotspot-name': '${r['hotspot_name'] ?? ''}',
  };
  Future<void> printIt(VoucherPrintLayout layout) async {
    final chosen = rows
        .where((r) => selected.contains(r['id']))
        .map(toVoucher)
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
      title: Text('Réimpression (${selected.length})'),
      actions: [
        PopupMenuButton<VoucherPrintLayout>(
          enabled: selected.isNotEmpty,
          onSelected: printIt,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: VoucherPrintLayout.standard,
              child: Text('Standard'),
            ),
            PopupMenuItem(value: VoucherPrintLayout.qr, child: Text('QR')),
            PopupMenuItem(
              value: VoucherPrintLayout.small,
              child: Text('Compact'),
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
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Utilisateur / profil / commentaire / date',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(isExpanded: true, 
                      value: profile,
                      decoration: const InputDecoration(labelText: 'Profil'),
                      items: [
                        const DropdownMenuItem(
                          value: VoucherHistoryFilter.all,
                          child: Text('Tous les profils'),
                        ),
                        ...profiles.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        profile = v ?? VoucherHistoryFilter.all;
                        comment = VoucherHistoryFilter.all;
                        selected.clear();
                      }),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: comment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire / lot Mikhmon',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: VoucherHistoryFilter.all,
                          child: Text('Tous les commentaires'),
                        ),
                        ...comments.map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              '${filter.isMikhmonComment(e) ? 'Mikhmon • ' : ''}'
                              '$e [${commentCount(e)}]',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        comment = v ?? VoucherHistoryFilter.all;
                        selected.clear();
                      }),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => setState(
                            () => selected.addAll(
                              shown.map((e) => e['id']).whereType<int>(),
                            ),
                          ),
                          child: const Text('Sélectionner affichés'),
                        ),
                        TextButton(
                          onPressed: () => setState(selected.clear),
                          child: const Text('Effacer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final r = shown[i];
                    final id = r['id'] as int?;
                    return CheckboxListTile(
                      value: id != null && selected.contains(id),
                      onChanged: id == null
                          ? null
                          : (v) => setState(() {
                              if (v == true)
                                selected.add(id);
                              else
                                selected.remove(id);
                            }),
                      title: Text('${r['username'] ?? '—'}'),
                      subtitle: Text(
                        '${r['profile'] ?? '—'} • ${AppCurrencySettings.formatRaw('${r['selling_price'] ?? '0'}', currency)} • ${r['validity'] ?? '—'}\n'
                        '${(r['comment'] ?? '').toString().isEmpty ? '' : '${r['comment']}\n'}'
                        '${r['created_at'] ?? ''}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
