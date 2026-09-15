import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class AutomationSummaryScreen extends StatefulWidget {
  final RouterOsService service;
  const AutomationSummaryScreen({super.key, required this.service});

  @override
  State<AutomationSummaryScreen> createState() =>
      _AutomationSummaryScreenState();
}

class _AutomationSummaryScreenState extends State<AutomationSummaryScreen> {
  bool loading = true;
  int scripts = 0;
  int schedulers = 0;
  int enabledSchedulers = 0;
  int recurringSchedulers = 0;
  int executedScripts = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  bool off(Map<String, String> r) =>
      r['disabled'] == 'yes' || r['disabled'] == 'true';

  @override
  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final result = await Future.wait([
      widget.service.scripts(),
      widget.service.schedulers(),
    ]);

    scripts = result[0].length;
    schedulers = result[1].length;
    enabledSchedulers = result[1].where((e) => !off(e)).length;
    recurringSchedulers = result[1].where((e) {
      final interval = (e['interval'] ?? '').trim();
      return interval.isNotEmpty && interval != '0s' && interval != '0';
    }).length;
    executedScripts = result[0].where((e) {
      return (int.tryParse(e['run-count'] ?? '0') ?? 0) > 0;
    }).length;

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Résumé automatisation'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _card('Scripts', scripts, Icons.code),
              _card(
                'Scripts déjà exécutés',
                executedScripts,
                Icons.play_circle_outline,
              ),
              _card('Schedulers', schedulers, Icons.event_repeat_outlined),
              _card(
                'Schedulers actifs',
                enabledSchedulers,
                Icons.check_circle_outline,
              ),
              _card('Schedulers récurrents', recurringSchedulers, Icons.repeat),
            ],
          ),
  );

  Widget _card(String label, int value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
