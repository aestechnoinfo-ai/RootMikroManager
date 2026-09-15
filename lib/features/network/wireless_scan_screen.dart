import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class WirelessScanScreen extends StatefulWidget {
  final RouterOsService service;
  const WirelessScanScreen({super.key, required this.service});
  @override
  State<WirelessScanScreen> createState() => _WirelessScanScreenState();
}

class _WirelessScanScreenState extends State<WirelessScanScreen> {
  bool loadingInterfaces = true, scanning = false;
  List<Map<String, String>> interfaces = [];
  List<Map<String, String>> results = [];
  String? selectedId;
  String? selectedPath;
  @override
  void initState() {
    super.initState();
    loadInterfaces();
  }

  Future<void> loadInterfaces() async {
    interfaces = await widget.service.wirelessInterfacesAll();
    if (interfaces.isNotEmpty) {
      selectedId = interfaces.first['.id'];
      selectedPath = interfaces.first['_path'];
    }
    if (mounted) setState(() => loadingInterfaces = false);
  }

  Future<void> scan() async {
    if (selectedId == null || selectedPath == null || scanning) return;
    setState(() {
      scanning = true;
      results = [];
    });
    try {
      results = await widget.service.scanWirelessInterface(
        selectedPath!,
        selectedId!,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan Wi‑Fi')),
    body: loadingInterfaces
        ? const Center(child: CircularProgressIndicator())
        : interfaces.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucune interface Wi‑Fi/Wireless compatible avec le scan n’a été détectée.',
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<String>(isExpanded: true, 
                value: selectedId,
                decoration: const InputDecoration(labelText: 'Interface radio'),
                items: interfaces
                    .map(
                      (r) => DropdownMenuItem(
                        value: r['.id'],
                        child: Text(
                          '${r['name'] ?? '—'} • ${r['_backend'] ?? ''}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  final r = interfaces.firstWhere((e) => e['.id'] == v);
                  setState(() {
                    selectedId = v;
                    selectedPath = r['_path'];
                  });
                },
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Le scan radio peut interrompre ou perturber temporairement le trafic sur certaines interfaces/pilotes. Évitez-le sur une radio critique en production.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: scanning ? null : scan,
                icon: const Icon(Icons.radar),
                label: const Text('Scanner les réseaux'),
              ),
              const SizedBox(height: 12),
              if (scanning) const Center(child: CircularProgressIndicator()),
              for (final r in results)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.wifi_find),
                    title: Text(r['ssid'] ?? r['name'] ?? 'Réseau'),
                    subtitle: Text(
                      [
                        if ((r['bssid'] ?? '').isNotEmpty)
                          'BSSID ${r['bssid']}',
                        if ((r['frequency'] ?? '').isNotEmpty)
                          '${r['frequency']} MHz',
                        if ((r['signal-strength'] ?? r['signal'] ?? '')
                            .isNotEmpty)
                          'Signal ${r['signal-strength'] ?? r['signal']}',
                      ].join(' • '),
                    ),
                  ),
                ),
            ],
          ),
  );
}
