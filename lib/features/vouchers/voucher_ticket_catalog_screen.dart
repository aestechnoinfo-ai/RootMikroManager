import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'hotspot_ticket_detail_screen.dart';

class VoucherTicketCatalogScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherTicketCatalogScreen({super.key, required this.service});
  @override
  State<VoucherTicketCatalogScreen> createState() => _S();
}

class _S extends State<VoucherTicketCatalogScreen> {
  bool loading = true;
  String query = '';
  List<Map<String, String>> users = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    users = await widget.service.hotspotUsers();
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, String>> get visible {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where(
          (u) => [
            'name',
            'profile',
            'comment',
            'server',
          ].any((k) => (u[k] ?? '').toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Tickets / Vouchers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Rechercher un ticket',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Cette vue affiche uniquement /ip/hotspot/user. Chaque ligne est un utilisateur/ticket et référence un profil par son champ profile.',
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final u = visible[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.confirmation_number_outlined),
                        title: Text(u['name'] ?? '—'),
                        subtitle: Text(
                          [
                            'Profil ${u['profile'] ?? 'default'}',
                            'Serveur ${u['server'] ?? 'all'}',
                            'Uptime ${u['uptime'] ?? '0s'}',
                            'Limite ${u['limit-uptime'] ?? '0'}',
                          ].join(' • '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final changed = await AppRouter.pushNamed<bool>(
                            context,
                            AppRoutes.voucherTicketDetail,
                            extra: RequiredRowPayload(u),
                          );
                          if (changed == true) await load();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
