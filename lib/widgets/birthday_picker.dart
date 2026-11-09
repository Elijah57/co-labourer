import 'package:flutter/material.dart';
import '../utils/birthday.dart';

Future<Birthday?> showBirthdayPicker(
  BuildContext context, {
  Birthday? initial,
}) {
  final initialMonth =
      initial == null ? 1 : Birthday.monthNumber(initial.month) ?? 1;
  final initialYear = (int.tryParse(initial?.year ?? '') ?? 2000)
      .clamp(1900, DateTime.now().year)
      .toInt();
  final initialDay = initial?.day ?? 1;
  var selectedDate = DateTime(initialYear, initialMonth, initialDay);
  var includeYear = initial?.year != null;

  return showDialog<Birthday>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Birthday'),
            content: SizedBox(
              width: 330,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 320,
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        onDateChanged: (date) {
                          setDialogState(() => selectedDate = date);
                        },
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include year'),
                      subtitle: const Text('Leave off if you do not know it'),
                      value: includeYear,
                      onChanged: (value) {
                        setDialogState(() => includeYear = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    Birthday(
                      day: selectedDate.day,
                      month: Birthday.monthName(selectedDate.month),
                      year: includeYear ? selectedDate.year.toString() : null,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
