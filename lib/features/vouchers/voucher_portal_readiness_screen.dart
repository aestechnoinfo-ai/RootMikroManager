import 'package:flutter/material.dart';
import 'voucher_portal_url_validator.dart';
import 'voucher_template_settings.dart';

class VoucherPortalReadinessScreen extends StatefulWidget {
  const VoucherPortalReadinessScreen({super.key});

  @override
  State<VoucherPortalReadinessScreen> createState() => _State();
}

class _State extends State<VoucherPortalReadinessScreen> {
  bool loading = true;
  VoucherTemplateSettings settings = const VoucherTemplateSettings();
  List<String> issues = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    settings = await VoucherTemplateSettings.load();
    issues = const VoucherPortalUrlValidator().validate(settings.loginUrl);
    if (!settings.showQr) {
      issues = ['QR désactivé dans le template.'];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Portail captif & QR'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('URL de connexion'),
                  subtitle: SelectableText(
                    settings.loginUrl.trim().isEmpty
                        ? 'Non configurée'
                        : settings.loginUrl,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('QR dans le template'),
                  trailing: Text(settings.showQr ? 'Activé' : 'Désactivé'),
                ),
              ),
              if (issues.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Configuration QR cohérente.'),
                    subtitle: Text(
                      'La validation physique reste à faire sur le portail '
                      'captif réel du routeur.',
                    ),
                  ),
                ),
              for (final issue in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(issue),
                  ),
                ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'RootMikroManager valide ici la structure de l’URL. '
                    'Il ne suppose pas qu’une URL arbitraire correspond '
                    'réellement au portail du routeur connecté.',
                  ),
                ),
              ),
            ],
          ),
  );
}
