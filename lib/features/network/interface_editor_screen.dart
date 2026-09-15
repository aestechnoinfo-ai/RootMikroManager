import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'network_input_validator.dart';

class InterfaceEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> row;

  const InterfaceEditorScreen({
    super.key,
    required this.service,
    required this.row,
  });

  @override
  State<InterfaceEditorScreen> createState() => _InterfaceEditorScreenState();
}

class _InterfaceEditorScreenState extends State<InterfaceEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController mtu;
  late final TextEditingController comment;
  bool enabled = true;
  bool saving = false;

  bool get dynamic =>
      widget.row['dynamic'] == 'yes' || widget.row['dynamic'] == 'true';

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.row['name'] ?? '');
    mtu = TextEditingController(text: widget.row['mtu'] ?? '');
    comment = TextEditingController(text: widget.row['comment'] ?? '');
    enabled =
        widget.row['disabled'] != 'yes' && widget.row['disabled'] != 'true';
  }

  Future<void> save() async {
    final id = widget.row['.id'];
    if (id == null ||
        dynamic ||
        saving ||
        !(formKey.currentState?.validate() ?? false))
      return;

    setState(() => saving = true);
    try {
      final values = <String, String>{
        'name': name.text.trim(),
        if (mtu.text.trim().isNotEmpty) 'mtu': mtu.text.trim(),
        'comment': comment.text.trim(),
        'disabled': enabled ? 'no' : 'yes',
      };
      await widget.service.set('/interface', id, values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Modifier interface')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (dynamic)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Interface dynamique : modification directe désactivée. Modifiez le service qui la crée.',
                ),
              ),
            ),
          TextFormField(
            controller: name,
            enabled: !dynamic,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: NetworkInputValidator.interfaceName,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: mtu,
            enabled: !dynamic,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'MTU'),
            validator: (v) => NetworkInputValidator.integerRange(
              v,
              label: 'MTU',
              min: 68,
              max: 65535,
              allowEmpty: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            enabled: !dynamic,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activée'),
            value: enabled,
            onChanged: dynamic ? null : (v) => setState(() => enabled = v),
          ),
          FilledButton.icon(
            onPressed: dynamic || saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    name.dispose();
    mtu.dispose();
    comment.dispose();
    super.dispose();
  }
}
