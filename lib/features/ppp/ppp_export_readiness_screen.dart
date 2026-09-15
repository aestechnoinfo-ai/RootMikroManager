import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppExportReadinessScreen extends StatefulWidget {
  final RouterOsService service;
  const PppExportReadinessScreen({super.key, required this.service});

  @override
  State<PppExportReadinessScreen> createState() => _State();
}

class _State extends State<PppExportReadinessScreen> {
  bool loading = true;
  int secrets = 0;
  int profiles = 0;
  int withPassword = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final values = await Future.wait([
      widget.service.pppSecrets(),
      widget.service.pppProfiles(),
    ]);
    final rows = values[0];
    secrets = rows.length;
    profiles = values[1].length;
    withPassword = rows.where((e) => (e['password'] ?? '').isNotEmpty).length;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Préparation export PPP')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Secrets'),
                  trailing: Text('$secrets'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Profils'),
                  trailing: Text('$profiles'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Secrets avec mot de passe lisible'),
                  trailing: Text('$withPassword'),
                ),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'L’export PPP doit rester sans mots de passe par '
                    'défaut. L’inclusion de mots de passe crée un fichier '
                    'en clair et doit rester une décision explicite.',
                  ),
                ),
              ),
            ],
          ),
  );
}
