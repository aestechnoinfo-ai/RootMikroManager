class PppProfileDeleteGuard {
  const PppProfileDeleteGuard();
  String? reason({
    required String profileName,
    required List<Map<String, String>> secrets,
    required List<Map<String, String>> active,
  }) {
    final secretCount = secrets
        .where((e) => (e['profile'] ?? '') == profileName)
        .length;
    final activeCount = active
        .where((e) => (e['profile'] ?? '') == profileName)
        .length;
    if (secretCount > 0 || activeCount > 0) {
      return 'Profil utilisé par $secretCount secret(s) et $activeCount session(s) active(s). Réaffectez-les avant suppression.';
    }
    return null;
  }
}
