import 'package:flutter/material.dart';
import 'voucher_template_settings.dart';
import 'voucher_print_density_policy.dart';
import 'voucher_paper_format.dart';

class VoucherPrintReadinessScreen extends StatefulWidget {
  const VoucherPrintReadinessScreen({super.key});
  @override
  State<VoucherPrintReadinessScreen> createState() => _S();
}

class _S extends State<VoucherPrintReadinessScreen> {
  bool loading = true;
  late VoucherTemplateSettings settings;
  List<String> issues = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    settings = await VoucherTemplateSettings.load();
    issues = [];
    if (settings.showPrice && settings.currency.trim().isEmpty)
      issues.add('Prix activé mais devise non configurée.');
    if (settings.showQr && settings.loginUrl.trim().isEmpty)
      issues.add(
        'QR activé sans URL Login : le QR contiendra un payload RootMikroManager interne, pas une URL captive directe.',
      );
    if (settings.safeTicketsPerPage >= 40 && settings.showQr)
      issues.add(
        '40–50 tickets/page avec QR : la lisibilité peut devenir insuffisante sur papier.',
      );
    if ((settings.paperFormat == VoucherPaperFormat.thermal58 ||
            settings.paperFormat == VoucherPaperFormat.thermal80) &&
        settings.safeTicketsPerPage > 2)
      issues.add(
        'Format thermique sélectionné avec plus de 2 tickets/page : réduisez la densité pour une impression physique lisible.',
      );
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Audit impression vouchers'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Format papier'),
                  trailing: Text(settings.paperFormat.label),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Tickets par page'),
                  trailing: Text('${settings.safeTicketsPerPage}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('QR'),
                  trailing: Text(settings.showQr ? 'activé' : 'désactivé'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Devise'),
                  trailing: Text(
                    settings.currency.isEmpty
                        ? 'non configurée'
                        : settings.currency,
                  ),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Configuration d’impression cohérente.'),
                  ),
                ),
              for (final x in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(x),
                  ),
                ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cet audit vérifie la configuration logicielle. La lisibilité réelle dépend encore du modèle d’imprimante, du papier et de la résolution physique.',
                  ),
                ),
              ),
            ],
          ),
  );
}
