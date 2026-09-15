import 'package:flutter/material.dart';
import 'ppp_monitor_settings.dart';

class PppMonitorSettingsScreen extends StatefulWidget {
  const PppMonitorSettingsScreen({super.key});
  @override
  State<PppMonitorSettingsScreen> createState() =>
      _PppMonitorSettingsScreenState();
}

class _PppMonitorSettingsScreenState extends State<PppMonitorSettingsScreen> {
  bool loading = true, auto = true, confirm = true;
  final seconds = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await PppMonitorSettings.load();
    auto = s.autoRefresh;
    confirm = s.confirmDisconnect;
    seconds.text = '${s.refreshSeconds}';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    await PppMonitorSettings(
      autoRefresh: auto,
      refreshSeconds: (int.tryParse(seconds.text) ?? 5).clamp(2, 300).toInt(),
      confirmDisconnect: confirm,
    ).save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Monitoring PPP')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actualisation automatique'),
                value: auto,
                onChanged: (v) => setState(() => auto = v),
              ),
              TextField(
                controller: seconds,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalle',
                  suffixText: 'secondes',
                  helperText: '2 à 300 secondes',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Confirmer avant déconnexion'),
                value: confirm,
                onChanged: (v) => setState(() => confirm = v),
              ),
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
