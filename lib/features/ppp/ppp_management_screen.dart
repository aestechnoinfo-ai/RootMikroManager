import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/routeros/routeros_service.dart';
import 'ppp_profile_delete_guard.dart';
import 'ppp_secret_delete_guard.dart';

class PppManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const PppManagementScreen({super.key, required this.service});

  @override
  State<PppManagementScreen> createState() => _PppManagementScreenState();
}

class _PppManagementScreenState extends State<PppManagementScreen> {
  final search = TextEditingController();
  int section = 0;
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = switch (section) {
      0 => await widget.service.pppSecrets(),
      1 => await widget.service.pppProfiles(),
      _ => await widget.service.pppActive(),
    };
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.values.any((v) => v.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      section == 0 ? AppRoutes.pppSecretEdit : AppRoutes.pppProfileEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<bool> confirmDelete(Map<String, String> row) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Supprimer "${row['name'] ?? 'cet élément'}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> action(String action, Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;

    if (action == 'edit') return edit(row);
    if (action == 'disconnect') {
      await widget.service.disconnectPppActive(id);
    } else if (action == 'enable') {
      await widget.service.enable('/ppp/secret', id);
    } else if (action == 'disable') {
      await widget.service.disable('/ppp/secret', id);
    } else if (action == 'delete') {
      if (section == 1) {
        final values = await Future.wait([
          widget.service.pppSecrets(),
          widget.service.pppActive(),
        ]);
        final reason = const PppProfileDeleteGuard().reason(
          profileName: row['name'] ?? '',
          secrets: values[0],
          active: values[1],
        );
        if (reason != null) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(reason)));
          }
          return;
        }
      } else if (section == 0) {
        final active = await widget.service.pppActive();
        final reason = const PppSecretDeleteGuard().reason(
          secretName: row['name'] ?? '',
          active: active,
        );
        if (reason != null) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(reason)));
          }
          return;
        }
      }
      if (!await confirmDelete(row)) return;
      await widget.service.remove(
        section == 0 ? '/ppp/secret' : '/ppp/profile',
        id,
      );
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('PPP / PPPoE'),
      actions: [
        IconButton(
          tooltip: 'Sessions actives',
          onPressed: () => AppRouter.pushNamed(context, AppRoutes.pppActive),
          icon: const Icon(Icons.online_prediction_outlined),
        ),
        IconButton(
          tooltip: 'Exporter CSV',
          onPressed: () => AppRouter.pushNamed(context, AppRoutes.pppExport),
          icon: const Icon(Icons.file_download_outlined),
        ),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Secrets'),
                  icon: Icon(Icons.key_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Profils'),
                  icon: Icon(Icons.tune),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Actifs'),
                  icon: Icon(Icons.people_outline),
                ),
              ],
              selected: {section},
              onSelectionChanged: (v) {
                setState(() => section = v.first);
                load();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Rechercher',
            ),
          ),
        ),
        if (section != 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: Text(
                  section == 0 ? 'Ajouter un secret' : 'Ajouter un profil',
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (_, index) {
                      final row = visible[index];
                      final disabled =
                          row['disabled'] == 'true' || row['disabled'] == 'yes';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              section == 2
                                  ? Icons.link
                                  : disabled
                                  ? Icons.pause
                                  : Icons.check,
                            ),
                          ),
                          title: Text(row['name'] ?? row['user'] ?? '—'),
                          subtitle: Text(
                            [
                              if ((row['profile'] ?? '').isNotEmpty)
                                'Profil: ${row['profile']}',
                              if ((row['service'] ?? '').isNotEmpty)
                                'Service: ${row['service']}',
                              if ((row['address'] ?? '').isNotEmpty)
                                'IP: ${row['address']}',
                              if ((row['caller-id'] ?? '').isNotEmpty)
                                'Caller: ${row['caller-id']}',
                              if ((row['uptime'] ?? '').isNotEmpty)
                                'Uptime: ${row['uptime']}',
                              if ((row['rate-limit'] ?? '').isNotEmpty)
                                'Rate: ${row['rate-limit']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, row),
                            itemBuilder: (_) {
                              if (section == 2) {
                                return const [
                                  PopupMenuItem(
                                    value: 'disconnect',
                                    child: Text('Déconnecter'),
                                  ),
                                ];
                              }
                              if (section == 1) {
                                return const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifier'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
                                ];
                              }
                              return [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                PopupMenuItem(
                                  value: disabled ? 'enable' : 'disable',
                                  child: Text(
                                    disabled ? 'Activer' : 'Désactiver',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                              ];
                            },
                          ),
                        ),
                      );
                    },
                  ),
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
