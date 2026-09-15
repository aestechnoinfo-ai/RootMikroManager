import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';

import '../../core/routeros/routeros_service.dart';
import '../vouchers/voucher_print_layout.dart';
import '../vouchers/voucher_template_settings.dart';
import 'hotspot_profile_config.dart';

enum UserFilterMode { all, expired }

class HotspotUsersScreen extends StatefulWidget {
  final RouterOsService service;

  const HotspotUsersScreen({super.key, required this.service});

  @override
  State<HotspotUsersScreen> createState() => _HotspotUsersScreenState();
}

class _HotspotUsersScreenState extends State<HotspotUsersScreen> {
  final search = TextEditingController();
  List<Map<String, String>> users = [];
  List<Map<String, String>> profiles = [];
  String profile = 'all';
  String comment = '';
  UserFilterMode mode = UserFilterMode.all;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(_localRefresh);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      profiles = await widget.service.hotspotProfiles();
      users = await widget.service.hotspotUsersFiltered(
        profile: profile,
        comment: comment.isEmpty ? null : comment,
        expiredOnly: mode == UserFilterMode.expired,
      );
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get shown {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      return [
        u['name'],
        u['server'],
        u['profile'],
        u['mac-address'],
        u['comment'],
      ].any((v) => (v ?? '').toLowerCase().contains(q));
    }).toList();
  }

  List<String> get batchComments {
    final set = <String>{};
    for (final u in users) {
      final value = u['comment'] ?? '';
      if (RegExp(r'^(?:vc|up)-\d{3}', caseSensitive: false).hasMatch(value)) {
        set.add(value);
      }
    }
    return set.toList()..sort();
  }

  Future<void> edit(Map<String, String> user) async {
    await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotUserEdit,
      extra: HotspotUserPayload(user),
    );
    await load();
  }

  Future<void> action(String value, Map<String, String> user) async {
    final id = user['.id'];
    if (id == null) return;

    try {
      if (value == 'edit') {
        await edit(user);
        return;
      }
      if (value == 'enable') {
        await widget.service.enable('/ip/hotspot/user', id);
      } else if (value == 'disable') {
        await widget.service.disable('/ip/hotspot/user', id);
      } else if (value == 'reset') {
        await widget.service.resetRootMikroManagerHotspotUser(user);
      } else if (value == 'print') {
        _print(user, VoucherPrintLayout.standard);
        return;
      } else if (value == 'qr') {
        _print(user, VoucherPrintLayout.qr);
        return;
      } else if (value == 'delete') {
        if (!await _confirm('Supprimer ${user['name'] ?? 'utilisateur'} ?'))
          return;
        await widget.service.removeHotspotUserAndScheduler(user);
      }
      await load();
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> _print(
    Map<String, String> user,
    VoucherPrintLayout layout,
  ) async {
    Map<String, String>? row;
    for (final item in profiles) {
      if (item['name'] == user['profile']) {
        row = item;
        break;
      }
    }
    final meta = row == null ? null : HotspotProfileConfig.fromRouterOs(row);
    final settings = await VoucherTemplateSettings.load();
    if (!mounted) return;

    AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: [
          {
            'username': user['name'] ?? '',
            'password': user['password'] ?? '',
            'profile': user['profile'] ?? '',
            'validity': meta?.validity ?? '',
            'price': meta?.price ?? '0',
            'selling-price': meta?.sellingPrice ?? '0',
          },
        ],
        layout: layout,
        templateSettings: settings,
      ),
    );
  }

  Future<void> removeExpired() async {
    if (!await _confirm('Supprimer tous les users expirés (limit-uptime=1s) ?'))
      return;

    try {
      final count = await widget.service.removeExpiredHotspotUsers();
      await load();
      _msg('$count utilisateur(s) supprimé(s).');
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> removeBatch() async {
    if (comment.isEmpty) return;
    if (!await _confirm(
      'Supprimer les vouchers inutilisés de ce lot ? '
      'Comme RootMikroManager, seuls ceux avec uptime=00:00:00 '
      'seront supprimés.',
    ))
      return;

    try {
      final count = await widget.service.removeUnusedHotspotUsersByComment(
        comment,
      );
      comment = '';
      await load();
      _msg('$count voucher(s) inutilisé(s) supprimé(s).');
    } catch (e) {
      _msg('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          label: Text(error!),
        ),
      );
    }

    final rows = shown;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Utilisateurs Hotspot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        AppRouter.pushNamed<bool>(
                          context,
                          AppRoutes.hotspotUserAdd,
                          extra: HotspotAddUserPayload(
                            initialProfile: profile == 'all' ? null : profile,
                          ),
                        ).then((changed) {
                          if (changed == true) load();
                        }),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ajouter'),
                  ),
                  FilledButton.icon(
                    onPressed: () => AppRouter.pushNamed(
                      context,
                      AppRoutes.vouchers,
                    ).then((_) => load()),
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Générer vouchers'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _filters(),
          const SizedBox(height: 10),
          if (mode == UserFilterMode.expired && users.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: removeExpired,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Supprimer tous les expirés'),
            ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: removeBatch,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Supprimer les vouchers inutilisés de ce lot'),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${rows.length} utilisateur(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Aucun utilisateur pour ce filtre.')),
            ),
          ...rows.map(_card),
        ],
      ),
    );
  }

  Widget _filters() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, c) {
          final widgets = [
            TextField(
              controller: search,
              decoration: const InputDecoration(
                labelText: 'Recherche',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            DropdownButtonFormField<String>(
              value: profile,
              decoration: const InputDecoration(labelText: 'Profil'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Tous les profils'),
                ),
                ...profiles.map(
                  (p) => DropdownMenuItem(
                    value: p['name'] ?? '',
                    child: Text(p['name'] ?? '—'),
                  ),
                ),
              ],
              onChanged: (v) async {
                profile = v ?? 'all';
                comment = '';
                await load();
              },
            ),
            DropdownButtonFormField<String>(
              value: comment,
              decoration: const InputDecoration(labelText: 'Comment / lot'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tous les lots')),
                ...batchComments.map(
                  (v) => DropdownMenuItem(value: v, child: Text(v)),
                ),
              ],
              onChanged: (v) async {
                comment = v ?? '';
                await load();
              },
            ),
            SegmentedButton<UserFilterMode>(
              segments: const [
                ButtonSegment(value: UserFilterMode.all, label: Text('Tous')),
                ButtonSegment(
                  value: UserFilterMode.expired,
                  label: Text('Expirés'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (v) async {
                mode = v.first;
                comment = '';
                await load();
              },
            ),
          ];

          if (c.maxWidth < 760) {
            return Column(
              children: [
                for (final w in widgets) ...[w, const SizedBox(height: 8)],
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: widgets[0]),
                  const SizedBox(width: 8),
                  Expanded(child: widgets[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: widgets[2]),
                  const SizedBox(width: 8),
                  Expanded(child: widgets[3]),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _card(Map<String, String> u) {
    final disabled = u['disabled'] == 'true' || u['disabled'] == 'yes';
    final expired = u['limit-uptime'] == '1s';
    final voucher = u['name'] == u['password'];

    return Card(
      child: ListTile(
        onTap: () => edit(u),
        leading: CircleAvatar(
          child: Icon(
            expired
                ? Icons.timer_off_outlined
                : disabled
                ? Icons.lock_outline
                : voucher
                ? Icons.confirmation_number_outlined
                : Icons.person_outline,
          ),
        ),
        title: Text(u['name'] ?? '—'),
        subtitle: Text(
          [
            'Server: ${(u['server'] ?? '').isEmpty ? 'all' : u['server']}',
            'Profil: ${u['profile'] ?? 'default'}',
            if ((u['mac-address'] ?? '').isNotEmpty) 'MAC: ${u['mac-address']}',
            if ((u['uptime'] ?? '').isNotEmpty) 'Uptime: ${u['uptime']}',
            if (expired) 'EXPIRED',
            if (disabled) 'DISABLED',
            if ((u['comment'] ?? '').isNotEmpty) u['comment']!,
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => action(v, u),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(
              value: disabled ? 'enable' : 'disable',
              child: Text(disabled ? 'Activer' : 'Désactiver'),
            ),
            if (expired)
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset RootMikroManager'),
              ),
            const PopupMenuItem(value: 'print', child: Text('Print Default')),
            const PopupMenuItem(value: 'qr', child: Text('Print QR')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(message),
          actions: [
            IconButton(
              tooltip: 'Exporter CSV',
              onPressed: () =>
                  AppRouter.pushNamed(context, AppRoutes.hotspotUsersExport),
              icon: const Icon(Icons.file_download_outlined),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;

  void _localRefresh() {
    if (mounted) setState(() {});
  }

  void _msg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    search.removeListener(_localRefresh);
    search.dispose();
    super.dispose();
  }
}
