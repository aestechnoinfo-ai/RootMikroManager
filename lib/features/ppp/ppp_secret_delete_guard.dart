class PppSecretDeleteGuard {
  const PppSecretDeleteGuard();

  String? reason({
    required String secretName,
    required List<Map<String, String>> active,
  }) {
    if (secretName.trim().isEmpty) {
      return 'Impossible de supprimer un secret PPP sans nom.';
    }

    final sessions = active.where((row) {
      final user = row['name'] ?? row['user'] ?? '';
      return user == secretName;
    }).length;

    if (sessions > 0) {
      return 'Suppression bloquée : $sessions session(s) PPP active(s) '
          'utilisent encore "$secretName". Déconnectez-les d’abord.';
    }

    return null;
  }
}
