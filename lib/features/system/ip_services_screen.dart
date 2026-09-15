import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class IpServicesScreen extends StatefulWidget {
  final RouterOsService service;
  const IpServicesScreen({super.key, required this.service});

  @override
  State<IpServicesScreen> createState() => _IpServicesScreenState();
}

class _IpServicesScreenState extends State<IpServicesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipServices();
    if (mounted) setState(() => loading = false);
  }

  Future<void> editor(Map<String, String> row) async {
    final port = TextEditingController(text: row['port'] ?? '');
    final address = TextEditingController(text: row['address'] ?? '');
    final maxSessions = TextEditingController(text: row['max-sessions'] ?? '');
    final certificate = TextEditingController(text: row['certificate'] ?? '');
    bool enabled = row['disabled'] != 'yes' && row['disabled'] != 'true';

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, local) => AlertDialog(
              title: Text(row['name'] ?? 'Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: port,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Port'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Adresses autorisées',
                        helperText: 'Ex: 192.168.88.0/24',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxSessions,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max sessions',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: certificate,
                      decoration: const InputDecoration(
                        labelText: 'Certificat',
                        helperText: 'Pour www-ssl / api-ssl si applicable',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activé'),
                      value: enabled,
                      onChanged: (v) => local(() => enabled = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!ok || row['.id'] == null) return;
    await widget.service.set('/ip/service', row['.id']!, {
      if (port.text.trim().isNotEmpty) 'port': port.text.trim(),
      'address': address.text.trim(),
      if (maxSessions.text.trim().isNotEmpty)
        'max-sessions': maxSessions.text.trim(),
      if (certificate.text.trim().isNotEmpty)
        'certificate': certificate.text.trim(),
      'disabled': enabled ? 'no' : 'yes',
    });
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Services IP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final disabled =
                    r['disabled'] == 'yes' || r['disabled'] == 'true';
                return Card(
                  child: ListTile(
                    onTap: () => editor(r),
                    leading: Icon(
                      disabled ? Icons.lock_outline : Icons.lock_open,
                    ),
                    title: Text(r['name'] ?? '—'),
                    subtitle: Text(
                      [
                        'Port ${r['port'] ?? '—'}',
                        if ((r['address'] ?? '').isNotEmpty)
                          'Adresse ${r['address']}',
                        if ((r['certificate'] ?? '').isNotEmpty)
                          'Cert ${r['certificate']}',
                      ].join(' • '),
                    ),
                    trailing: Text(disabled ? 'Off' : 'On'),
                  ),
                );
              },
            ),
          ),
  );
}
