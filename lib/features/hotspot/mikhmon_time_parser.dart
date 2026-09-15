class MikhmonTimeParser {
  const MikhmonTimeParser._();

  /// Converts human input to a RouterOS interval.
  ///
  /// Textual months use the conventional Mikhmon duration of 30 days because
  /// RouterOS schedulers have no calendar-month interval. A bare `m` remains
  /// minutes, as required by RouterOS; use `mois` or `month` for months.
  static String normalize(String input) {
    var value = _foldAccents(
      input.toLowerCase(),
    ).replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) throw const FormatException('Durée vide');
    if (RegExp(r'^\d+$').hasMatch(value)) value = '${value}h';

    final token = RegExp(
      r'(\d+)(months?|mois|semaines?|weeks?|journees?|jours?|days?|heures?|hours?|hrs?|minutes?|mins?|secondes?|seconds?|secs?|[wdhms])',
      caseSensitive: false,
    );
    var cursor = 0;
    var seconds = 0;
    for (final match in token.allMatches(value)) {
      if (match.start != cursor) {
        throw FormatException('Durée invalide: $input');
      }
      cursor = match.end;
      final amount = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      seconds +=
          amount *
          switch (unit) {
            'month' || 'months' || 'mois' => 30 * 24 * 60 * 60,
            'w' ||
            'week' ||
            'weeks' ||
            'semaine' ||
            'semaines' => 7 * 24 * 60 * 60,
            'd' ||
            'day' ||
            'days' ||
            'jour' ||
            'jours' ||
            'journee' ||
            'journees' => 24 * 60 * 60,
            'h' ||
            'hour' ||
            'hours' ||
            'heure' ||
            'heures' ||
            'hr' ||
            'hrs' => 60 * 60,
            'm' || 'min' || 'mins' || 'minute' || 'minutes' => 60,
            's' ||
            'sec' ||
            'secs' ||
            'seconde' ||
            'secondes' ||
            'second' ||
            'seconds' => 1,
            _ => throw FormatException('Unité invalide: $unit'),
          };
    }
    if (cursor != value.length || seconds <= 0) {
      throw FormatException('Durée invalide: $input');
    }

    final out = StringBuffer();
    void take(String suffix, int unitSeconds) {
      final amount = seconds ~/ unitSeconds;
      if (amount > 0) out.write('$amount$suffix');
      seconds %= unitSeconds;
    }

    take('w', 7 * 24 * 60 * 60);
    take('d', 24 * 60 * 60);
    take('h', 60 * 60);
    take('m', 60);
    take('s', 1);
    return out.toString();
  }

  static String _foldAccents(String value) => value
      .replaceAll(RegExp('[àáâäãå]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôöõ]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ç', 'c');
}
