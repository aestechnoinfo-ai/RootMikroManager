import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6NdScreen extends StatefulWidget {
  final RouterOsService service;
  const Ipv6NdScreen({super.key, required this.service});
  @override
  State<Ipv6NdScreen> createState() => _State();
}

class _State extends State<Ipv6NdScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipv6NdProfiles();
    if (mounted) setState(() => loading = false);
  }

  Future<void> toggleAdvertise(Map<String, String> r) async {
    final id = r['.id'];
    if (id == null) return;
    final enabled = r['disabled'] != 'yes';
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              enabled
                  ? 'Désactiver Neighbor Discovery ?'
                  : 'Activer Neighbor Discovery ?',
            ),
            content: Text(
              'Interface : ${r['interface'] ?? 'all'}\nUne modification des Router Advertisements peut changer l’adressage et la route par défaut des clients IPv6.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(enabled ? 'Désactiver' : 'Activer'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await widget.service.set('/ipv6/nd', id, {
        'disabled': enabled ? 'yes' : 'no',
      });
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('IPv6 Neighbor Discovery'),
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
                    'Neighbor Discovery envoie les Router Advertisements utilisés par SLAAC. Modifiez ces paramètres avec prudence sur les interfaces de production.',
                  ),
                ),
              ),
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: Icon(
                      r['disabled'] == 'yes'
                          ? Icons.pause_circle_outline
                          : Icons.campaign_outlined,
                    ),
                    title: Text(r['interface'] ?? 'all'),
                    subtitle: Text(
                      [
                        'RA interval ${r['ra-interval'] ?? '—'}',
                        'lifetime ${r['ra-lifetime'] ?? '—'}',
                        'MTU ${r['mtu'] ?? 'unspecified'}',
                        'managed ${r['managed-address-configuration'] ?? 'no'}',
                        'other ${r['other-configuration'] ?? 'no'}',
                      ].join(' • '),
                    ),
                    trailing: Switch(
                      value: r['disabled'] != 'yes',
                      onChanged: (_) => toggleAdvertise(r),
                    ),
                  ),
                ),
            ],
          ),
  );
}
