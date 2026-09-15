import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class BandwidthTestScreen extends StatefulWidget {
  final RouterOsService service;
  const BandwidthTestScreen({super.key, required this.service});

  @override
  State<BandwidthTestScreen> createState() => _BandwidthTestScreenState();
}

class _BandwidthTestScreenState extends State<BandwidthTestScreen> {
  final address = TextEditingController();
  final user = TextEditingController();
  final password = TextEditingController();
  final duration = TextEditingController(text: '10s');
  final limit = TextEditingController(text: '10M');
  String protocol = 'tcp';
  String direction = 'both';
  bool running = false;
  List<Map<String, String>> rows = [];

  Future<void> run() async {
    if (address.text.trim().isEmpty || running) return;
    setState(() {
      running = true;
      rows = [];
    });
    try {
      rows = await widget.service.bandwidthTest(
        address: address.text.trim(),
        user: user.text.trim(),
        password: password.text,
        duration: duration.text.trim().isEmpty ? '10s' : duration.text.trim(),
        protocol: protocol,
        direction: direction,
        localTxSpeed: limit.text.trim(),
        remoteTxSpeed: limit.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bandwidth Test')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Attention : un test de bande passante peut consommer '
              'beaucoup de CPU et de trafic. RootMikroManager applique '
              'une limite de débit configurable au lieu de lancer un test '
              'illimité par défaut.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        TextField(
          controller: address,
          decoration: const InputDecoration(
            labelText: 'Routeur distant',
            hintText: '10.0.0.2',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: user,
          decoration: const InputDecoration(labelText: 'Utilisateur'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mot de passe'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: protocol,
          decoration: const InputDecoration(labelText: 'Protocole'),
          items: const [
            'tcp',
            'udp',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => protocol = v ?? 'tcp'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: direction,
          decoration: const InputDecoration(labelText: 'Direction'),
          items: const [
            'receive',
            'transmit',
            'both',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => direction = v ?? 'both'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: duration,
          decoration: const InputDecoration(labelText: 'Durée'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: limit,
          decoration: const InputDecoration(
            labelText: 'Limite TX/RX',
            hintText: '10M',
            helperText: 'Exemple : 10M. Ne laissez pas le test illimité.',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: running ? null : run,
          icon: const Icon(Icons.speed),
          label: const Text('Lancer le test'),
        ),
        const SizedBox(height: 16),
        if (running) const Center(child: CircularProgressIndicator()),
        for (final r in rows)
          Card(
            child: ListTile(
              title: Text(r['status'] ?? 'Résultat'),
              subtitle: Text(
                [
                  if ((r['tx-current'] ?? '').isNotEmpty)
                    'TX ${r['tx-current']}',
                  if ((r['rx-current'] ?? '').isNotEmpty)
                    'RX ${r['rx-current']}',
                  if ((r['lost-packets'] ?? '').isNotEmpty)
                    'Perdus ${r['lost-packets']}',
                  if ((r['duration'] ?? '').isNotEmpty) r['duration']!,
                ].join(' • '),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    address.dispose();
    user.dispose();
    password.dispose();
    duration.dispose();
    limit.dispose();
    super.dispose();
  }
}
