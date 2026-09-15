import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/export/user_selected_export_service.dart';

import '../../core/database/app_database.dart';
import '../../core/settings/app_currency_settings.dart';
import '../../core/routeros/router_session.dart';
import '../hotspot/hotspot_profile_config.dart';
import 'voucher_print_layout.dart';
import 'voucher_template_settings.dart';
import 'voucher_history_export_service.dart';
import 'voucher_history_filter.dart';
import 'voucher_history_repository.dart';

class VoucherHistoryScreen extends StatefulWidget {
  const VoucherHistoryScreen({super.key});

  @override
  State<VoucherHistoryScreen> createState() => _VoucherHistoryScreenState();
}

class _VoucherHistoryScreenState extends State<VoucherHistoryScreen> {
  final search = TextEditingController();
  final filter = const VoucherHistoryFilter();
  List<Map<String, Object?>> allRows = [];
  bool loading = true;
  String currency = '';
  String selectedProfile = VoucherHistoryFilter.all;
  String selectedComment = VoucherHistoryFilter.all;
  bool syncing = false;

  List<Map<String, Object?>> get commentSource =>
      selectedProfile == VoucherHistoryFilter.all
      ? allRows
      : allRows
            .where(
              (row) => (row['profile'] ?? '').toString() == selectedProfile,
            )
            .toList();

  int commentCount(String value) => commentSource
      .where((row) => (row['comment'] ?? '').toString().trim() == value)
      .length;

  List<Map<String, Object?>> get rows => filter.apply(
    allRows,
    query: search.text,
    profile: selectedProfile,
    comment: selectedComment,
  );

  @override
  void initState() {
    super.initState();
    load().then((_) {
      if (mounted && RouterSession.instance.connected) {
        syncMikhmon(silent: true);
      }
    });
  }

  Future<void> load() async {
    setState(() => loading = true);
    final db = await AppDatabase.instance.db;
    final routerId = RouterSession.instance.activeRouter?.id;
    final values = await Future.wait([
      VoucherHistoryRepository(db).read(routerId),
      AppCurrencySettings.load(),
    ]);
    allRows = values[0] as List<Map<String, Object?>>;
    currency = values[1] as String;
    if (mounted) setState(() => loading = false);
  }

  Map<String, String> _voucher(Map<String, Object?> row) => {
    'username': (row['username'] ?? '').toString(),
    'password': (row['password'] ?? '').toString(),
    'profile': (row['profile'] ?? '').toString(),
    // Older history rows did not persist pricing metadata.
    'selling-price': (row['selling_price'] ?? '0').toString(),
    'validity': (row['validity'] ?? '').toString(),
    'comment': (row['comment'] ?? '').toString(),
    'hotspot-name': (row['hotspot_name'] ?? '').toString(),
  };

