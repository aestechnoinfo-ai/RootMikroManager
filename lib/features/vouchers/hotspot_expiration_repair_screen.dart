import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'voucher_batch_lifecycle_result_screen.dart';
import 'voucher_batch_lifecycle_service.dart';

class HotspotExpirationRepairScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotExpirationRepairScreen({super.key, required this.service});
  @override
  State<HotspotExpirationRepairScreen> createState() => _State();
}

class _State extends State<HotspotExpirationRepairScreen> {
  bool loading = true, working = false;
  List<Map<String, String>> rows = [];
  final selected = <String>{};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    rows = await widget.service.hotspotUsersFiltered(expiredOnly: true);
    selected.removeWhere((x) => !rows.any((r) => r['.id'] == x));
    if (mounted) setState(() => loading = false);
  }

  Future<void> repair() async {
    final targets = rows.where((r) => selected.contains(r['.id'])).toList();
    if (targets.isEmpty) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nettoyer les tickets expirés ?'),
            content: Text(
              '${targets.length} ticket(s) seront traités dans cet ordre : cookies, sessions actives, scheduler utilisateur, ticket.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nettoyer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    setState(() => working = true);
    final result = await VoucherBatchLifecycleService(
      widget.service,
    ).deleteTickets(targets);
    selected.clear();
    await load();
    if (!mounted) return;
    setState(() => working = false);
    await AppRouter.pushNamed(
      context,
      AppRoutes.voucherBatchLifecycleResult,
      extra: VoucherBatchLifecycleResultPayload(
        title: 'Résultat du nettoyage',
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Réparer expirations (${rows.length})'),
      actions: [
        IconButton(
          onPressed: loading || working ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
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
                    'Cette vue ne touche qu’aux tickets déjà marqués expirés. Elle n’efface jamais un profil Hotspot.',
                  ),
                ),
              ),
              if (rows.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: working
                          ? null
                          : () => setState(() {
                              selected
                                ..clear()
                                ..addAll(
                                  rows.map((e) => e['.id']).whereType<String>(),
                                );
                            }),
                      child: const Text('Tout sélectionner'),
                    ),
                    OutlinedButton(
                      onPressed: working
                          ? null
                          : () => setState(selected.clear),
                      child: const Text('Tout désélectionner'),
                    ),
                  ],
                ),
              for (final r in rows)
                CheckboxListTile(
                  value: selected.contains(r['.id']),
                  onChanged: working
                      ? null
                      : (v) => setState(() {
                          final id = r['.id'];
                          if (id == null) return;
                          if (v == true)
                            selected.add(id);
                          else
                            selected.remove(id);
                        }),
                  title: Text(r['name'] ?? '—'),
                  subtitle: Text(
                    'Profil ${r['profile'] ?? '—'} • commentaire ${r['comment'] ?? '—'}',
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: working || selected.isEmpty ? null : repair,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(
                  working
                      ? 'Nettoyage…'
                      : 'Nettoyer la sélection (${selected.length})',
                ),
              ),
            ],
          ),
  );
}
