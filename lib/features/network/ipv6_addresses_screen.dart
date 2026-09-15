import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class Ipv6AddressesScreen extends StatefulWidget {
  final RouterOsService service;
  const Ipv6AddressesScreen({super.key, required this.service});
  @override
  State<Ipv6AddressesScreen> createState() => _State();
}

class _State extends State<Ipv6AddressesScreen> {
  bool loading = true;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    rows = await widget.service.ipv6Addresses();
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, String>? r]) async {
    if (r?['dynamic'] == 'yes') return;
    final x = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.ipv6AddressEdit,
      extra: OptionalRowPayload(r),
    );
    if (x == true) await load();
  }

  Future<void> removeAddress(Map<String, String> r) async {
    if (r['dynamic'] == 'yes') return;
    final id = r['.id'];
    if (id == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cette adresse IPv6 ?'),
            content: Text(
              '${r['address'] ?? '—'} sur ${r['interface'] ?? '—'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await widget.service.remove('/ipv6/address', id);
      await load();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Adresses IPv6'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse IPv6'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final r in rows)
                      Card(
                        child: ListTile(
                          onTap: () => edit(r),
                          leading: Icon(
                            r['dynamic'] == 'yes'
                                ? Icons.auto_awesome
                                : Icons.language,
                          ),
                          title: Text(r['address'] ?? '—'),
                          subtitle: Text(
                            '${r['interface'] ?? '—'} • advertise ${r['advertise'] ?? 'no'} • ${r['disabled'] == 'yes' ? 'désactivée' : 'active'}',
                          ),
                          trailing: r['dynamic'] == 'yes'
                              ? const Chip(label: Text('dynamique'))
                              : IconButton(
                                  onPressed: () => removeAddress(r),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
