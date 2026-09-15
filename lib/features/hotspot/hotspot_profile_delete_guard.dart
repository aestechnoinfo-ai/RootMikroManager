class HotspotProfileDeleteGuard {
  const HotspotProfileDeleteGuard();

  String? reason({
    required String profileName,
    required List<Map<String, String>> users,
    required List<Map<String, String>> active,
  }) {
    if (profileName.trim().isEmpty) {
      return 'Profil Hotspot invalide.';
    }

    final tickets = users.where((e) => e['profile'] == profileName).length;
    final sessions = active.where((e) => e['profile'] == profileName).length;

    if (tickets > 0 || sessions > 0) {
      return 'Suppression bloquée : "$profileName" est encore utilisé par '
          '$tickets ticket(s) et $sessions session(s) active(s).';
    }
    return null;
  }
}
