import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'hotspot_ticket_lifecycle_service.dart';

class HotspotTicketDetailScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> ticket;

  const HotspotTicketDetailScreen({
    super.key,
    required this.service,
    required this.ticket,
  });

  @override
  State<HotspotTicketDetailScreen> createState() => _State();
}

class _State extends State<HotspotTicketDetailScreen> {
  late Map<String, String> ticket;
  bool busy = false;
  String status = '';

  HotspotTicketLifecycleService get lifecycle =>
      HotspotTicketLifecycleService(widget.service);

  @override
  void initState() {
    super.initState();
    ticket = Map<String, String>.from(widget.ticket);
  }

  Future<void> refresh() async {
    final id = ticket['.id'];
    if (id == null) return;
    final fresh = await widget.service.hotspotUserById(id);
    if (fresh.isNotEmpty && mounted) setState(() => ticket = fresh);
  }

  Future<bool> confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> clearSession() async {
    setState(() => busy = true);
    final result = await lifecycle.clearSession(ticket['name'] ?? '');
    if (mounted) {
      setState(() {
        busy = false;
        status = result.success
            ? '${result.cookiesRemoved} cookie(s), '
                  '${result.sessionsRemoved} session(s) supprimé(s).'
            : 'Erreur : ${result.error}';
      });
    }
  }

  Future<void> resetTicket() async {
    if (!await confirm(
      'Réinitialiser ce ticket ?',
      'Les cookies, sessions et scheduler associés seront supprimés avant '
          'la remise à zéro du ticket.',
    ))
      return;
    setState(() => busy = true);
    final result = await lifecycle.resetTicket(ticket);
    await refresh();
    if (mounted) {
      setState(() {
        busy = false;
        status = result.success
            ? 'Ticket réinitialisé. Cookies ${result.cookiesRemoved}, '
                  'sessions ${result.sessionsRemoved}, '
                  'schedulers ${result.schedulersRemoved}.'
            : 'Erreur : ${result.error}';
      });
    }
  }

  Future<void> deleteTicket() async {
    if (!await confirm(
      'Supprimer ce ticket ?',
      'Ordre appliqué : cookie → session active → scheduler → ticket. '
          'Le profil Hotspot référencé ne sera pas supprimé.',
    ))
      return;
    setState(() => busy = true);
    final result = await lifecycle.deleteTicket(ticket);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        status = 'Erreur : ${result.error}';
      });
    }
  }

  Widget line(String label, String value) => Card(
    child: ListTile(
      title: Text(label),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          value.isEmpty ? '—' : value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(ticket['name'] ?? 'Ticket'),
      actions: [
        IconButton(
          onPressed: busy ? null : refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Cette fiche représente un ticket /ip/hotspot/user. '
              'Le champ Profil est uniquement une référence vers '
              '/ip/hotspot/user/profile.',
            ),
          ),
        ),
        line('Username', ticket['name'] ?? ''),
        line('Profil', ticket['profile'] ?? ''),
        line('Serveur', ticket['server'] ?? ''),
        line('Uptime', ticket['uptime'] ?? ''),
        line('Limite de temps', ticket['limit-uptime'] ?? ''),
        line('Limite de données', ticket['limit-bytes-total'] ?? ''),
        line('Désactivé', ticket['disabled'] ?? ''),
        line('Commentaire', ticket['comment'] ?? ''),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: busy ? null : clearSession,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('Nettoyer cookie et session'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: busy ? null : resetTicket,
          icon: const Icon(Icons.restart_alt_outlined),
          label: const Text('Réinitialiser le ticket'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : deleteTicket,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Supprimer le ticket'),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(status),
            ),
          ),
        ],
      ],
    ),
  );
}
