import 'package:flutter/material.dart';

enum LogSeverity { success, info, warning, error, critical }

class LogVisualStyle {
  final LogSeverity severity;
  final Color color;
  final IconData icon;
  final String label;

  const LogVisualStyle({
    required this.severity,
    required this.color,
    required this.icon,
    required this.label,
  });

  static LogVisualStyle fromRouterOs(Map<String, String> row) {
    final topics = (row['topics'] ?? '').toLowerCase();
    final message = (row['message'] ?? '').toLowerCase();
    final text = '$topics $message';

    if (_has(text, ['critical', 'fatal', 'panic', 'emergency'])) {
      return const LogVisualStyle(
        severity: LogSeverity.critical,
        color: Colors.red,
        icon: Icons.dangerous_outlined,
        label: 'Critique',
      );
    }
    if (_has(text, [
      'error',
      'failed',
      'failure',
      'denied',
      'invalid',
      'timeout',
      'refused',
      'disconnected',
      'down',
      'lost',
    ])) {
      return const LogVisualStyle(
        severity: LogSeverity.error,
        color: Colors.red,
        icon: Icons.error_outline,
        label: 'Erreur',
      );
    }
    if (_has(text, [
      'warning',
      'warn',
      'retry',
      'unstable',
      'high',
      'low',
      'expired',
      'expire',
    ])) {
      return const LogVisualStyle(
        severity: LogSeverity.warning,
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
        label: 'Avertissement',
      );
    }
    if (_has(text, [
      'success',
      'successful',
      'connected',
      'logged in',
      'login',
      'started',
      'running',
      ' up ',
      'enabled',
      'added',
      'created',
    ])) {
      return LogVisualStyle(
        severity: LogSeverity.success,
        color: Colors.green,
        icon: _topicIcon(topics),
        label: 'OK',
      );
    }
    return LogVisualStyle(
      severity: LogSeverity.info,
      color: _topicColor(topics),
      icon: _topicIcon(topics),
      label: 'Info',
    );
  }

  static bool _has(String text, List<String> words) => words.any(text.contains);

  static IconData _topicIcon(String topics) {
    if (topics.contains('hotspot')) return Icons.wifi_outlined;
    if (topics.contains('ppp') || topics.contains('pppoe'))
      return Icons.vpn_key_outlined;
    if (topics.contains('firewall')) return Icons.shield_outlined;
    if (topics.contains('interface')) return Icons.cable_outlined;
    if (topics.contains('wireless') || topics.contains('wifi'))
      return Icons.wifi_tethering_outlined;
    if (topics.contains('dhcp')) return Icons.lan_outlined;
    if (topics.contains('system')) return Icons.memory_outlined;
    if (topics.contains('script') || topics.contains('scheduler'))
      return Icons.code_outlined;
    if (topics.contains('account')) return Icons.person_outline;
    if (topics.contains('route') || topics.contains('routing'))
      return Icons.alt_route_outlined;
    return Icons.article_outlined;
  }

  static Color _topicColor(String topics) {
    if (topics.contains('firewall')) return Colors.deepOrange;
    if (topics.contains('hotspot')) return Colors.green;
    if (topics.contains('ppp') || topics.contains('pppoe')) return Colors.blue;
    if (topics.contains('interface')) return Colors.teal;
    if (topics.contains('dhcp')) return Colors.cyan;
    if (topics.contains('wireless') || topics.contains('wifi'))
      return Colors.indigo;
    if (topics.contains('system')) return Colors.purple;
    if (topics.contains('script') || topics.contains('scheduler'))
      return Colors.blueGrey;
    if (topics.contains('account')) return Colors.brown;
    if (topics.contains('route') || topics.contains('routing'))
      return Colors.deepPurple;
    return Colors.blueGrey;
  }
}
