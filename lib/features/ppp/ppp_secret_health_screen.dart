import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class PppSecretHealthScreen extends StatefulWidget {
  final RouterOsService service;
  const PppSecretHealthScreen({super.key, required this.service});
  @override
  State<PppSecretHealthScreen> createState() => _S();
}

class _S extends State<PppSecretHealthScreen> {
  bool loading = true;
  List<String> issues = [];
  int total = 0, disabled = 0, noPassword = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final rows = await widget.service.pppSecrets();
    total = rows.length;
    disabled = rows.where((e) => (e['disabled'] ?? 'no') == 'yes').length;
    noPassword = 0;
    issues = [];
    final names = <String, int>{};
    for (final r in rows) {
      final n = r['name'] ?? '';
      if (n.isNotEmpty) names[n] = (names[n] ?? 0) + 1;
      if ((r['password'] ?? '').isEmpty) {
        noPassword++;
        issues.add('$n : aucun mot de passe PPP visible/configuré.');
      }
      if ((r['service'] ?? 'any') == 'any')
        issues.add(
          '$n : service PPP = any, à vérifier si ce compte doit être limité à PPPoE/L2TP/etc.',
        );
    }
    for (final e in names.entries.where((e) => e.value > 1))
      issues.add('${e.key} : nom PPP dupliqué (${e.value}).');
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Santé des comptes PPP'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Secrets $total')),
                  Chip(label: Text('Désactivés $disabled')),
                  Chip(label: Text('Sans mot de passe $noPassword')),
                ],
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cet audit ne révèle jamais les mots de passe. Il signale seulement leur absence apparente et les configurations trop permissives.',
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Aucune alerte simple détectée.'),
                  ),
                ),
              for (final x in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(x),
                  ),
                ),
            ],
          ),
  );
}
