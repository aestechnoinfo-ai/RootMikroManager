import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';

enum RouterLogAction { clear, limit200, restoreDefault }

class RouterLogActionsMenu extends StatefulWidget {
  const RouterLogActionsMenu({
    super.key,
    required this.service,
    this.onChanged,
    this.enabled = true,
  });

  final RouterOsService service;
  final Future<void> Function()? onChanged;
  final bool enabled;

  @override
  State<RouterLogActionsMenu> createState() => _RouterLogActionsMenuState();
}

class _RouterLogActionsMenuState extends State<RouterLogActionsMenu> {
  bool busy = false;

  Future<void> _run(RouterLogAction action) async {
    final description = switch (action) {
      RouterLogAction.clear =>
        'Vider maintenant tous les buffers mémoire de journaux ? Cette action est irréversible.',
      RouterLogAction.limit200 =>
        'Limiter durablement le buffer mémoire principal à 200 lignes ? La modification reste active après redémarrage du routeur.',
      RouterLogAction.restoreDefault =>
        'Retirer la limite de 200 lignes et restaurer le buffer mémoire principal à 1 000 lignes ?',
    };
    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmer sur le routeur'),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!accepted || !mounted) return;
    setState(() => busy = true);
    try {
      final message = switch (action) {
        RouterLogAction.clear =>
          'Buffers mémoire vidés (${await widget.service.clearAllMemoryLogs()}).',
        RouterLogAction.limit200 =>
          await widget.service.limitDefaultMemoryLogsTo200().then(
            (_) => 'Limite permanente fixée à 200 lignes.',
          ),
        RouterLogAction.restoreDefault =>
          await widget.service.disableDefaultMemoryLogLimit().then(
            (_) => 'Limite de 200 retirée ; buffer restauré à 1 000 lignes.',
          ),
      };
      await widget.onChanged?.call();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Échec : $error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => busy
      ? const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : PopupMenuButton<RouterLogAction>(
          tooltip: 'Actions sur les logs',
          enabled: widget.enabled,
          icon: const Icon(Icons.cleaning_services_outlined),
          onSelected: _run,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: RouterLogAction.clear,
              child: Text('Vider les logs mémoire'),
            ),
            PopupMenuItem(
              value: RouterLogAction.limit200,
              child: Text('Limiter à 200 lignes'),
            ),
            PopupMenuItem(
              value: RouterLogAction.restoreDefault,
              child: Text('Retirer la limite de 200'),
            ),
          ],
        );
}