  Future<void> printRows(
    List<Map<String, Object?>> source,
    VoucherPrintLayout layout,
  ) async {
    if (source.isEmpty) return;
    final settings = await VoucherTemplateSettings.load();
    if (!mounted) return;
    await AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: source.map(_voucher).toList(),
        layout: layout,
        templateSettings: settings,
      ),
    );
  }

  Future<void> exportCsv() async {
    if (rows.isEmpty) return;
    final csv = const VoucherHistoryExportService().csv(rows, currency);
    final location = await const UserSelectedExportService().saveText(
      suggestedName:
          'voucher-history-${DateTime.now().millisecondsSinceEpoch}.csv',
      mimeType: 'text/csv',
      content: csv,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          location == null
              ? 'Export annulé.'
              : 'CSV enregistré dans l’emplacement choisi.',
        ),
      ),
    );
  }

  Future<void> syncMikhmon({bool silent = false}) async {
    final session = RouterSession.instance;
    if (!session.connected || session.activeRouter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez d’abord un routeur.')),
      );
      return;
    }
    setState(() => syncing = true);
    try {
      final live = await session.readIsolated(
        (service) async => (
          users: await service.hotspotUsers(),
          profiles: await service.hotspotProfiles(),
        ),
      );
      final candidates = live.users.where(
        (user) => filter.isMikhmonComment(user['comment'] ?? ''),
      );
      final profileMetadata = <String, HotspotProfileConfig>{
        for (final row in live.profiles)
          if ((row['name'] ?? '').isNotEmpty)
            row['name']!: HotspotProfileConfig.fromRouterOs(row),
      };
      final db = await AppDatabase.instance.db;
      final existing = await db.query(
        'voucher_history',
        columns: ['username', 'profile', 'comment'],
        where: 'router_id = ?',
        whereArgs: [session.activeRouter!.id],
      );
      final keys = existing
          .map(
            (row) =>
                '${row['username']}\u0000${row['profile']}\u0000${row['comment']}',
          )
          .toSet();
      var imported = 0;
      await db.transaction((txn) async {
        for (final user in candidates) {
          final username = user['name'] ?? '';
          final profile = user['profile'] ?? '';
          final comment = user['comment'] ?? '';
          final metadata = profileMetadata[profile];
          final key = '$username\u0000$profile\u0000$comment';
          if (username.isEmpty || keys.contains(key)) continue;
          await txn.insert('voucher_history', {
            'router_id': session.activeRouter!.id,
            'username': username,
            'password': user['password'] ?? '',
            'profile': profile,
            'selling_price': metadata?.sellingPrice ?? '0',
            'validity': metadata?.validity ?? user['limit-uptime'] ?? '',
            'comment': comment,
            'hotspot_name': '',
            'created_at': '',
          });
          keys.add(key);
          imported++;
        }
      });
      await AppDatabase.instance.log(
        'voucher.history.mikhmon_synced',
        routerId: session.activeRouter!.id,
        data: {'imported': imported},
      );
      await load();
      if (!mounted) return;
      if (!silent || imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$imported ticket(s) Mikhmon importé(s).')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synchronisation impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l’historique ?'),
        content: const Text(
          'Les vouchers présents sur le routeur ne seront pas supprimés. '
          'Seul l’historique local sera effacé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = await AppDatabase.instance.db;
    final routerId = RouterSession.instance.activeRouter?.id;
    await VoucherHistoryRepository(db).clear(routerId);
    await AppDatabase.instance.log(
      'voucher.history.cleared',
      routerId: routerId,
    );
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Historique vouchers'),
      actions: [
        IconButton(
          tooltip: 'Importer les lots Mikhmon du routeur',
          onPressed: loading || syncing ? null : syncMikhmon,
          icon: syncing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_outlined),
        ),
        IconButton(
          tooltip: 'Exporter CSV',
          onPressed: loading ? null : exportCsv,
          icon: const Icon(Icons.download_outlined),
        ),
        PopupMenuButton<VoucherPrintLayout>(
          tooltip: 'Réimprimer la liste filtrée',
          onSelected: (layout) => printRows(rows, layout),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: VoucherPrintLayout.standard,
              child: Text('Imprimer Default'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.qr,
              child: Text('Imprimer QR'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.small,
              child: Text('Imprimer Small / Thermal'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.mikhmonCode,
              child: Text('Imprimer Compact Code'),
            ),
            PopupMenuItem(
              value: VoucherPrintLayout.mikhmonCredentials,
              child: Text('Imprimer Compact ID + Pass'),
            ),
          ],
          icon: const Icon(Icons.print_outlined),
        ),
        IconButton(
          onPressed: clear,
          tooltip: 'Effacer',
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Utilisateur / profil / commentaire / date',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      DropdownButtonFormField<String>(
                        value: selectedProfile,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Profil'),
                        items: [
                          const DropdownMenuItem(
                            value: VoucherHistoryFilter.all,
                            child: Text('Tous les profils'),
                          ),
                          ...filter
                              .profiles(allRows)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedProfile = value ?? VoucherHistoryFilter.all;
                          selectedComment = VoucherHistoryFilter.all;
                        }),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedComment,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Commentaire / lot Mikhmon',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: VoucherHistoryFilter.all,
                            child: Text('Tous les commentaires'),
                          ),
                          ...filter
                              .comments(commentSource)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    '${filter.isMikhmonComment(value) ? 'Mikhmon • ' : ''}'
                                    '$value [${commentCount(value)}]',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (value) => setState(
                          () => selectedComment =
                              value ?? VoucherHistoryFilter.all,
                        ),
                      ),
                    ];
                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 8),
                          fields[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 8),
                        Expanded(child: fields[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${rows.length} voucher(s)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (currency.isNotEmpty)
                      Chip(label: Text('Devise : $currency')),
                  ],
                ),
                const SizedBox(height: 8),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined),
                      title: Text((row['username'] ?? '—').toString()),
                      subtitle: Text(
                        'Mot de passe: ${row['password'] ?? '—'} • '
                        'Profil: ${row['profile'] ?? '—'}\n'
                        'Validité: ${row['validity'] ?? '—'} • '
                        'Prix: ${AppCurrencySettings.formatRaw((row['selling_price'] ?? '0').toString(), currency)}\n'
                        '${(row['comment'] ?? '').toString().isEmpty ? '' : 'Commentaire: ${row['comment']}\n'}'
                        '${row['created_at'] ?? ''}',
                      ),
                      trailing: PopupMenuButton<VoucherPrintLayout>(
                        onSelected: (layout) => printRows([row], layout),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: VoucherPrintLayout.standard,
                            child: Text('Default'),
                          ),
                          PopupMenuItem(
                            value: VoucherPrintLayout.qr,
                            child: Text('QR'),
                          ),
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
