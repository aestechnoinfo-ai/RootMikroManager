class PppDuplicateSecretGuard {
  const PppDuplicateSecretGuard();
  bool exists(
    String name,
    List<Map<String, String>> secrets, {
    String? exceptId,
  }) {
    final n = name.trim().toLowerCase();
    return secrets.any(
      (e) =>
          (e['.id'] != exceptId) &&
          ((e['name'] ?? '').trim().toLowerCase() == n),
    );
  }
}
