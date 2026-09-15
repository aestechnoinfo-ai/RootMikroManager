import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'hotspot_profile_config.dart';
import 'hotspot_profile_validator.dart';

class HotspotProfileSafetyScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotProfileSafetyScreen({super.key, required this.service});

  @override
  State<HotspotProfileSafetyScreen> createState() => _State();
}

class _State extends State<HotspotProfileSafetyScreen> {
  bool loading = true;
  List<String> issues = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final values = await Future.wait([
      widget.service.hotspotProfiles(),
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
      widget.service.schedulers(),
    ]);

    final profiles = values[0];
    final users = values[1];
    final active = values[2];
    final schedulers = values[3];
    final validator = const HotspotProfileValidator();
    final out = <String>[];

    for (final row in profiles) {
      final config = HotspotProfileConfig.fromRouterOs(row);
      for (final issue in validator.validate(
        config,
        existingProfiles: profiles,
      )) {
        out.add('${config.name}: $issue');
      }

      final expirable = config.expirationMode != HotspotExpirationMode.none;
      final monitorCount = schedulers
          .where((e) => e['name'] == config.name)
          .length;

      if (expirable && monitorCount == 0) {
        out.add('${config.name}: scheduler de validité absent.');
      }
      if (!expirable && monitorCount > 0) {
        out.add('${config.name}: scheduler présent sans mode d’expiration.');
      }
      if (monitorCount > 1) {
        out.add('${config.name}: $monitorCount schedulers homonymes.');
      }

      final ticketCount = users
          .where((e) => e['profile'] == config.name)
          .length;
      final activeCount = active
          .where((e) => e['profile'] == config.name)
          .length;

      if (activeCount > ticketCount) {
        out.add('${config.name}: plus de sessions actives que de tickets.');
      }
    }

    issues = out;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sécurité profils Hotspot'),
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
                    'Audit des profils uniquement. Aucun ticket ni profil '
                    'n’est modifié automatiquement.',
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Profils Hotspot cohérents.'),
                  ),
                ),
              for (final issue in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(issue),
                  ),
                ),
            ],
          ),
  );
}
