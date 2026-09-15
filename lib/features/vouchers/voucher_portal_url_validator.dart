class VoucherPortalUrlValidator {
  const VoucherPortalUrlValidator();

  List<String> validate(String raw) {
    final issues = <String>[];
    final value = raw.trim();
    if (value.isEmpty) {
      issues.add('URL du portail absente.');
      return issues;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      issues.add('URL du portail invalide.');
      return issues;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      issues.add('Le portail doit utiliser http ou https.');
    }
    if (uri.userInfo.isNotEmpty) {
      issues.add('Ne placez pas d’identifiants dans l’URL du portail.');
    }
    return issues;
  }

  String buildQrPayload({
    required String loginUrl,
    required String username,
    required String password,
  }) {
    final uri = Uri.parse(loginUrl.trim());
    final params = Map<String, String>.from(uri.queryParameters)
      ..['username'] = username
      ..['password'] = password;
    return uri.replace(queryParameters: params).toString();
  }
}
