import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/router_session.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/routeros/routeros_client.dart';
import '../../core/network/ip_scanner_service.dart';

import '../../core/security/secure_store.dart';
import '../../data/models/router_model.dart';
import '../../data/repositories/router_repository.dart';
import '../../shared/widgets/mikrotik_router_image.dart';
import '../discovery/discovery_candidate.dart';
import 'router_card_palette.dart';

class RoutersScreen extends StatefulWidget {
  const RoutersScreen({super.key});

  @override
  State<RoutersScreen> createState() => _RoutersScreenState();
}

class _RoutersScreenState extends State<RoutersScreen> {
  final repo = RouterRepository();
  final secureStore = SecureStore();
  final scanner = IpScannerService();
  final Map<String, ScanHostStatus> routerStatus = {};
  CancellationToken? statusToken;
  bool checkingRouters = false;

  final searchController = TextEditingController();

  String selectedGroup = 'Tous';

  String statusKey(RouterModel router) =>
      router.id?.toString() ?? '${router.host}:${router.port}';

  Color statusColor(RouterModel router) {
    return switch (routerStatus[statusKey(router)] ?? ScanHostStatus.pending) {
      ScanHostStatus.pending => Colors.grey,
      ScanHostStatus.scanning => Colors.grey,
      ScanHostStatus.online => Colors.green,
      ScanHostStatus.offline => Colors.red,
      ScanHostStatus.authError => Colors.orange,
    };
  }

  Future<void> checkSavedRouters(List<RouterModel> routers) async {
    if (checkingRouters) {
      statusToken?.cancel();
      setState(() => checkingRouters = false);
      return;
    }
    final token = CancellationToken();
    statusToken = token;
    setState(() {
      checkingRouters = true;
      for (final router in routers) {
        routerStatus[statusKey(router)] = ScanHostStatus.scanning;
      }
    });
    try {
      for (final router in routers) {
        if (token.isCancelled) break;
        final result = await scanner.probeHost(
          router.host,
          router.port,
          timeout: const Duration(seconds: 3),
          retries: 1,
          cancellationToken: token,
        );
        if (!mounted || token.isCancelled) break;
        var verifiedStatus = ScanHostStatus.offline;
        if (result.status == ScanHostStatus.online && router.id != null) {
          final probe = RouterOsService();
          try {
            final secret = await secureStore.readRouterPassword(router.id!);
            if (token.isCancelled) break;
            if (secret != null && secret.isNotEmpty) {
              await probe.connect(
                router,
                secret,
                allowSelfSignedCertificate: false,
              );
              await probe.identity();
              verifiedStatus = ScanHostStatus.online;
            }
          } on RouterOsAuthenticationException {
            verifiedStatus = ScanHostStatus.authError;
          } catch (_) {
            verifiedStatus = ScanHostStatus.offline;
          } finally {
            await probe.client.close();
          }
        }
        if (!mounted || token.isCancelled) break;
        setState(() => routerStatus[statusKey(router)] = verifiedStatus);
      }
    } on ScanCancelledException {
      // L'annulation est une sortie normale demandée par l'utilisateur.
    } finally {
      if (mounted && identical(statusToken, token)) {
        setState(() => checkingRouters = false);
      }
    }
  }

