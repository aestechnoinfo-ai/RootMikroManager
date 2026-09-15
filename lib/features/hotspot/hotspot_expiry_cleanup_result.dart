class HotspotExpiryCleanupResult {
  final int usersMatched;
  final int usersRemoved;
  final int activeSessionsRemoved;
  final int cookiesRemoved;
  const HotspotExpiryCleanupResult({
    this.usersMatched = 0,
    this.usersRemoved = 0,
    this.activeSessionsRemoved = 0,
    this.cookiesRemoved = 0,
  });
  bool get changed =>
      usersRemoved > 0 || activeSessionsRemoved > 0 || cookiesRemoved > 0;
  String get summary =>
      '$usersMatched ticket(s) expiré(s) • $cookiesRemoved cookie(s) supprimé(s) • $activeSessionsRemoved session(s) déconnectée(s) • $usersRemoved ticket(s) supprimé(s)';
}
