import 'package:flutter/material.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class DnsStaticEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const DnsStaticEditorScreen({super.key, required this.service, this.row});

  @override
  State<DnsStaticEditorScreen> createState() => _DnsStaticEditorScreenState();
}

class _DnsStaticEditorScreenState extends State<DnsStaticEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController address;
  late final TextEditingController ttl;
  late final TextEditingController regexp;
  late final TextEditingController forwardTo;
  late final TextEditingController cname;
  late final TextEditingController mxExchange;
  late final TextEditingController ns;
  late final TextEditingController textRecord;
  late final TextEditingController srvTarget;
  late final TextEditingController srvPort;
  late final TextEditingController mxPreference;
  late final TextEditingController comment;
  String type = 'A';
  bool matchSubdomain = false;
  bool enabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    address = TextEditingController(text: r?['address'] ?? '');
    ttl = TextEditingController(text: r?['ttl'] ?? '1d');
    regexp = TextEditingController(text: r?['regexp'] ?? '');
    forwardTo = TextEditingController(text: r?['forward-to'] ?? '');
    cname = TextEditingController(text: r?['cname'] ?? '');
    mxExchange = TextEditingController(text: r?['mx-exchange'] ?? '');
    ns = TextEditingController(text: r?['ns'] ?? '');
    textRecord = TextEditingController(text: r?['text'] ?? '');
    srvTarget = TextEditingController(text: r?['srv-target'] ?? '');
    srvPort = TextEditingController(text: r?['srv-port'] ?? '0');
    mxPreference = TextEditingController(text: r?['mx-preference'] ?? '0');
    comment = TextEditingController(text: r?['comment'] ?? '');
    type = r?['type'] ?? 'A';
    matchSubdomain =
        r?['match-subdomain'] == 'yes' || r?['match-subdomain'] == 'true';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
  }

  Future<void> save() async {
    if (saving) return;
    if (name.text.trim().isEmpty && regexp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom DNS ou Regexp obligatoire.')),
      );
      return;
    }
    String? error;
    if (name.text.trim().isNotEmpty) {
      error = NetworkInputValidator.dnsName(name.text);
    }
    if (error == null && type == 'A') {
      error = NetworkInputValidator.ipv4(address.text, label: 'Adresse A');
    }
    if (error == null && type == 'AAAA') {
      error = NetworkInputValidator.ipv6(address.text, label: 'Adresse AAAA');
    }
    if (error == null && type == 'FWD') {
      error = NetworkInputValidator.dnsForwardTarget(forwardTo.text);
    }
    if (error == null && type == 'CNAME') {
      error = NetworkInputValidator.dnsName(cname.text, label: 'CNAME');
    }
    if (error == null && type == 'MX') {
      error =
          NetworkInputValidator.dnsName(
            mxExchange.text,
            label: 'MX Exchange',
          ) ??
          NetworkInputValidator.integerRange(
            mxPreference.text,
            label: 'MX Preference',
            min: 0,
            max: 65535,
          );
    }
    if (error == null && type == 'NS') {
      error = NetworkInputValidator.dnsName(ns.text, label: 'NS');
    }
    if (error == null && type == 'SRV') {
      error =
          NetworkInputValidator.dnsName(srvTarget.text, label: 'SRV Target') ??
          NetworkInputValidator.integerRange(
            srvPort.text,
            label: 'SRV Port',
            min: 0,
            max: 65535,
          );
    }
    if (error == null && type == 'TXT' && textRecord.text.trim().isEmpty) {
      error = 'Texte TXT obligatoire.';
    }
    if (error == null) {
      error = NetworkInputValidator.routerOsDuration(
        ttl.text,
        label: 'TTL',
        allowEmpty: true,
      );
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => saving = true);

    final values = <String, String>{
      if (name.text.trim().isNotEmpty) 'name': name.text.trim(),
      'type': type,
      if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
      if (ttl.text.trim().isNotEmpty) 'ttl': ttl.text.trim(),
      if (regexp.text.trim().isNotEmpty) 'regexp': regexp.text.trim(),
      if (type == 'FWD' && forwardTo.text.trim().isNotEmpty)
        'forward-to': forwardTo.text.trim(),
      if (type == 'CNAME' && cname.text.trim().isNotEmpty)
        'cname': cname.text.trim(),
      if (type == 'MX' && mxExchange.text.trim().isNotEmpty)
        'mx-exchange': mxExchange.text.trim(),
      if (type == 'MX') 'mx-preference': mxPreference.text.trim(),
      if (type == 'NS' && ns.text.trim().isNotEmpty) 'ns': ns.text.trim(),
      if (type == 'TXT' && textRecord.text.trim().isNotEmpty)
        'text': textRecord.text.trim(),
      if (type == 'SRV' && srvTarget.text.trim().isNotEmpty)
        'srv-target': srvTarget.text.trim(),
      if (type == 'SRV') 'srv-port': srvPort.text.trim(),
      'match-subdomain': matchSubdomain ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/dns/static', values);
      } else {
        await widget.service.set('/ip/dns/static', id, values);
      }
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
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter DNS statique' : 'Modifier DNS statique',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const [
            'A',
            'AAAA',
            'CNAME',
            'FWD',
            'MX',
            'NS',
            'NXDOMAIN',
            'SRV',
            'TXT',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => type = v ?? 'A'),
        ),
        const SizedBox(height: 10),
        if (type == 'A' || type == 'AAAA') ...[
          TextField(
            controller: address,
            decoration: InputDecoration(
              labelText: type == 'A' ? 'Adresse IPv4' : 'Adresse IPv6',
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (type == 'CNAME') ...[
          TextField(
            controller: cname,
            decoration: const InputDecoration(labelText: 'CNAME'),
          ),
          const SizedBox(height: 10),
        ],
        if (type == 'MX') ...[
          TextField(
            controller: mxExchange,
            decoration: const InputDecoration(labelText: 'MX Exchange'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: mxPreference,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'MX Preference'),
          ),
          const SizedBox(height: 10),
        ],
        if (type == 'NS') ...[
          TextField(
            controller: ns,
            decoration: const InputDecoration(labelText: 'Name Server'),
          ),
          const SizedBox(height: 10),
        ],
        if (type == 'SRV') ...[
          TextField(
            controller: srvTarget,
            decoration: const InputDecoration(labelText: 'SRV Target'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: srvPort,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'SRV Port'),
          ),
          const SizedBox(height: 10),
        ],
        if (type == 'TXT') ...[
          TextField(
            controller: textRecord,
            decoration: const InputDecoration(labelText: 'Texte TXT'),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: ttl,
          decoration: const InputDecoration(labelText: 'TTL'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: regexp,
          decoration: const InputDecoration(labelText: 'Regexp'),
        ),
        const SizedBox(height: 10),
        if (type == 'FWD')
          TextField(
            controller: forwardTo,
            decoration: const InputDecoration(
              labelText: 'Forward To',
              hintText: '1.1.1.1 ou forwarder',
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Match Subdomain'),
          value: matchSubdomain,
          onChanged: (v) => setState(() => matchSubdomain = v),
        ),
        TextField(
          controller: comment,
          decoration: const InputDecoration(labelText: 'Commentaire'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activée'),
          value: enabled,
          onChanged: (v) => setState(() => enabled = v),
        ),
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    ttl.dispose();
    regexp.dispose();
    forwardTo.dispose();
    cname.dispose();
    mxExchange.dispose();
    ns.dispose();
    textRecord.dispose();
    srvTarget.dispose();
    srvPort.dispose();
    mxPreference.dispose();
    comment.dispose();
    super.dispose();
  }
}
