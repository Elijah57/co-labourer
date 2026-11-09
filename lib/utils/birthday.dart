class Birthday {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _monthNumbers = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final int day;
  final String month;
  final String? year;

  Birthday({
    required this.day,
    required String month,
    String? year,
  })  : month = _normalizeMonth(month),
        year = year == null || year.trim().isEmpty ? null : year.trim();

  factory Birthday.fromText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw const FormatException('Empty birthday');

    final iso =
        RegExp(r'^(?:(\d{4})-|--)?(\d{1,2})-(\d{1,2})$').firstMatch(trimmed);
    if (iso != null) {
      final year = iso.group(1);
      final month = int.parse(iso.group(2)!);
      final day = int.parse(iso.group(3)!);
      _validate(day, month, year);
      return Birthday(day: day, month: monthName(month), year: year);
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) throw FormatException('Invalid birthday: $trimmed');

    final dayFirst = int.tryParse(parts[0].replaceAll(RegExp(r'\D'), ''));
    final monthFirst = monthNumber(parts[0]);

    int? day;
    int? month;
    String? year;

    if (dayFirst != null) {
      day = dayFirst;
      month = monthNumber(parts[1]);
      year = _yearFrom(parts.skip(2));
    } else if (monthFirst != null) {
      month = monthFirst;
      day = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), ''));
      year = _yearFrom(parts.skip(2));
    }

    if (day == null || month == null) {
      throw FormatException('Invalid birthday: $trimmed');
    }

    _validate(day, month, year);
    return Birthday(day: day, month: monthName(month), year: year);
  }

  static String monthName(int month) {
    if (month < 1 || month > 12) return _monthNames.first;
    return _monthNames[month - 1];
  }

  static int? monthNumber(String month) {
    return _monthNumbers[month.trim().toLowerCase()];
  }

  static String _normalizeMonth(String month) {
    final number = monthNumber(month);
    return number == null ? month.trim() : monthName(number);
  }

  static String? _yearFrom(Iterable<String> parts) {
    for (final part in parts) {
      final cleaned = part.replaceAll(RegExp(r'\D'), '');
      if (cleaned.length == 4) return cleaned;
    }
    return null;
  }

  static void _validate(int day, int month, String? year) {
    if (month < 1 || month > 12) {
      throw FormatException('Invalid month: $month');
    }
    final maxDay = DateTime(
      int.tryParse(year ?? '') ?? 2000,
      month + 1,
      0,
    ).day;
    if (day < 1 || day > maxDay) {
      throw FormatException('Invalid day: $day');
    }
  }

  String toDatabaseText() {
    final monthNumber = _monthToNum(month);
    final monthText = monthNumber.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    if (year != null) return '$year-$monthText-$dayText';
    return '--$monthText-$dayText';
  }

  String toDisplayString() {
    final dayText = day.toString().padLeft(2, '0');
    final monthAbbr = _monthAbbr(month);
    if (year != null) {
      return '$dayText $monthAbbr $year (age ${_calculateAge()})';
    }
    return '$dayText $monthAbbr';
  }

  int _calculateAge() {
    final birthYear = int.tryParse(year ?? '');
    if (birthYear == null) return 0;
    final birthDate = DateTime(birthYear, _monthToNum(month), day);
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static int _monthToNum(String month) {
    return monthNumber(month) ?? 1;
  }

  static String _monthAbbr(String month) {
    final number = monthNumber(month);
    if (number == null) return _monthAbbreviations.first;
    return _monthAbbreviations[number - 1];
  }

  String get displayFull => '$day $month${year != null ? ' $year' : ''}';

  @override
  String toString() => displayFull;
}
