import 'hotspot_expiry_cleanup_hub_screen.dart';
import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'hotspot_profile_config.dart';
import 'hotspot_profile_delete_guard.dart';
import 'hotspot_users_screen.dart';
import '../../core/settings/app_currency_settings.dart';

class HotspotManagementScreen extends StatefulWidget {
  final RouterOsService service;
  final int initialIndex;
  const HotspotManagementScreen({
    super.key,
    required this.service,
    this.initialIndex = 0,
  });
  @override
  State<HotspotManagementScreen> createState() =>
      _HotspotManagementScreenState();
}

class _HotspotManagementScreenState extends State<HotspotManagementScreen> {
  late int index;
  static const sections = [
    ('Utilisateurs', Icons.people_outline),
    ('Profils', Icons.badge_outlined),
    ('Actifs', Icons.online_prediction_outlined),
    ('Cookies', Icons.cookie_outlined),
    ('Hosts', Icons.lan_outlined),
    ('IP Binding', Icons.link_outlined),
    ('Expiration', Icons.timer_off_outlined),
  ];
  @override
  void initState() {
    super.initState();
    index = widget.initialIndex.clamp(0, sections.length - 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hotspot')),
    body: LayoutBuilder(
      builder: (context, c) {
        final body = _section(index);
        if (c.maxWidth >= 760) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (v) => setState(() => index = v),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final s in sections)
                    NavigationRailDestination(
                      icon: Icon(s.$2),
                      label: Text(s.$1),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          );
        }
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < sections.length; i++)
                    ButtonSegment(
                      value: i,
                      icon: Icon(sections[i].$2),
                      label: Text(sections[i].$1),
                    ),
                ],
                selected: {index},
                onSelectionChanged: (v) => setState(() => index = v.first),
              ),
            ),
            Expanded(child: body),
          ],
        );
      },
    ),
  );
  Widget _section(int i) {
    switch (i) {
      case 0:
        return _Users(service: widget.service);
      case 1:
        return _Profiles(service: widget.service);
      case 2:
        return _Rows(
          title: 'Utilisateurs actifs',
          loader: widget.service.activeUsers,
          titleField: 'user',
          fields: const [
            'address',
            'mac-address',
            'uptime',
            'session-time-left',
          ],
        );
      case 3:
        return _Rows(
          title: 'Cookies',
          loader: widget.service.hotspotCookies,
          titleField: 'user',
          fields: const ['mac-address', 'expires-in'],
          service: widget.service,
          removePath: '/ip/hotspot/cookie',
        );
      case 4:
        return _Rows(
          title: 'Hosts',
          loader: widget.service.hotspotHosts,
          titleField: 'mac-address',
          fields: const ['address', 'to-address', 'server'],
        );
      case 5:
        return _Rows(
          title: 'IP Binding',
          loader: widget.service.hotspotIpBindings,
          titleField: 'mac-address',
          fields: const ['address', 'to-address', 'type', 'comment'],
          service: widget.service,
          removePath: '/ip/hotspot/ip-binding',
        );
      default:
        return HotspotExpiryCleanupHubScreen(service: widget.service);
    }
  }
}

class _Users extends StatelessWidget {
  final RouterOsService service;
  const _Users({required this.service});

  @override
  Widget build(BuildContext context) => HotspotUsersScreen(service: service);
}

class _Profiles extends StatefulWidget {
  final RouterOsService service;

  const _Profiles({required this.service});

  @override
  State<_Profiles> createState() => _ProfilesState();
}

class _ProfilesState extends State<_Profiles> {
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;
  String _currency = '';

  @override
  void initState() {
    super.initState();
    AppCurrencySettings.load().then((value) {
      if (mounted) setState(() => _currency = value);
    });
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await widget.service.hotspotProfiles();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> openEditor([Map<String, String>? profile]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.hotspotProfileEdit,
      extra: OptionalRowPayload(profile),
    );

    if (changed == true) await load();
  }

  Future<void> deleteProfile(Map<String, String> profile) async {
    final name = profile['name'] ?? 'ce profil';

    final dependencies = await Future.wait([
      widget.service.hotspotUsers(),
      widget.service.activeUsers(),
    ]);
    final reason = const HotspotProfileDeleteGuard().reason(
      profileName: name,
      users: dependencies[0],
      active: dependencies[1],
    );
    if (reason != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(reason)));
      }
      return;
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le profil ?'),
        content: Text(
          'Le profil "$name" et son scheduler de surveillance '
          'RootMikroManager associé sera supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.service.deleteRootMikroManagerHotspotProfile(profile);
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _Error(message: error!, retry: load);
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () =>
                    AppRouter.pushNamed(context, AppRoutes.hotspotSettings),
                icon: const Icon(Icons.settings_ethernet_outlined),
                label: const Text('Configuration Hotspot'),
              ),
              Text(
                'Profils (${rows.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.icon(
                onPressed: () => openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty) const _Empty('Aucun profil Hotspot.'),
          ...rows.map((profile) {
            final config = HotspotProfileConfig.fromRouterOs(profile);

            final details = <String>[
              'Partage: ${config.sharedUsers}',
              if (config.rateLimit.isNotEmpty) 'Rate: ${config.rateLimit}',
              if (config.addressPool != 'none') 'Pool: ${config.addressPool}',
              'Expiration: ${config.expirationMode.label}',
              if (config.validity.isNotEmpty) 'Validité: ${config.validity}',
              if (config.price != '0')
                'Prix: ${AppCurrencySettings.formatRaw(config.price, _currency)}',
              if (config.sellingPrice != '0')
                'Vente: ${AppCurrencySettings.formatRaw(config.sellingPrice, _currency)}',
              if (config.lockUser) 'MAC Lock',
            ];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(config.name),
                subtitle: Text(details.join(' • ')),
                onTap: () => openEditor(profile),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      openEditor(profile);
                    } else if (action == 'delete') {
                      deleteProfile(profile);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Rows extends StatefulWidget {
  final String title, titleField;
  final List<String> fields;
  final Future<List<Map<String, String>>> Function() loader;
  final RouterOsService? service;
  final String? removePath;
  const _Rows({
    required this.title,
    required this.loader,
    required this.titleField,
    required this.fields,
    this.service,
    this.removePath,
  });
  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  List<Map<String, String>> rows = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await widget.loader();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _Error(message: error!, retry: load);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '${widget.title} (${rows.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty) _Empty('${widget.title} : aucun élément.'),
          ...rows.map(
            (r) => Card(
              child: ListTile(
                title: Text(r[widget.titleField] ?? '—'),
                subtitle: Text(
                  widget.fields
                      .where((f) => (r[f] ?? '').isNotEmpty)
                      .map((f) => '$f: ${r[f]}')
                      .join(' • '),
                ),
                trailing: widget.removePath == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final id = r['.id'];
                          if (id != null) {
                            await widget.service!.remove(
                              widget.removePath!,
                              id,
                            );
                            await load();
                          }
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final Future<void> Function() retry;
  const _Error({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
