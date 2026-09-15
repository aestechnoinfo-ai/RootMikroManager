import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'voucher_batch_lifecycle_service.dart';
import 'voucher_router_ticket_filter.dart';

class VoucherBatchPreviewScreen extends StatefulWidget {
  final RouterOsService service;
  const VoucherBatchPreviewScreen({super.key, required this.service});
  @override
  State<VoucherBatchPreviewScreen> createState() => _State();
}

class _State extends State<VoucherBatchPreviewScreen> {
  final search = TextEditingController();
  final filter = const VoucherRouterTicketFilter();
  final selected = <String>{};
  List<Map<String, String>> rows = [];
  String profile = VoucherRouterTicketFilter.all;
  String comment = VoucherRouterTicketFilter.all;
  bool loading = true, deleting = false;
  bool unusedOnly = true;
  int completed = 0;
  String? error;

  List<Map<String, String>> get shown {
    final result = filter.apply(
      rows,
      query: search.text,
      profile: profile,
      comment: comment,
    );
    return unusedOnly
        ? result.where((row) => filter.isUnused(row)).toList()
        : result;
  }

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await widget.service.hotspotUsers();
      selected.removeWhere((id) => !rows.any((row) => row['.id'] == id));
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> deleteTickets(List<Map<String, String>> targets) async {
    if (targets.isEmpty || deleting) return;
    final used = targets.where((row) => !filter.isUnused(row)).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${targets.length} ticket(s) ?'),
        content: Text(
          '${targets.length - used} inutilisé(s), $used déjà utilisé(s).\n\n'
          'Les sessions, cookies et schedulers associés seront nettoyés. '
          'Les profils Hotspot seront conservés. Cette action RouterOS est '
          'irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      deleting = true;
      completed = 0;
    });
    final result = await VoucherBatchLifecycleService(widget.service)
        .deleteTickets(
          targets,
          onProgress: (value) {
            if (mounted) setState(() => completed = value);
          },
        );
    await load();
    selected.clear();
    if (!mounted) return;
    setState(() => deleting = false);
    await AppRouter.pushNamed(
      context,
      AppRoutes.voucherBatchLifecycleResult,
      extra: VoucherBatchLifecycleResultPayload(
        title: 'Résultat de la suppression',
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = shown;
    final selectedRows = rows
        .where((row) => selected.contains(row['.id']))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppression de tickets'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: loading || deleting ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: FilledButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: Text('Réessayer : $error'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Filtre exact par profil ou commentaire. Les lots '
                        'Mikhmon vc-/up- sont identifiés automatiquement.',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: search,
                        decoration: const InputDecoration(
                          labelText: 'Utilisateur, profil ou commentaire',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: unusedOnly,
                        title: const Text('Tickets inutilisés uniquement'),
                        subtitle: const Text(
                          'Activé par défaut, comme Mikhmon officiel.',
                        ),
                        onChanged: deleting
                            ? null
                            : (value) => setState(() {
                                unusedOnly = value;
                                selected.clear();
                              }),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = [
                            _dropdown(
                              'Profil',
                              profile,
                              'Tous les profils',
                              filter.values(rows, 'profile'),
                              (value) => profile = value,
                            ),
                            _dropdown(
                              'Commentaire / lot',
                              comment,
                              'Tous les commentaires',
                              filter.values(rows, 'comment'),
                              (value) => comment = value,
                              markMikhmon: true,
                            ),
                          ];
                          if (constraints.maxWidth < 620) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 8),
                                fields[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 8),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: deleting
                                ? null
                                : () => setState(
                                    () => selected.addAll(
                                      visible
                                          .map((row) => row['.id'])
                                          .whereType<String>(),
                                    ),
                                  ),
                            child: Text(
                              'Sélectionner affichés (${visible.length})',
                            ),
                          ),
                          TextButton(
                            onPressed: deleting
                                ? null
                                : () => setState(selected.clear),
                            child: const Text('Désélectionner'),
                          ),
                          Chip(
                            label: Text('${selected.length} sélectionné(s)'),
                          ),
                        ],
                      ),
                      if (deleting) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: targetsProgress(selectedRows.length),
                        ),
                        Text('$completed / ${selectedRows.length} traité(s)'),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final row = visible[index];
                      final id = row['.id'];
                      final note = row['comment'] ?? '';
                      return CheckboxListTile(
                        value: id != null && selected.contains(id),
                        onChanged: deleting || id == null
                            ? null
                            : (checked) => setState(() {
                                checked == true
                                    ? selected.add(id)
                                    : selected.remove(id);
                              }),
                        secondary: IconButton(
                          tooltip: 'Supprimer ce ticket',
                          onPressed: deleting
                              ? null
                              : () => deleteTickets([row]),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        title: Text(row['name'] ?? '—'),
                        subtitle: Text(
                          'Profil ${row['profile'] ?? '—'} • uptime '
                          '${row['uptime'] ?? '0s'}\n'
                          '${note.isEmpty ? 'Sans commentaire' : note}'
                          '${filter.isMikhmonComment(note) ? ' • Mikhmon' : ''}',
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: deleting || selectedRows.isEmpty
                            ? null
                            : () => deleteTickets(selectedRows),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(
                          'Supprimer la sélection (${selectedRows.length})',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  double? targetsProgress(int count) => count == 0 ? null : completed / count;

  Widget _dropdown(
    String label,
    String value,
    String allLabel,
    List<String> values,
    ValueChanged<String> save, {
    bool markMikhmon = false,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem(
        value: VoucherRouterTicketFilter.all,
        child: Text(allLabel),
      ),
      ...values.map(
        (item) => DropdownMenuItem(
          value: item,
          child: Text(
            markMikhmon && filter.isMikhmonComment(item)
                ? 'Mikhmon • $item'
                : item,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    onChanged: deleting
        ? null
        : (next) => setState(() => save(next ?? VoucherRouterTicketFilter.all)),
  );

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }
}
