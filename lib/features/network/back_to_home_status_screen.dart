import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class BackToHomeStatusScreen extends StatefulWidget {
  final RouterOsService service;
  const BackToHomeStatusScreen({super.key, required this.service});
  @override
  State<BackToHomeStatusScreen> createState() => _S();
}

class _S extends State<BackToHomeStatusScreen> {
  bool l = true;
  Map<String, String> row = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    row = await widget.service.ipCloudStatus();
    if (mounted) setState(() => l = false);
  }

  bool sensitive(String k) {
    final x = k.toLowerCase();
    return x.contains('private-key') ||
        x.contains('client-config') ||
        x.contains('qrcode');
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Back To Home • État')),
    body: l
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Back To Home s’appuie sur WireGuard et peut utiliser un relais lorsque le routeur n’est pas directement joignable. '
                    'Les clés privées, configurations client et QR codes restent masqués. '
                    'Cette vue sert au diagnostic : la gestion normale de Back To Home reste volontairement prudente.',
                  ),
                ),
              ),
              for (final e in row.entries.where(
                (e) => e.key.startsWith('vpn-') && !sensitive(e.key),
              ))
                Card(
                  child: ListTile(title: Text(e.key), subtitle: Text(e.value)),
                ),
            ],
          ),
  );
}
