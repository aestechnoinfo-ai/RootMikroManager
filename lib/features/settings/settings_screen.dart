import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../dashboard/dashboard_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final defaultApiPort = TextEditingController(text: '8728');
  final scanTimeout = TextEditingController(text: '250');
  final trafficInterface = TextEditingController();

  bool autoRefresh = true;
  double refreshSeconds = 10;
  double trafficRefreshSeconds = 2;
  double trafficWindowSeconds = 60;
  double logCount = 5;
  double warningPercent = 70;
  double criticalPercent = 90;
  double ticketWarningCount = 20;
  double ticketCriticalCount = 5;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = AppDatabase.instance;
    final dashboard = await DashboardSettings.load();

    defaultApiPort.text = await db.getSetting('default_api_port') ?? '8728';
    scanTimeout.text = await db.getSetting('scan_timeout_ms') ?? '250';

    autoRefresh = dashboard.autoRefresh;
    refreshSeconds = dashboard.refreshSeconds.toDouble();
    trafficRefreshSeconds = dashboard.trafficRefreshSeconds.toDouble();
    trafficWindowSeconds = dashboard.trafficWindowSeconds.toDouble();
    logCount = dashboard.logCount.toDouble();
    warningPercent = dashboard.warningPercent.toDouble();
    criticalPercent = dashboard.criticalPercent.toDouble();
    ticketWarningCount = dashboard.ticketWarningCount.toDouble();
    ticketCriticalCount = dashboard.ticketCriticalCount.toDouble();
    trafficInterface.text = dashboard.trafficInterface;

    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final db = AppDatabase.instance;

    if (criticalPercent <= warningPercent) {
      criticalPercent = (warningPercent + 5).clamp(2, 99).toDouble();
    }
    if (ticketCriticalCount > ticketWarningCount) {
      ticketCriticalCount = ticketWarningCount;
    }

    await db.setSetting('default_api_port', defaultApiPort.text.trim());
    await db.setSetting('scan_timeout_ms', scanTimeout.text.trim());

    await DashboardSettings(
      autoRefresh: autoRefresh,
      refreshSeconds: refreshSeconds.round(),
      trafficRefreshSeconds: trafficRefreshSeconds.round(),
      trafficWindowSeconds: trafficWindowSeconds.round(),
      logCount: logCount.round(),
      warningPercent: warningPercent.round(),
      criticalPercent: criticalPercent.round(),
      ticketWarningCount: ticketWarningCount.round(),
      ticketCriticalCount: ticketCriticalCount.round(),
      trafficInterface: trafficInterface.text.trim(),
    ).save();

    await db.log('settings.updated');
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paramètres enregistrés.')));
  }

  Widget slider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String Function(double)? label,
  }) {
    final valueLabel = label?.call(value) ?? value.round().toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title : $valueLabel',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Connexion RouterOS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: defaultApiPort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port API par défaut',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scanTimeout,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Timeout scan réseau (ms)',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actualisation automatique'),
                subtitle: const Text(
                  'Actualise les indicateurs complets du tableau de bord.',
                ),
                value: autoRefresh,
                onChanged: (value) => setState(() => autoRefresh = value),
              ),
              slider(
                title: 'Actualisation générale',
                subtitle:
                    'Routeur, mémoire, stockage, ventes, sessions, tickets et logs.',
                value: refreshSeconds,
                min: 3,
                max: 300,
                divisions: 99,
                label: (v) => '${v.round()} s',
                onChanged: (v) => setState(() => refreshSeconds = v),
              ),
              slider(
                title: 'Actualisation du trafic',
                subtitle: 'Intervalle entre deux mesures RX/TX.',
                value: trafficRefreshSeconds,
                min: 1,
                max: 30,
                divisions: 29,
                label: (v) => '${v.round()} s',
                onChanged: (v) => setState(() => trafficRefreshSeconds = v),
              ),
              slider(
                title: 'Fenêtre du graphique trafic',
                subtitle: 'Durée de l’historique RX/TX visible à l’accueil.',
                value: trafficWindowSeconds,
                min: 10,
                max: 600,
                divisions: 59,
                label: (v) => '${v.round()} s',
                onChanged: (v) => setState(() => trafficWindowSeconds = v),
              ),
              TextField(
                controller: trafficInterface,
                decoration: const InputDecoration(
                  labelText: 'Interface trafic',
                  hintText:
                      'Vide = première interface active, sinon ether1, pppoe-out1…',
                ),
              ),
              const SizedBox(height: 12),
              slider(
                title: 'Aperçu des logs',
                subtitle: 'Nombre de lignes récentes affichées à l’accueil.',
                value: logCount,
                min: 1,
                max: 50,
                divisions: 49,
                label: (v) => '${v.round()} lignes',
                onChanged: (v) => setState(() => logCount = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Seuils couleur',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              slider(
                title: 'Orange à partir de',
                subtitle: 'RAM, stockage et autres jauges en pourcentage.',
                value: warningPercent,
                min: 30,
                max: 90,
                divisions: 60,
                label: (v) => '${v.round()} %',
                onChanged: (v) => setState(() {
                  warningPercent = v;
                  if (criticalPercent <= v) {
                    criticalPercent = (v + 5).clamp(35, 99).toDouble();
                  }
                }),
              ),
              slider(
                title: 'Rouge à partir de',
                subtitle: 'Seuil critique des jauges en pourcentage.',
                value: criticalPercent,
                min: 35,
                max: 99,
                divisions: 64,
                label: (v) => '${v.round()} %',
                onChanged: (v) => setState(
                  () => criticalPercent = v > warningPercent
                      ? v
                      : warningPercent + 1,
                ),
              ),
              slider(
                title: 'Tickets orange',
                subtitle: 'Stock restant faible par profil.',
                value: ticketWarningCount,
                min: 1,
                max: 500,
                divisions: 99,
                label: (v) => '${v.round()} tickets',
                onChanged: (v) => setState(() => ticketWarningCount = v),
              ),
              slider(
                title: 'Tickets rouge',
                subtitle: 'Stock restant critique par profil.',
                value: ticketCriticalCount,
                min: 0,
                max: 100,
                divisions: 100,
                label: (v) => '${v.round()} tickets',
                onChanged: (v) => setState(() => ticketCriticalCount = v),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    defaultApiPort.dispose();
    scanTimeout.dispose();
    trafficInterface.dispose();
    super.dispose();
  }
}
