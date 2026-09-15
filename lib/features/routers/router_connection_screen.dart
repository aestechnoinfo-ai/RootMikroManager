import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/network/ip_scanner_service.dart';
import '../../core/routeros/router_session.dart';
import '../../core/security/secure_store.dart';
import '../../data/models/router_model.dart';
import '../../data/repositories/router_repository.dart';

class RouterConnectionScreen extends StatefulWidget {
  final RouterModel router;
  final IpScannerService? scanner;
  const RouterConnectionScreen({super.key, required this.router, this.scanner});

  @override
  State<RouterConnectionScreen> createState() => _RouterConnectionScreenState();
}

class _RouterConnectionScreenState extends State<RouterConnectionScreen> {
  final password = TextEditingController();
  late final scanner = widget.scanner ?? IpScannerService();
  bool connecting = false;
  bool pinging = false;
  bool pingSucceeded = false;
  bool allowSelfSigned = false;
  String status = '';

  bool get loading => connecting || pinging;

  Future<void> pingRouter() async {
    if (loading) return;
    setState(() {
      pinging = true;
      pingSucceeded = false;
      status = 'Test de ${widget.router.host}:${widget.router.port}…';
    });
    final watch = Stopwatch()..start();
    try {
      final result = await scanner.probeHost(
        widget.router.host,
        widget.router.port,
        timeout: const Duration(seconds: 3),
        retries: 1,
      );
      watch.stop();
      pingSucceeded = result.status == ScanHostStatus.online;
      status = result.status == ScanHostStatus.online
          ? 'Accessible : port ${widget.router.port} ouvert '
                '(${watch.elapsedMilliseconds} ms, ${result.attempts} tentative(s)).'
          : 'Inaccessible : aucune réponse sur le port '
                '${widget.router.port} après ${result.attempts} tentatives.';
    } catch (e) {
      watch.stop();
      status = 'Échec du test réseau : $e';
    }
    if (mounted) setState(() => pinging = false);
  }

  @override
  void initState() {
    super.initState();
    SecureStore().readRouterPassword(widget.router.id!).then((v) {
      if (v != null && mounted) password.text = v;
    });
  }

  Future<void> connect() async {
    if (loading || !pingSucceeded) return;
    var connected = false;
    setState(() {
      connecting = true;
      status = '';
    });
    try {
      await RouterSession.instance.connect(
        widget.router,
        password.text,
        allowSelfSignedCertificate: allowSelfSigned,
      );
      final identity = await RouterSession.instance.service.identity();
      final enrichedRouter = RouterModel(
        id: widget.router.id,
        name: widget.router.name,
        host: widget.router.host,
        port: widget.router.port,
        username: widget.router.username,
        groupName: widget.router.groupName,
        tags: widget.router.tags,
        colorValue: widget.router.colorValue,
        createdAt: widget.router.createdAt,
        macAddress: widget.router.macAddress,
        romonId: widget.router.romonId,
        useTls: widget.router.useTls,
        protocols: widget.router.protocols,
        boardName: widget.router.boardName,
      );
      RouterSession.instance.registerActiveRouter(
        enrichedRouter,
        password.text,
      );
      await RouterRepository().update(enrichedRouter);
      await SecureStore().saveRouterPassword(widget.router.id!, password.text);
      status = 'Connecté à ${identity['name'] ?? widget.router.name}';
      connected = true;
    } catch (e) {
      await RouterSession.instance.disconnect();
      pingSucceeded = false;
      status = 'Erreur : $e';
    }
    if (mounted) setState(() => connecting = false);
    if (mounted && connected) context.goNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.router.name)),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.router.host}:${widget.router.port}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe RouterOS',
              ),
            ),
            if (widget.router.useTls || widget.router.port == 8729) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Autoriser certificat auto-signé'),
                subtitle: const Text(
                  'Désactivez pour exiger un certificat TLS valide.',
                ),
                value: allowSelfSigned,
                onChanged: loading
                    ? null
                    : (value) => setState(() => allowSelfSigned = value),
              ),
              Text(
                'API-SSL TLS actif sur le port ${widget.router.port}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 420;
                final buttons = [
                  OutlinedButton.icon(
                    onPressed: loading ? null : pingRouter,
                    icon: const Icon(Icons.network_ping),
                    label: Text(pinging ? 'Ping en cours…' : 'Pinger'),
                  ),
                  FilledButton.icon(
                    onPressed: loading || !pingSucceeded ? null : connect,
                    icon: const Icon(Icons.login),
                    label: Text(connecting ? 'Connexion…' : 'Connecter'),
                  ),
                ];
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons[0],
                      const SizedBox(height: 8),
                      buttons[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            if (!pingSucceeded && !loading)
              const Text('Effectuez un ping réussi pour activer Connecter.'),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (RouterSession.instance.activeRouter != null)
              TextButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        await RouterSession.instance.disconnect();
                        if (mounted) {
                          setState(() {
                            pingSucceeded = false;
                            status = 'Session fermée';
                          });
                        }
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Déconnecter'),
              ),
            if (status.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(status),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }
}