  Future<void> openDiscovery(String routeName) async {
    final requiresRouter =
        routeName == AppRoutes.discoveryNeighbors ||
        routeName == AppRoutes.discoveryRomon;
    if (requiresRouter && !RouterSession.instance.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Neighbors et RoMON nécessitent un premier routeur connecté. '
            'Utilisez Scan IP pour découvrir ce premier routeur.',
          ),
        ),
      );
      return;
    }

    await AppRouter.pushNamed(context, routeName);
    if (mounted) setState(() {});
  }

  Future<void> openEditor([RouterModel? existing]) async {
    if (existing == null) {
      await AppRouter.pushNamed(
        context,
        AppRoutes.discoveryCandidateSave,
        extra: const DiscoveryCandidatePayload(
          DiscoveryCandidate(source: 'Manuel'),
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    final name = TextEditingController(text: existing.name);
    final host = TextEditingController(text: existing.host);
    final username = TextEditingController(text: existing.username);
    final port = TextEditingController(text: '${existing.port}');
    final password = TextEditingController();
    final group = TextEditingController(text: existing.groupName);
    final tags = TextEditingController(text: existing.tags);

    if (existing.id != null) {
      password.text = await secureStore.readRouterPassword(existing.id!) ?? '';
    }

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le routeur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: host,
                decoration: const InputDecoration(labelText: 'IP / Domaine'),
              ),
              TextField(
                controller: port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port API'),
              ),
              TextField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: 'Utilisateur RouterOS',
                ),
              ),
              TextField(
                controller: group,
                decoration: const InputDecoration(labelText: 'Groupe'),
              ),
              TextField(
                controller: tags,
                decoration: const InputDecoration(
                  labelText: 'Tags (séparés par des virgules)',
                ),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok != true ||
        name.text.trim().isEmpty ||
        host.text.trim().isEmpty ||
        username.text.trim().isEmpty) {
      return;
    }

    final router = RouterModel(
      id: existing.id,
      name: name.text.trim(),
      host: host.text.trim(),
      port: int.tryParse(port.text) ?? 8728,
      username: username.text.trim(),
      groupName: group.text.trim().isEmpty ? 'Général' : group.text.trim(),
      tags: tags.text.trim(),
      colorValue: existing.colorValue,
      createdAt: existing.createdAt,
      macAddress: existing.macAddress,
      romonId: existing.romonId,
      useTls: existing.useTls,
      protocols: existing.protocols,
      boardName: existing.boardName,
    );

    final probe = RouterOsService();
    try {
      await probe.connect(
        router,
        password.text,
        allowSelfSignedCertificate: false,
      );
      await probe.identity();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modifications non enregistrées : $error')),
        );
      }
      return;
    } finally {
      await probe.client.close();
    }
    if (RouterSession.instance.activeRouter?.id == existing.id) {
      await RouterSession.instance.disconnect();
    }
    await repo.update(router);
    await secureStore.saveRouterPassword(existing.id!, password.text);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteRouter(RouterModel router) async {
    if (router.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le routeur ?'),
        content: Text(
          'Le routeur « ${router.name} » '
          'sera supprimé.',
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
    );

    if (confirmed != true) return;

    await repo.remove(router.id!);
    await secureStore.deleteRouterPassword(router.id!);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routeurs')),
      body: FutureBuilder<List<String>>(
        future: repo.groups(),
        builder: (context, groupSnapshot) {
          final groups = groupSnapshot.data ?? const ['Tous'];

          return FutureBuilder<List<RouterModel>>(
            future: repo.all(
              search: searchController.text,
              group: selectedGroup,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final routers = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final group in groups)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(group),
                                selected: selectedGroup == group,
                                onSelected: (_) {
                                  setState(() => selectedGroup = group);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttonWidth = constraints.maxWidth >= 720
                            ? (constraints.maxWidth - 16) / 3
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: buttonWidth,
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    openDiscovery(AppRoutes.discoveryIpScan),
                                icon: const Icon(Icons.radar),
                                label: const Text('Scanner le réseau'),
                              ),
                            ),
                            SizedBox(
                              width: buttonWidth,
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    openDiscovery(AppRoutes.discoveryNeighbors),
                                icon: const Icon(Icons.device_hub_outlined),
                                label: const Text('Neighbors'),
                              ),
                            ),
                            SizedBox(
                              width: buttonWidth,
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    openDiscovery(AppRoutes.discoveryRomon),
                                icon: const Icon(Icons.hub_outlined),
                                label: const Text('RoMON'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${routers.length} routeur(s)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: checkingRouters
                              ? 'Arrêter la vérification'
                              : 'Vérifier les routeurs enregistrés',
                          onPressed: routers.isEmpty
                              ? null
                              : () => checkSavedRouters(routers),
                          icon: Icon(
                            checkingRouters
                                ? Icons.stop_circle
                                : Icons.wifi_find,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => openEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final router in routers)
                      Card(
                        color: RouterCardPalette.colorFor(
                          router,
                          Theme.of(context).brightness,
                        ),
                        surfaceTintColor: Colors.transparent,
                        elevation: 4,
                        shadowColor: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.35),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          minVerticalPadding: 12,
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              MikrotikRouterImage(
                                boardName: router.boardName,
                                size: 52,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: statusColor(router),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(router.name),
                          subtitle: Text(
                            [
                              '${router.host}:${router.port}',
                              router.username,
                              router.groupName,
                              if (router.tags.isNotEmpty) router.tags,
                            ].join(' • '),
                          ),
                          onTap: () => AppRouter.pushNamed(
                            context,
                            AppRoutes.routerConnection,
                            extra: RouterConnectionPayload(router),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                openEditor(router);
                              }
                              if (value == 'delete') {
                                deleteRouter(router);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    statusToken?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
