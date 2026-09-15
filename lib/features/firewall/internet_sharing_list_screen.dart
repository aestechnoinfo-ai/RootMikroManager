import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'internet_sharing_rule.dart';
import 'internet_sharing_service.dart';

class InternetSharingListScreen extends StatefulWidget {
  final RouterOsService service;
  const InternetSharingListScreen({super.key, required this.service});

  @override
  State<InternetSharingListScreen> createState() =>
      _InternetSharingListScreenState();
}

class _InternetSharingListScreenState extends State<InternetSharingListScreen> {
  bool loading = true;
  List<InternetSharingRule> rules = [];

  InternetSharingService get manager => InternetSharingService(widget.service);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rules = await manager.managedRules();
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.internetSharingAdd,
    );
    if (changed == true) await load();
  }

  Future<void> editTtl(InternetSharingRule rule) async {
    final controller = TextEditingController(text: '${rule.ttl}');
    final value = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('TTL — ${rule.interfaceName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'TTL',
            helperText: '1 à 255',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await manager.updateTtl(rule, value);
    await load();
  }

  Future<void> remove(InternetSharingRule rule) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Retirer la protection ?'),
            content: Text(
              'Supprimer la règle anti-partage de '
              '${rule.interfaceName} ?',
            ),
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
    if (!ok) return;
    await manager.remove(rule);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Partage Internet'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: add,
              icon: const Icon(Icons.block_outlined),
              label: const Text('Désactiver partage de connexion Internet'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : rules.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune interface protégée par '
                      'RootMikroManager.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rules.length,
                    itemBuilder: (_, i) {
                      final rule = rules[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              rule.enabled ? Icons.block : Icons.pause,
                            ),
                          ),
                          title: Text(rule.interfaceName),
                          subtitle: Text(
                            'Mangle • postrouting • '
                            'change-ttl • set:${rule.ttl}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'toggle') {
                                await manager.setEnabled(rule, !rule.enabled);
                                await load();
                              }
                              if (v == 'ttl') {
                                await editTtl(rule);
                              }
                              if (v == 'delete') {
                                await remove(rule);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  rule.enabled
                                      ? 'Désactiver la règle'
                                      : 'Activer la règle',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'ttl',
                                child: Text('Modifier TTL'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Retirer'),
                              ),
                            ],
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
}
