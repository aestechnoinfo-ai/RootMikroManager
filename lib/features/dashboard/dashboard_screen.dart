import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';

import '../../core/routeros/router_session.dart';
import '../../core/settings/app_currency_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/router_repository.dart';
import '../../data/models/router_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/mikrotik_router_image.dart';
import '../logs/log_visual_style.dart';
import '../logs/router_log_actions_menu.dart';
import '../reports/sales_sync_coordinator.dart';
import '../reports/sales_cache_repository.dart';
import 'dashboard_data_service.dart';
import 'dashboard_settings.dart';
import 'dashboard_snapshot.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.loaderFactory, this.ensureConnection});
  final DashboardDataService Function()? loaderFactory;
  final Future<void> Function()? ensureConnection;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final routerRepository = RouterRepository();

  DashboardSettings settings = const DashboardSettings();
  DashboardSnapshot? snapshot;
  DashboardDataService? dataService;
  RouterModel? snapshotRouter;
  String? trafficError;
  String currency = '';
  String trafficInterface = '';
  String? error;
  bool loading = true;
  bool refreshing = false;
  bool trafficRefreshing = false;

  Timer? refreshTimer;
  Timer? trafficTimer;
  final List<double> rxHistory = [];
  final List<double> txHistory = [];
  double currentRx = 0;
  double currentTx = 0;
  DateTime? lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RouterSession.instance.status.addListener(_sessionChanged);
    _bootstrap();
  }

  void _sessionChanged() {
    final session = RouterSession.instance;
    if (session.status.value != RouterSessionStatus.online ||
        identical(snapshotRouter, session.activeRouter)) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted && !refreshing) unawaited(_refreshAll());
    });
  }

  Future<void> _bootstrap() async {
    try {
      settings = await DashboardSettings.load()
          .timeout(const Duration(seconds: 5))
          .catchError((_) => settings);
      currency = await AppCurrencySettings.load()
          .timeout(const Duration(seconds: 5))
          .catchError((_) => currency);

      if (!mounted) return;
      if (RouterSession.instance.activeRouter != null) {
        await _refreshAll();
      } else {
        if (mounted) setState(() => loading = false);
      }

      if (error == null) _configureTimers();
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Impossible de charger les paramètres locaux.';
        });
      }
    }
  }

  void _configureTimers() {
    refreshTimer?.cancel();
    trafficTimer?.cancel();

    if (!mounted ||
        !settings.autoRefresh ||
        RouterSession.instance.activeRouter == null) {
      return;
    }

    refreshTimer = Timer.periodic(
      Duration(seconds: settings.refreshSeconds),
      (_) => _refreshAll(background: true),
    );

    trafficTimer = Timer.periodic(
      Duration(seconds: settings.trafficRefreshSeconds),
      (_) => _refreshTraffic(),
    );
  }

  Future<void> _refreshAll({bool background = false}) async {
    if (RouterSession.instance.activeRouter == null || refreshing) return;
    final requestedRouter = RouterSession.instance.activeRouter;
    if (!identical(snapshotRouter, requestedRouter)) {
      snapshotRouter = requestedRouter;
      snapshot = null;
      dataService =
          widget.loaderFactory?.call() ??
          DashboardDataService(
            RouterSession.instance.service,
            salesReader: () async {
              final id = RouterSession.instance.activeRouter?.id;
              if (id == null) return const [];
              return (await const SalesCacheRepository().read(id)).rows;
            },
          );
      trafficInterface = '';
      rxHistory.clear();
      txHistory.clear();
      currentRx = currentTx = 0;
    }
    refreshTimer?.cancel();

    if (mounted) {
      setState(() {
        refreshing = true;
        if (!background && snapshot == null) loading = true;
      });
    }

    try {
      await (widget.ensureConnection?.call() ??
          RouterSession.instance.ensureConnected());
      final routerId = requestedRouter?.id;
      // Populate the sales cache independently from the optional dashboard
      // sections. A timeout while reading tickets/logs must never prevent this
      // one-way background synchronization from starting.
      if (routerId != null) {
        unawaited(_prefetchSales(routerId));
      }
      final loader = dataService!;
      final data = await loader.load(
        settings,
        forceSales: !background,
        cancelled: () =>
            !mounted ||
            !identical(requestedRouter, RouterSession.instance.activeRouter),
        onUpdate: (partial) {
          if (!mounted ||
              !identical(
                requestedRouter,
                RouterSession.instance.activeRouter,
              )) {
            return;
          }
          setState(() {
            snapshot = partial;
            loading = false;
            trafficInterface = loader.chooseTrafficInterface(partial, settings);
          });
        },
      );
      final selected = loader.chooseTrafficInterface(data, settings);
      if (!identical(requestedRouter, RouterSession.instance.activeRouter)) {
        return;
      }
      final boardName = MikrotikRouterImage.bestModel([
        data.routerboard['model'] ?? '',
        data.resource['board-name'] ?? '',
        requestedRouter?.boardName ?? '',
      ]);
      if (routerId != null && boardName.isNotEmpty) {
        try {
          await routerRepository
              .updateBoardName(routerId, boardName)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // Metadata persistence must not prevent displaying live data.
        }
      }

      if (!mounted) return;
      setState(() {
        snapshot = data;
        trafficInterface = selected;
        lastRefresh = DateTime.now();
        error = null;
        loading = false;
        refreshing = false;
      });
      if (routerId != null) {
        final coordinator = SalesSyncCoordinator.instance;
        coordinator.startPeriodic(
          routerId: routerId,
          fetch: () => RouterSession.instance.readIsolated(
            (reader) => reader.rootmikromanagerSalesScripts(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
        refreshing = false;
      });
      // Do not continually restart a failed refresh in the background.
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
        });
        _configureTimers();
        if (RouterSession.instance.activeRouter != null &&
            !identical(requestedRouter, RouterSession.instance.activeRouter)) {
          scheduleMicrotask(() {
            if (mounted) unawaited(_refreshAll());
          });
        }
      }
    }
  }

  Future<void> _prefetchSales(int routerId) async {
    final before = await const SalesCacheRepository().read(routerId);
    if (before.isFresh(DateTime.now().toUtc(), SalesSyncCoordinator.ttl)) {
      return;
    }
    try {
      await SalesSyncCoordinator.instance.sync(
        routerId: routerId,
        fetch: () => RouterSession.instance.readIsolated(
          (reader) => reader.rootmikromanagerSalesScripts(),
        ),
      );
      if (mounted && RouterSession.instance.activeRouter?.id == routerId) {
        unawaited(_refreshAll(background: true));
      }
    } catch (_) {
      // The dashboard continues with the last healthy cache while offline.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final routerId = RouterSession.instance.activeRouter?.id;
      if (routerId != null) {
        SalesSyncCoordinator.instance.startPeriodic(
          routerId: routerId,
          fetch: () => RouterSession.instance.readIsolated(
            (reader) => reader.rootmikromanagerSalesScripts(),
          ),
        );
      }
    } else {
      SalesSyncCoordinator.instance.stopPeriodic();
    }
  }

  Future<void> _refreshTraffic() async {
    if (RouterSession.instance.activeRouter == null ||
        trafficInterface.isEmpty ||
        trafficRefreshing) {
      return;
    }

    trafficRefreshing = true;
    final requestedRouter = RouterSession.instance.activeRouter;
    final requestedInterface = trafficInterface;
    try {
      final row = await RouterSession.instance.service.interfaceTrafficOnce(
        trafficInterface,
      );

      final rx = double.tryParse(row['rx-bits-per-second'] ?? '0') ?? 0;
      final tx = double.tryParse(row['tx-bits-per-second'] ?? '0') ?? 0;

      final maxPoints = math
          .max(
            2,
            settings.trafficWindowSeconds ~/
                math.max(1, settings.trafficRefreshSeconds),
          )
          .toInt();

      if (!mounted ||
          !identical(requestedRouter, RouterSession.instance.activeRouter) ||
          requestedInterface != trafficInterface) {
        return;
      }
      setState(() {
        trafficError = null;
        currentRx = rx;
        currentTx = tx;
        rxHistory.add(rx);
        txHistory.add(tx);

        while (rxHistory.length > maxPoints) {
          rxHistory.removeAt(0);
        }
        while (txHistory.length > maxPoints) {
          txHistory.removeAt(0);
        }
      });
    } catch (_) {
      if (mounted &&
          identical(requestedRouter, RouterSession.instance.activeRouter)) {
        setState(
          () => trafficError = 'Trafic indisponible : dernier relevé conservé.',
        );
      }
    } finally {
      trafficRefreshing = false;
    }
  }

  void _open(String routeName) {
    refreshTimer?.cancel();
    trafficTimer?.cancel();
    AppRouter.pushNamed(context, routeName).then((_) async {
      if (!mounted) return;
      await _bootstrap();
    });
  }

  Color _usageColor(double percentage) {
    if (percentage >= settings.criticalPercent) {
      return Colors.red;
    }
    if (percentage >= settings.warningPercent) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Color _ticketColor(int count) {
    if (count <= settings.ticketCriticalCount) {
      return Colors.red;
    }
    if (count <= settings.ticketWarningCount) {
      return Colors.orange;
    }
    return Colors.green;
  }

  double _number(Map<String, String> row, String key) =>
      double.tryParse(row[key] ?? '') ?? 0;

  double _usedPercent(double total, double free) => total <= 0
      ? 0.0
      : ((total - free) / total * 100).clamp(0, 100).toDouble();

  String _bytes(double bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes;
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[index]}';
  }

  String _bits(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)} Gbps';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} Mbps';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} Kbps';
    }
    return '${value.toStringAsFixed(0)} bps';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RouterSessionStatus>(
      valueListenable: RouterSession.instance.status,
      builder: (context, sessionStatus, _) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/images/logo.png',
                width: 30,
                height: 32,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'RootMikroManager',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            RouterLogActionsMenu(
              service: RouterSession.instance.service,
              enabled:
                  RouterSession.instance.activeRouter != null && !refreshing,
              onChanged: _refreshAll,
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed:
                  RouterSession.instance.activeRouter != null && !refreshing
                  ? () => _refreshAll()
                  : null,
              icon: refreshing && snapshot == null
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        drawer: AppDrawer(
          onSelect: (routeName) {
            if (routeName != AppRoutes.dashboard) _open(routeName);
          },
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RouterSession.instance.activeRouter == null
            ? _disconnected()
            : snapshot == null
            ? _error()
            : RefreshIndicator(onRefresh: _refreshAll, child: _dashboard()),
      ),
    );
  }

  Widget _disconnected() {
    return FutureBuilder<List<RouterModel>>(
      future: routerRepository.all(),
      builder: (context, async) {
        final savedRouters = async.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.router_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Aucun routeur connecté',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${savedRouters.length} routeur(s) enregistré(s). Connecte un routeur '
              'pour afficher le tableau de bord temps réel.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _open(AppRoutes.routers),
              icon: const Icon(Icons.router),
              label: const Text('Ouvrir les routeurs'),
            ),
            if (savedRouters.isNotEmpty) ...[
              const SizedBox(height: 18),
              for (final router in savedRouters.take(4))
                Card(
                  child: ListTile(
                    leading: MikrotikRouterImage(
                      boardName: router.boardName,
                      size: 52,
                    ),
                    title: Text(router.name),
                    subtitle: Text(
                      router.boardName.isEmpty
                          ? router.host
                          : '${router.boardName} • ${router.host}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(AppRoutes.routers),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _error() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Icon(Icons.error_outline, size: 52),
      const SizedBox(height: 12),
      Text(
        'Impossible de charger le tableau de bord.\n$error',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _refreshAll,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    ],
  );

  Widget _dashboard() {
    final s = snapshot!;
    final totalMemory = _number(s.resource, 'total-memory');
    final freeMemory = _number(s.resource, 'free-memory');
    final ramUsed = _usedPercent(totalMemory, freeMemory);

    final totalStorage = _number(s.resource, 'total-hdd-space');
    final freeStorage = _number(s.resource, 'free-hdd-space');
    final storageUsed = _usedPercent(totalStorage, freeStorage);

    final cpu = _number(s.resource, 'cpu-load');

    return LayoutBuilder(
      builder: (context, box) {
        final padding = math.max(12.0, box.maxWidth * 0.025).toDouble();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          children: [
            _header(s),
            if (refreshing) const Text('Actualisation des sections en cours…'),
            if (dataService?.errors.isNotEmpty ?? false)
              Text(
                'Sections indisponibles ou anciennes : ${dataService!.errors.entries.map((e) => '${e.key} : ${e.value}').join(' ; ')}',
              ),
            if (error != null)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Actualisation interrompue. Les dernières données restent affichées. Appuyez sur Actualiser pour réessayer.',
                ),
              ),
            const SizedBox(height: 12),
            _responsiveWrap(box.maxWidth, [
              _metricCard(
                title: 'CPU',
                value: _sectionValue('resource', '${cpu.toStringAsFixed(0)} %'),
                icon: Icons.memory,
                color: _usageColor(cpu),
                percentage: cpu,
                onTap: () => _open(AppRoutes.system),
                gradientSlot: DashboardGradientSlot.cpu,
              ),
              _metricCard(
                title: 'RAM utilisée',
                value: _sectionValue(
                  'resource',
                  '${ramUsed.toStringAsFixed(0)} % • ${_bytes(totalMemory - freeMemory)}',
                ),
                icon: Icons.developer_board,
                color: _usageColor(ramUsed),
                percentage: ramUsed,
                subtitle:
                    '${_bytes(freeMemory)} libres / ${_bytes(totalMemory)}',
                onTap: () => _open(AppRoutes.system),
                gradientSlot: DashboardGradientSlot.memory,
              ),
              _metricCard(
                title: 'Stockage utilisé',
                value: _sectionValue(
                  'resource',
                  '${storageUsed.toStringAsFixed(0)} % • ${_bytes(totalStorage - freeStorage)}',
                ),
                icon: Icons.storage,
                color: _usageColor(storageUsed),
                percentage: storageUsed,
                subtitle:
                    '${_bytes(freeStorage)} libres / ${_bytes(totalStorage)}',
                onTap: () => _open(AppRoutes.system),
                gradientSlot: DashboardGradientSlot.storage,
              ),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Chiffre d’affaires', Icons.payments_outlined),
            const SizedBox(height: 8),
            _responsiveWrap(box.maxWidth, [
              _plainCard(
                'Aujourd’hui',
                _sectionValue('sales', _money(s.salesToday)),
                Icons.today,
                () => _open(AppRoutes.reports),
                DashboardGradientSlot.salesToday,
              ),
              _plainCard(
                'Cette semaine',
                _sectionValue('sales', _money(s.salesWeek)),
                Icons.date_range,
                () => _open(AppRoutes.reports),
                DashboardGradientSlot.salesWeek,
              ),
              _plainCard(
                'Ce mois',
                _sectionValue('sales', _money(s.salesMonth)),
                Icons.calendar_month,
                () => _open(AppRoutes.reports),
                DashboardGradientSlot.salesMonth,
              ),
              _plainCard(
                'CA total',
                _sectionValue('sales', _money(s.salesTotal)),
                Icons.account_balance_wallet_outlined,
                () => _open(AppRoutes.reports),
                DashboardGradientSlot.salesTotal,
              ),
            ]),
            const SizedBox(height: 18),
            _sectionTitle('Utilisateurs connectés', Icons.people_alt_outlined),
            const SizedBox(height: 8),
            _responsiveWrap(box.maxWidth, [
              _plainCard(
                'Hotspot actifs',
                _sectionValue('hotspot', '${s.hotspotActive.length}'),
                Icons.wifi,
                () => _open(AppRoutes.hotspot),
                DashboardGradientSlot.hotspot,
              ),
              _plainCard(
                'PPP actifs',
                _sectionValue('ppp', '${s.pppActive.length}'),
                Icons.vpn_key_outlined,
                () => _open(AppRoutes.ppp),
                DashboardGradientSlot.ppp,
              ),
            ]),
            const SizedBox(height: 18),
            if (dataService?.hasData('tickets') ?? false)
              _ticketSection(s)
            else
              Text('Tickets : ${_sectionValue('tickets', '')}'),
            const SizedBox(height: 18),
            _trafficSection(),
            const SizedBox(height: 18),
            if (dataService?.hasData('logs') ?? false)
              _logsSection(s)
            else
              Text('Journaux : ${_sectionValue('logs', '')}'),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  String _sectionValue(String section, String value) {
    final loader = dataService;
    if (loader == null || !loader.hasData(section)) {
      return loader?.pending.contains(section) == true
          ? 'Chargement…'
          : 'Indisponible';
    }
    return loader.errors.containsKey(section) ? '$value (ancien)' : value;
  }

  Widget _header(DashboardSnapshot s) {
    final clock = s.clock;
    final resource = s.resource;
    final board = s.routerboard;
    final activeRouter = RouterSession.instance.activeRouter;

    final headerGradient = _dashboardGradient(DashboardGradientSlot.router);
    final foreground = _gradientForeground(headerGradient);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      elevation: 4,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Container(
          decoration: BoxDecoration(gradient: headerGradient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 14,
              alignment: WrapAlignment.spaceBetween,
              children: [
                MikrotikRouterImage(
                  boardName: board['model'] ?? '',
                  alternativeModels: [
                    resource['board-name'] ?? '',
                    activeRouter?.boardName ?? '',
                  ],
                  size: 110,
                ),
                IconTheme(
                  data: IconThemeData(color: foreground),
                  child: _infoBlock('Routeur', [
                    s.identity['name'] ?? activeRouter?.name ?? 'MikroTik',
                    'IP : ${activeRouter?.host ?? '—'}',
                    'Board : ${resource['board-name'] ?? '—'}',
                    'Modèle : ${board['model'] ?? '—'}',
                    'RouterOS : ${resource['version'] ?? '—'}',
                    'Architecture : ${resource['architecture-name'] ?? '—'}',
                    'N° série : ${board['serial-number'] ?? '—'}',
                    'Firmware : ${board['current-firmware'] ?? '—'}',
                  ], Icons.router),
                ),
                IconTheme(
                  data: IconThemeData(color: foreground),
                  child: _infoBlock('Système', [
                    'Date : ${clock['date'] ?? '—'}',
                    'Heure : ${clock['time'] ?? '—'}',
                    'Fuseau : ${clock['time-zone-name'] ?? '—'}',
                    'Uptime : ${resource['uptime'] ?? '—'}',
                    'CPU : ${resource['cpu'] ?? '—'} '
                        '× ${resource['cpu-count'] ?? '—'}',
                    'Fréquence : ${resource['cpu-frequency'] ?? '—'} MHz',
                  ], Icons.schedule),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketSection(DashboardSnapshot s) {
    final entries = s.remainingTicketsByProfile.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tickets restants',
          Icons.confirmation_number_outlined,
          trailing: '${s.remainingTicketsTotal} au total',
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Aucun ticket disponible'),
              trailing: Icon(Icons.circle, color: _ticketColor(0), size: 14),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 13,
                      color: _ticketColor(entries[i].value),
                    ),
                    title: Text(entries[i].key),
                    subtitle: const Text(
                      'Utilisateurs Hotspot non encore consommés',
                    ),
                    trailing: Text(
                      '${entries[i].value}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    onTap: () => _open(AppRoutes.vouchers),
                  ),
                  if (i != entries.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _trafficSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Trafic temps réel',
          Icons.show_chart,
          trailing: trafficInterface.isEmpty
              ? 'Interface non définie'
              : trafficInterface,
        ),
        const SizedBox(height: 8),
        if (trafficError != null) Text(trafficError!),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _trafficValue(
                        'RX',
                        _bits(currentRx),
                        Icons.download,
                      ),
                    ),
                    Expanded(
                      child: _trafficValue(
                        'TX',
                        _bits(currentTx),
                        Icons.upload,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrafficPainter(
                      rx: List<double>.of(rxHistory),
                      tx: List<double>.of(txHistory),
                      rxColor: Theme.of(context).colorScheme.primary,
                      txColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Échantillon ${settings.trafficRefreshSeconds}s • '
                  'fenêtre ${settings.trafficWindowSeconds}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _logsSection(DashboardSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Logs récents',
          Icons.article_outlined,
          trailing: '${settings.logCount} max',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: const [
            _LogLegendDot(color: Colors.green, label: 'OK'),
            _LogLegendDot(color: Colors.orange, label: 'Avertissement'),
            _LogLegendDot(color: Colors.red, label: 'Erreur/Critique'),
            _LogLegendDot(color: Colors.blueGrey, label: 'Information'),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: s.logs.isEmpty
              ? const ListTile(title: Text('Aucun log récent'))
              : Column(
                  children: [
                    for (var i = 0; i < s.logs.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final row = s.logs[i];
                          final style = LogVisualStyle.fromRouterOs(row);
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: style.color, width: 4),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: style.color.withValues(
                                  alpha: 0.12,
                                ),
                                child: Icon(
                                  style.icon,
                                  color: style.color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                row['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(row['topics'] ?? ''),
                                  Text(
                                    style.label,
                                    style: TextStyle(
                                      color: style.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                row['time'] ?? '',
                                style: TextStyle(
                                  color: style.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => _open(AppRoutes.logs),
                            ),
                          );
                        },
                      ),
                      if (i != s.logs.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
        if (lastRefresh != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Dernière actualisation : '
                '${lastRefresh!.hour.toString().padLeft(2, '0')}:'
                '${lastRefresh!.minute.toString().padLeft(2, '0')}:'
                '${lastRefresh!.second.toString().padLeft(2, '0')}'
                '${settings.autoRefresh ? ' • Auto ${settings.refreshSeconds}s' : ' • Manuel'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, {String? trailing}) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _responsiveWrap(double width, List<Widget> children) {
    final available = width - 32;
    final columns = width >= 1200
        ? 4
        : width >= 750
        ? 3
        : width >= 480
        ? 2
        : 1;
    final cardWidth = math
        .max(220.0, (available - ((columns - 1) * 12)) / columns)
        .toDouble();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: math.min(cardWidth, available).toDouble(),
              child: child,
            ),
          )
          .toList(),
    );
  }

  LinearGradient _dashboardGradient(DashboardGradientSlot slot) {
    final extension = Theme.of(context).extension<CustomGradientsExtension>();
    return extension?.forSlot(slot) ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.mikrotikTurquoise, Color(0xFF155757)],
        );
  }

  Color _gradientForeground(LinearGradient gradient) {
    final colors = gradient.colors;
    final average = Color.fromARGB(
      255,
      colors.fold<int>(
            0,
            (sum, color) => sum + ((color.toARGB32() >> 16) & 0xFF),
          ) ~/
          colors.length,
      colors.fold<int>(
            0,
            (sum, color) => sum + ((color.toARGB32() >> 8) & 0xFF),
          ) ~/
          colors.length,
      colors.fold<int>(0, (sum, color) => sum + (color.toARGB32() & 0xFF)) ~/
          colors.length,
    );
    return ThemeData.estimateBrightnessForColor(average) == Brightness.dark
        ? Colors.white
        : AppTheme.mikrotikBlack;
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double percentage,
    String? subtitle,
    VoidCallback? onTap,
    required DashboardGradientSlot gradientSlot,
  }) {
    final gradient = _dashboardGradient(gradientSlot);
    final foreground = _gradientForeground(gradient);
    return Card(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: foreground),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (percentage / 100).clamp(0, 1).toDouble(),
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plainCard(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
    DashboardGradientSlot gradientSlot,
  ) {
    final gradient = _dashboardGradient(gradientSlot);
    final foreground = _gradientForeground(gradient);
    return Card(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: foreground.withValues(alpha: 0.16),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: foreground)),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String title, List<String> lines, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(line),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trafficValue(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  String _money(double value) => currency.trim().isEmpty
      ? value.toStringAsFixed(2)
      : '${value.toStringAsFixed(2)} $currency';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SalesSyncCoordinator.instance.stopPeriodic();
    RouterSession.instance.status.removeListener(_sessionChanged);
    refreshTimer?.cancel();
    trafficTimer?.cancel();
    super.dispose();
  }
}

class _LogLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LogLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 10, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _TrafficPainter extends CustomPainter {
  final List<double> rx;
  final List<double> tx;
  final Color rxColor;
  final Color txColor;

  const _TrafficPainter({
    required this.rx,
    required this.tx,
    required this.rxColor,
    required this.txColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxValue = [
      ...rx,
      ...tx,
      1.0,
    ].reduce((a, b) => math.max(a, b).toDouble());

    void drawLine(List<double> values, Color color) {
      if (values.length < 2) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = size.width * i / (values.length - 1);
        final y = size.height - (values[i] / maxValue * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(rx, rxColor);
    drawLine(tx, txColor);
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter old) =>
      old.rx != rx ||
      old.tx != tx ||
      old.rxColor != rxColor ||
      old.txColor != txColor;
}
