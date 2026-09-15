import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class LoggingRulesScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingRulesScreen({super.key, required this.service});

  @override
  State<LoggingRulesScreen> createState() => _LoggingRulesScreenState();
}

class _LoggingRulesScreenState extends State<LoggingRulesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  bool disabled(Map<String, String> r) =>
      r['disabled'] == 'yes' || r['disabled'] == 'true';

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.loggingRules();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? row]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.loggingRuleEdit,
      extra: OptionalRowPayload(row),
    );
    if (changed == true) await load();
  }

  Future<void> action(String value, Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    if (value == 'edit') return edit(r);
    if (value == 'toggle') {
      if (disabled(r)) {
        await widget.service.enable('/system/logging', id);
      } else {
        await widget.service.disable('/system/logging', id);
      }
    } else if (value == 'delete') {
      await widget.service.remove('/system/logging', id);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Règles de logging'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une règle'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final off = disabled(r);
                      return Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: Icon(
                            off
                                ? Icons.notifications_off_outlined
                                : Icons.notifications_active_outlined,
                          ),
                          title: Text(r['topics'] ?? 'info'),
                          subtitle: Text(
                            [
                              'Action ${r['action'] ?? 'memory'}',
                              if ((r['prefix'] ?? '').isNotEmpty)
                                'Prefix ${r['prefix']}',
                              if ((r['regex'] ?? '').isNotEmpty)
                                'Regex ${r['regex']}',
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => action(v, r),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(off ? 'Activer' : 'Désactiver'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
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
