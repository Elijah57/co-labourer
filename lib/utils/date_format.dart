const _months = [
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

String formatDayMonth(DateTime date) {
  final month = _months[date.month - 1];
  if (date.year == DateTime.now().year) return '${date.day} $month';
  return '${date.day} $month ${date.year}';
}
