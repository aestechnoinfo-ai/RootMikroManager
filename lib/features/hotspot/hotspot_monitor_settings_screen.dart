import 'package:flutter/material.dart';
import 'hotspot_monitor_settings.dart';

class HotspotMonitorSettingsScreen extends StatefulWidget {
  const HotspotMonitorSettingsScreen({super.key});

  @override
  State<HotspotMonitorSettingsScreen> createState() =>
      _HotspotMonitorSettingsScreenState();
}

class _HotspotMonitorSettingsScreenState
    extends State<HotspotMonitorSettingsScreen> {
  bool loading = true;
  bool autoRefresh = true;
  bool showTraffic = true;
  bool confirmDisconnect = true;
  final seconds = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await HotspotMonitorSettings.load();
    autoRefresh = s.autoRefresh;
    showTraffic = s.showTraffic;
    confirmDisconnect = s.confirmDisconnect;
    seconds.text = '${s.refreshSeconds}';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final s = HotspotMonitorSettings(
      autoRefresh: autoRefresh,
      refreshSeconds: (int.tryParse(seconds.text) ?? 5).clamp(2, 300).toInt(),
      showTraffic: showTraffic,
      confirmDisconnect: confirmDisconnect,
    );
    await s.save();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Monitoring Hotspot')),
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
                  helperText: '2 à 300 secondes',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Afficher le trafic par session'),
                value: showTraffic,
                onChanged: (v) => setState(() => showTraffic = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Confirmer avant déconnexion'),
                value: confirmDisconnect,
                onChanged: (v) => setState(() => confirmDisconnect = v),
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
