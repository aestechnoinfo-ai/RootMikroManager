import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppDestructiveActionAuditScreen extends StatefulWidget {
  final RouterOsService service;
  const PppDestructiveActionAuditScreen({super.key, required this.service});

  @override
  State<PppDestructiveActionAuditScreen> createState() => _State();
}

class _State extends State<PppDestructiveActionAuditScreen> {
  bool loading = true;
  int secrets = 0;
  int profiles = 0;
  int active = 0;
  int activeWithSecret = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final values = await Future.wait([
      widget.service.pppSecrets(),
      widget.service.pppProfiles(),
      widget.service.pppActive(),
    ]);
    final secretRows = values[0];
    final profileRows = values[1];
    final activeRows = values[2];
    final names = secretRows.map((e) => e['name'] ?? '').toSet();

    secrets = secretRows.length;
    profiles = profileRows.length;
    active = activeRows.length;
    activeWithSecret = activeRows.where((row) {
      final user = row['name'] ?? row['user'] ?? '';
      return names.contains(user);
    }).length;

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sécurité des suppressions PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Secrets PPP'),
                  trailing: Text('$secrets'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Profils PPP'),
                  trailing: Text('$profiles'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions actives'),
                  trailing: Text('$active'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Sessions liées à un secret'),
                  trailing: Text('$activeWithSecret'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'RootMikroManager bloque la suppression d’un secret '
                    'ayant une session active et la suppression d’un '
                    'profil encore utilisé. La déconnexion reste une '
                    'action séparée et explicite.',
                  ),
                ),
              ),
            ],
          ),
  );
}
