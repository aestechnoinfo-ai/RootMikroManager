import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class LoggingActionEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const LoggingActionEditorScreen({super.key, required this.service, this.row});
  @override
  State<LoggingActionEditorScreen> createState() => _S();
}

class _S extends State<LoggingActionEditorScreen> {
  late final TextEditingController name,
      memoryLines,
      diskFile,
      diskLines,
      diskCount,
      remote,
      src,
      vrf,
      emailTo,
      emailCc;
  String target = 'memory',
      protocol = 'udp',
      format = 'default',
      severity = 'auto',
      facility = 'daemon',
      timeFormat = 'bsd-syslog';
  bool memoryStop = false,
      diskStop = false,
      cert = false,
      startTls = false,
      remember = false,
      saving = false;
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    memoryLines = TextEditingController(text: r?['memory-lines'] ?? '1000');
    diskFile = TextEditingController(text: r?['disk-file-name'] ?? 'log');
    diskLines = TextEditingController(text: r?['disk-lines-per-file'] ?? '100');
    diskCount = TextEditingController(text: r?['disk-file-count'] ?? '2');
    remote = TextEditingController(
      text: r?['remote-port'] ?? r?['remote'] ?? '0.0.0.0:514',
    );
    src = TextEditingController(text: r?['src-address'] ?? '0.0.0.0');
    vrf = TextEditingController(text: r?['vrf'] ?? 'main');
    emailTo = TextEditingController(text: r?['email-to'] ?? '');
    emailCc = TextEditingController(text: r?['email-cc'] ?? '');
    target = r?['target'] ?? 'memory';
    protocol = r?['remote-protocol'] ?? 'udp';
    format = r?['remote-log-format'] ?? 'default';
    severity = r?['syslog-severity'] ?? 'auto';
    facility = r?['syslog-facility'] ?? 'daemon';
    timeFormat = r?['syslog-time-format'] ?? 'bsd-syslog';
    memoryStop = r?['memory-stop-on-full'] == 'yes';
    diskStop = r?['disk-stop-on-full'] == 'yes';
    cert = r?['check-certificate'] == 'yes';
    startTls = r?['email-start-tls'] == 'yes';
    remember = r?['remember'] == 'yes';
  }

  bool valid(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v != null && v >= 1 && v <= 65535;
  }

  void note(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    if (target == 'memory' && !valid(memoryLines)) {
      note('Memory Lines : 1 à 65535.');
      return;
    }
    if (target == 'disk' && (!valid(diskLines) || !valid(diskCount))) {
      note('Valeurs disque : 1 à 65535.');
      return;
    }
    if (target == 'remote' &&
        (protocol == 'tcp' || protocol == 'tls') &&
        format != 'cef') {
      note('TCP/TLS nécessite le format CEF.');
      return;
    }
    setState(() => saving = true);
    final v = <String, String>{'name': name.text.trim(), 'target': target};
    if (target == 'memory')
      v.addAll({
        'memory-lines': memoryLines.text.trim(),
        'memory-stop-on-full': memoryStop ? 'yes' : 'no',
      });
    if (target == 'disk')
      v.addAll({
        'disk-file-name': diskFile.text.trim(),
        'disk-lines-per-file': diskLines.text.trim(),
        'disk-file-count': diskCount.text.trim(),
        'disk-stop-on-full': diskStop ? 'yes' : 'no',
      });
    if (target == 'remote')
      v.addAll({
        'remote-port': remote.text.trim(),
        'remote-protocol': protocol,
        'remote-log-format': format,
        'src-address': src.text.trim(),
        'vrf': vrf.text.trim().isEmpty ? 'main' : vrf.text.trim(),
        'syslog-severity': severity,
        'syslog-facility': facility,
        'syslog-time-format': timeFormat,
        'check-certificate': cert ? 'yes' : 'no',
      });
    if (target == 'email')
      v.addAll({
        'email-to': emailTo.text.trim(),
        'email-cc': emailCc.text.trim(),
        'email-start-tls': startTls ? 'yes' : 'no',
      });
    if (target == 'echo') v['remember'] = remember ? 'yes' : 'no';
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/system/logging/action', v);
      else
        await widget.service.set('/system/logging/action', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        note('$e');
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Ajouter action logging'
            : 'Modifier action logging',
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
        DropdownButtonFormField<String>(isExpanded: true, 
          value: target,
          decoration: const InputDecoration(labelText: 'Target'),
          items: const [
            'memory',
            'disk',
            'remote',
            'echo',
            'email',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => target = v ?? 'memory'),
        ),
        if (target == 'memory') ...[
          const SizedBox(height: 10),
          TextField(
            controller: memoryLines,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Memory Lines'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stop on full'),
            value: memoryStop,
            onChanged: (v) => setState(() => memoryStop = v),
          ),
        ],
        if (target == 'disk') ...[
          const SizedBox(height: 10),
          TextField(
            controller: diskFile,
            decoration: const InputDecoration(labelText: 'Disk File Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: diskLines,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Lines per file'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: diskCount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'File count'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stop on full'),
            value: diskStop,
            onChanged: (v) => setState(() => diskStop = v),
          ),
        ],
        if (target == 'remote') ...[
          const SizedBox(height: 10),
          TextField(
            controller: remote,
            decoration: const InputDecoration(
              labelText: 'Remote server',
              hintText: '192.168.1.10:514',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: protocol,
            decoration: const InputDecoration(labelText: 'Protocol'),
            items: const [
              'udp',
              'tcp',
              'tls',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => protocol = v ?? 'udp'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: format,
            decoration: const InputDecoration(labelText: 'Format'),
            items: const [
              'default',
              'syslog',
              'cef',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => format = v ?? 'default'),
          ),
          if ((protocol == 'tcp' || protocol == 'tls') && format != 'cef')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('TCP/TLS est pris en charge avec CEF.'),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: src,
            decoration: const InputDecoration(labelText: 'Source Address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: vrf,
            decoration: const InputDecoration(
              labelText: 'VRF',
              helperText: 'Logging distant : RouterOS 7.19+',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: severity,
            decoration: const InputDecoration(labelText: 'Syslog Severity'),
            items: const [
              'auto',
              'emergency',
              'alert',
              'critical',
              'error',
              'warning',
              'notice',
              'info',
              'debug',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => severity = v ?? 'auto'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: facility,
            decoration: const InputDecoration(labelText: 'Syslog Facility'),
            items: const [
              'auth',
              'authpriv',
              'cron',
              'daemon',
              'ftp',
              'kern',
              'local0',
              'local1',
              'local2',
              'local3',
              'local4',
              'local5',
              'local6',
              'local7',
              'lpr',
              'mail',
              'news',
              'ntp',
              'syslog',
              'user',
              'uucp',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => facility = v ?? 'daemon'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: timeFormat,
            decoration: const InputDecoration(labelText: 'Syslog Time Format'),
            items: const [
              'bsd-syslog',
              'iso8601',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => timeFormat = v ?? 'bsd-syslog'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Check certificate'),
            value: cert,
            onChanged: (v) => setState(() => cert = v),
          ),
        ],
        if (target == 'email') ...[
          const SizedBox(height: 10),
          TextField(
            controller: emailTo,
            decoration: const InputDecoration(labelText: 'Email To'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailCc,
            decoration: const InputDecoration(labelText: 'Email Cc'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('STARTTLS'),
            value: startTls,
            onChanged: (v) => setState(() => startTls = v),
          ),
        ],
        if (target == 'echo')
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remember'),
            value: remember,
            onChanged: (v) => setState(() => remember = v),
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
    for (final c in [
      name,
      memoryLines,
      diskFile,
      diskLines,
      diskCount,
      remote,
      src,
      vrf,
      emailTo,
      emailCc,
    ])
      c.dispose();
    super.dispose();
  }
}
