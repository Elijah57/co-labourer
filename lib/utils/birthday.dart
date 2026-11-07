class Birthday {
  final int day;
  final String month;
  final String? year;

  Birthday({
    required this.day,
    required this.month,
    this.year,
  });

  factory Birthday.fromText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw FormatException('Empty birthday');

    final parts = trimmed.split(' ');
    if (parts.length < 2) throw FormatException('Invalid birthday: $trimmed');

    final dayStr = parts[0];
    final dayNum = int.tryParse(dayStr.replaceAll(RegExp(r'[^\d]'), ''));
    if (dayNum == null || dayNum < 1 || dayNum > 31) {
      throw FormatException('Invalid day: $dayStr');
    }

    final monthRaw = parts.sublist(1).join(' ');
    final monthNorm = _normalizeMonth(monthRaw);

    return Birthday(day: dayNum, month: monthNorm, year: null);
  }

  String toDatabaseText() {
    if (year != null && year!.isNotEmpty) {
      final m = _monthToNum(month);
      return '$year-${m.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }
    final m = _monthToNum(month);
    return '--${m.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String toDisplayString() {
    final dayText = day.toString().padLeft(2, '0');
    final monthAbbr = _monthAbbr(month);
    if (year != null && year!.isNotEmpty) {
      final age = _calculateAge();
      return '$dayText $monthAbbr $year (age $age)';
    }
    return '$dayText $monthAbbr';
  }

  int _calculateAge() {
    if (year == null || year!.isEmpty) return 0;
    final birthDate = DateTime(int.parse(year!), _monthToNum(month), day);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String _normalizeMonth(String month) {
    final lowered = month.toLowerCase();
    final map = {
      'jan': 'January', 'february': 'February', 'mar': 'March',
      'april': 'April', 'may': 'May', 'june': 'June',
      'july': 'July', 'august': 'August', 'september': 'September',
      'october': 'October', 'november': 'November', 'december': 'December',
    };
    return map[lowered] ?? month;
  }

  static int _monthToNum(String month) {
    final m = _normalizeMonth(month);
    final nums = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
    return nums[m]!;
  }

  static String _monthAbbr(String month) {
    final m = _normalizeMonth(month);
    final map = {
      'January': 'Jan', 'February': 'Feb', 'March': 'Mar', 'April': 'Apr',
      'May': 'May', 'June': 'Jun', 'July': 'Jul', 'August': 'Aug',
      'September': 'Sep', 'October': 'Oct', 'November': 'Nov', 'December': 'Dec',
    };
    return map[m]!;
  }

  String get displayFull =>
      '$day $month${year != null && year!.isNotEmpty ? ' $year' : ''}';

  @override
  String toString() {
    if (year != null && year!.isNotEmpty) {
      return '$day $month $year';
    }
    return '$day $month';
  }
}