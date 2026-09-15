class MikhmonBatchComment {
  const MikhmonBatchComment();

  /// Mikhmon 7.13.5 construit `vc|up-NNN-MM.dd.yy-commentaire` mais son
  /// catalogue reconnaît le lot à partir du préfixe et des trois chiffres.
  bool matches(String value) => RegExp(
    r'^(?:vc|up)-\d{3}(?:-|$)',
    caseSensitive: false,
  ).hasMatch(value.trim());
}
