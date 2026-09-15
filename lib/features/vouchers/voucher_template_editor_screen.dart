import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

import 'voucher_print_layout.dart';
import 'voucher_paper_format.dart';
import 'voucher_print_screen.dart';
import 'voucher_template_settings.dart';

class VoucherTemplateEditorScreen extends StatefulWidget {
  const VoucherTemplateEditorScreen({super.key});

  @override
  State<VoucherTemplateEditorScreen> createState() =>
      _VoucherTemplateEditorScreenState();
}

class _VoucherTemplateEditorScreenState
    extends State<VoucherTemplateEditorScreen> {
  final hotspotName = TextEditingController();
  final title = TextEditingController();
  final currency = TextEditingController();
  final loginUrl = TextEditingController();
  final footerText = TextEditingController();

  bool showTitle = true;
  bool showHotspotName = true;
  bool showPassword = true;
  bool showProfile = true;
  bool showValidity = true;
  bool showTimeLimit = true;
  bool showDataLimit = true;
  bool showPrice = true;
  bool showLoginUrl = true;
  bool showQr = true;
  bool showNumber = true;
  bool showComment = false;

  int ticketsPerPage = 10;
  VoucherPaperFormat paperFormat = VoucherPaperFormat.printer;
  bool loading = true;
  bool saving = false;
  VoucherPrintLayout previewLayout = VoucherPrintLayout.standard;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final settings = await VoucherTemplateSettings.load();
    hotspotName.text = settings.hotspotName;
    title.text = settings.title;
    currency.text = settings.currency;
    loginUrl.text = settings.loginUrl;
    footerText.text = settings.footerText;
    ticketsPerPage = settings.safeTicketsPerPage;
    paperFormat = settings.paperFormat;
    showTitle = settings.showTitle;
    showHotspotName = settings.showHotspotName;
    showPassword = settings.showPassword;
    showProfile = settings.showProfile;
    showValidity = settings.showValidity;
    showTimeLimit = settings.showTimeLimit;
    showDataLimit = settings.showDataLimit;
    showPrice = settings.showPrice;
    showLoginUrl = settings.showLoginUrl;
    showQr = settings.showQr;
    showNumber = settings.showNumber;
    showComment = settings.showComment;
    if (mounted) setState(() => loading = false);
  }

  VoucherTemplateSettings get current => VoucherTemplateSettings(
    hotspotName: hotspotName.text.trim(),
    title: title.text.trim().isEmpty ? 'RootMikroManager' : title.text.trim(),
    currency: currency.text.trim(),
    loginUrl: loginUrl.text.trim(),
    footerText: footerText.text.trim(),
    ticketsPerPage: ticketsPerPage,
    paperFormat: paperFormat,
    showTitle: showTitle,
    showHotspotName: showHotspotName,
    showPassword: showPassword,
    showProfile: showProfile,
    showValidity: showValidity,
    showTimeLimit: showTimeLimit,
    showDataLimit: showDataLimit,
    showPrice: showPrice,
    showLoginUrl: showLoginUrl,
    showQr: showQr,
    showNumber: showNumber,
    showComment: showComment,
  );

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await current.save();
      _message('Modèle voucher enregistré.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> reset() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Réinitialiser le modèle ?'),
            content: const Text(
              'Les paramètres du voucher seront remis aux valeurs '
              'RootMikroManager par défaut.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await VoucherTemplateSettings.reset();
    await load();
    _message('Modèle réinitialisé.');
  }

  void preview() {
    AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: const [
          {
            'username': 'RMM-A7K926',
            'password': 'RMM-A7K926',
            'profile': '1H-2M',
            'validity': '1h',
            'selling-price': '500',
            'limit-uptime': '1h',
            'limit-bytes-total': '1073741824',
            'comment': 'Promo',
          },
        ],
        layout: previewLayout,
        templateSettings: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Éditeur voucher'),
      actions: [
        IconButton(
          tooltip: 'Aperçu',
          onPressed: loading ? null : preview,
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: 'Réinitialiser',
          onPressed: loading ? null : reset,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Text(
                'Mise en page',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<VoucherPrintLayout>(isExpanded: true, 
                value: previewLayout,
                decoration: const InputDecoration(labelText: 'Modèle'),
                items: const [
                  DropdownMenuItem(
                    value: VoucherPrintLayout.standard,
                    child: Text('Default'),
                  ),
                  DropdownMenuItem(
                    value: VoucherPrintLayout.qr,
                    child: Text('QR'),
                  ),
                  DropdownMenuItem(
                    value: VoucherPrintLayout.small,
                    child: Text('Small / Thermal'),
                  ),
                  DropdownMenuItem(
                    value: VoucherPrintLayout.mikhmonCode,
                    child: Text('Compact — code unique'),
                  ),
                  DropdownMenuItem(
                    value: VoucherPrintLayout.mikhmonCredentials,
                    child: Text('Compact — identifiant + mot de passe'),
                  ),
                ],
                onChanged: (v) => setState(
                  () => previewLayout = v ?? VoucherPrintLayout.standard,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<VoucherPaperFormat>(isExpanded: true, 
                value: paperFormat,
                decoration: const InputDecoration(labelText: 'Format papier'),
                items: VoucherPaperFormat.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(
                  () => paperFormat = v ?? VoucherPaperFormat.printer,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tickets par page',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '$ticketsPerPage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              Slider(
                min: 1,
                max: 50,
                divisions: 49,
                value: ticketsPerPage.toDouble(),
                label: '$ticketsPerPage',
                onChanged: (v) => setState(
                  () => ticketsPerPage = v.round().clamp(1, 50).toInt(),
                ),
              ),
              const Text(
                'Le code voucher reste toujours affiché et est '
                'volontairement plus grand que toutes les autres '
                'informations.',
              ),
              const SizedBox(height: 18),
              Text('Identité', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hotspotName,
                decoration: const InputDecoration(labelText: 'Nom du Hotspot'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: footerText,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Texte de pied de ticket',
                  hintText: 'Exemple : Par AESOLTEC AFRIQUE',
                  helperText: 'Dynamique et utilisé par les modèles compacts.',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: currency,
                decoration: const InputDecoration(
                  labelText: 'Devise',
                  hintText: 'Exemple : FCFA',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: loginUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL de connexion pour QR',
                  hintText: 'Exemple : http://10.10.10.1/login',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Informations à afficher',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text('Code voucher'),
                subtitle: Text('Toujours activé — information principale.'),
                trailing: Icon(Icons.check_circle_outline),
              ),
              _switch('Titre', showTitle, (v) => setState(() => showTitle = v)),
              _switch(
                'Nom du Hotspot',
                showHotspotName,
                (v) => setState(() => showHotspotName = v),
              ),
              _switch(
                'Mot de passe',
                showPassword,
                (v) => setState(() => showPassword = v),
              ),
              _switch(
                'Profil',
                showProfile,
                (v) => setState(() => showProfile = v),
              ),
              _switch(
                'Validité',
                showValidity,
                (v) => setState(() => showValidity = v),
              ),
              _switch(
                'Limite de temps',
                showTimeLimit,
                (v) => setState(() => showTimeLimit = v),
              ),
              _switch(
                'Limite de données',
                showDataLimit,
                (v) => setState(() => showDataLimit = v),
              ),
              _switch('Prix', showPrice, (v) => setState(() => showPrice = v)),
              _switch(
                'URL Login',
                showLoginUrl,
                (v) => setState(() => showLoginUrl = v),
              ),
              _switch('QR Code', showQr, (v) => setState(() => showQr = v)),
              _switch(
                'Numéro du ticket',
                showNumber,
                (v) => setState(() => showNumber = v),
              ),
              _switch(
                'Commentaire',
                showComment,
                (v) => setState(() => showComment = v),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: preview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Prévisualiser'),
              ),
            ],
          ),
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    hotspotName.dispose();
    title.dispose();
    currency.dispose();
    loginUrl.dispose();
    footerText.dispose();
    super.dispose();
  }
}
