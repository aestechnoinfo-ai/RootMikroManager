import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class SystemClockScreen extends StatefulWidget {
  final RouterOsService service;
  const SystemClockScreen({super.key, required this.service});

  @override
  State<SystemClockScreen> createState() => _SystemClockScreenState();
}

class _SystemClockScreenState extends State<SystemClockScreen> {
  final date = TextEditingController();
  final time = TextEditingController();
  final timeZoneName = TextEditingController();
  bool autodetect = true;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final row = await widget.service.systemClock();
    date.text = row['date'] ?? '';
    time.text = row['time'] ?? '';
    timeZoneName.text = row['time-zone-name'] ?? '';
    autodetect =
        row['time-zone-autodetect'] != 'no' &&
        row['time-zone-autodetect'] != 'false';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.service.setSystemClock(
        date: date.text.trim(),
        time: time.text.trim(),
        timeZoneName: timeZoneName.text.trim(),
        timeZoneAutodetect: autodetect,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Horloge mise à jour.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Horloge système')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: date,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'sep/01/2026',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: time,
                decoration: const InputDecoration(
                  labelText: 'Heure',
                  hintText: '18:30:00',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeZoneName,
                enabled: !autodetect,
                decoration: const InputDecoration(
                  labelText: 'Fuseau horaire',
                  hintText: 'Africa/Ouagadougou',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Détection automatique du fuseau'),
                value: autodetect,
                onChanged: (v) => setState(() => autodetect = v),
              ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    date.dispose();
    time.dispose();
    timeZoneName.dispose();
    super.dispose();
  }
}
