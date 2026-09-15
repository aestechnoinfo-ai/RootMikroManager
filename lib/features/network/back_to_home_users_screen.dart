import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class BackToHomeUsersScreen extends StatefulWidget {
  final RouterOsService service;
  const BackToHomeUsersScreen({super.key, required this.service});
  @override
  State<BackToHomeUsersScreen> createState() => _State();
}

class _State extends State<BackToHomeUsersScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      rows = await widget.service.backToHomeUsers();
      error = null;
    } catch (e) {
      error = e;
      rows = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Map<String, String> safe(Map<String, String> r) {
    const hidden = {
      'private-key',
      'preshared-key',
      'client-config',
      'config',
      'qr-code',
      'secret',
      'password',
    };
    return Map.fromEntries(r.entries.where((e) => !hidden.contains(e.key)));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Back To Home • Utilisateurs'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Vue volontairement non sensible : aucune clé privée, secret, configuration client ou QR code n’est affiché par RootMikroManager.',
                  ),
                ),
              ),
              if (error != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Back To Home indisponible'),
                    subtitle: Text('$error'),
                  ),
                ),
              for (final r in rows)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(
                      r['name'] ?? r['comment'] ?? r['id'] ?? 'Utilisateur',
                    ),
                    subtitle: Text(
                      r['disabled'] == 'yes' ? 'désactivé' : 'actif',
                    ),
                    children: [
                      for (final e in safe(r).entries)
                        ListTile(
                          dense: true,
                          title: Text(e.key),
                          trailing: Flexible(
                            child: Text(e.value, textAlign: TextAlign.right),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
  );
}
