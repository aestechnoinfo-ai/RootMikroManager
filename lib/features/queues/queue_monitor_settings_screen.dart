import 'package:flutter/material.dart';
import 'queue_monitor_settings.dart';

class QueueMonitorSettingsScreen extends StatefulWidget {
  const QueueMonitorSettingsScreen({super.key});

  @override
  State<QueueMonitorSettingsScreen> createState() =>
      _QueueMonitorSettingsScreenState();
}

class _QueueMonitorSettingsScreenState
    extends State<QueueMonitorSettingsScreen> {
  bool loading = true;
  bool autoRefresh = true;
  bool showBytes = true;
  bool showPackets = true;
  final seconds = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await QueueMonitorSettings.load();
    autoRefresh = s.autoRefresh;
    showBytes = s.showBytes;
    showPackets = s.showPackets;
    seconds.text = '${s.refreshSeconds}';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    await QueueMonitorSettings(
      autoRefresh: autoRefresh,
      refreshSeconds: (int.tryParse(seconds.text) ?? 3).clamp(1, 300).toInt(),
      showBytes: showBytes,
      showPackets: showPackets,
    ).save();

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Monitoring Queues')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actualisation automatique'),
                value: autoRefresh,
                onChanged: (v) => setState(() => autoRefresh = v),
              ),
              TextField(
                controller: seconds,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalle',
                  suffixText: 'secondes',
                  helperText: '1 à 300 secondes',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Afficher les octets'),
                value: showBytes,
                onChanged: (v) => setState(() => showBytes = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Afficher les paquets'),
                value: showPackets,
                onChanged: (v) => setState(() => showPackets = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    seconds.dispose();
    super.dispose();
  }
}
