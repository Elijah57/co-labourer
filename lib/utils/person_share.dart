import '../models/person.dart';
import 'birthday.dart';

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _clean(String? value) => value?.trim() ?? '';

String _joinNonEmpty(Iterable<String?> parts, String separator) =>
    parts.map(_clean).where((p) => p.isNotEmpty).join(separator);

String _ordinal(int day) {
  if (day % 100 >= 11 && day % 100 <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

/// "16th Oct 2006", or "16th Oct" when the year was left out.
String formatShareBirthday(Birthday? birthday) {
  if (birthday == null) return '';
  final month = Birthday.monthNumber(birthday.month);
  final monthText = month == null ? birthday.month : _monthAbbr[month - 1];
  return _joinNonEmpty([_ordinal(birthday.day), monthText, birthday.year], ' ');
}

String shareFullName(Person person) =>
    _joinNonEmpty([person.firstname, person.lastname], ' ');

/// The Me profile name with the "B." (Brother) title, e.g. "B. Elijah".
/// Not added twice if the stored name already starts with it.
String withBrotherTitle(String? name) {
  final cleaned = _clean(name);
  if (cleaned.isEmpty) return '';
  if (RegExp(r'^b\.\s*', caseSensitive: false).hasMatch(cleaned)) {
    return cleaned;
  }
  return 'B. $cleaned';
}

/// Plain-text card for sharing a person. Missing fields keep their label
/// with an empty value. "Invited By" is "B." plus the Me profile name, then the
/// person's partner, joined by " & ".
String formatPersonForShare(Person person, {String? myName}) {
  final invitedBy =
      _joinNonEmpty([withBrotherTitle(myName), person.partner], ' & ');
  return [
    'Full Name: ${shareFullName(person)}',
    'Phone Number: ${_clean(person.phoneno)}',
    'Date of Birth: ${formatShareBirthday(person.birthday)}',
    'Sex: ${person.sex?.label ?? ''}',
    'Occupation: ${_clean(person.occupation)}',
    'Address: ${_clean(person.address)}',
    'Invited By: $invitedBy',
  ].join('\n');
}
