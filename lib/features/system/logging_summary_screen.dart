import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class LoggingSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingSummaryScreen({super.key, required this.service});

  @override
  State<LoggingSummaryScreen> createState() => _LoggingSummaryScreenState();
}

class _LoggingSummaryScreenState extends State<LoggingSummaryScreen> {
  bool loading = true;
  int logs = 0;
  int errors = 0;
  int warnings = 0;
  int rules = 0;
  int actions = 0;
  int remoteActions = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final result = await Future.wait([
      widget.service.logs(),
      widget.service.loggingRules(),
      widget.service.loggingActions(),
    ]);
    logs = result[0].length;
    errors = result[0]
        .where((e) => (e['topics'] ?? '').contains('error'))
        .length;
    warnings = result[0]
        .where((e) => (e['topics'] ?? '').contains('warning'))
        .length;
    rules = result[1].length;
    actions = result[2].length;
    remoteActions = result[2].where((e) => e['target'] == 'remote').length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé journalisation'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _c('Logs en mémoire', logs, Icons.article_outlined),
              _c('Erreurs', errors, Icons.error_outline),
              _c('Warnings', warnings, Icons.warning_amber_outlined),
              _c('Règles', rules, Icons.rule_outlined),
              _c('Actions', actions, Icons.output_outlined),
              _c('Actions remote', remoteActions, Icons.cloud_outlined),
            ],
          ),
  );

  Widget _c(String label, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
