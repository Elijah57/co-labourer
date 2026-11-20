import 'package:co_labourer/models/person.dart';
import 'package:co_labourer/utils/birthday.dart';
import 'package:co_labourer/utils/person_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 1, 1);

  test('formats a full person like the requested template', () {
    final person = Person(
      id: 'p1',
      firstname: 'Favour',
      lastname: 'Okhioya',
      othername: 'Grace',
      phoneno: '8074816842',
      birthday: Birthday(day: 16, month: 'October', year: '2006'),
      sex: Sex.female,
      occupation: 'Student (Philosophy 200L)',
      address: 'Jagun, PPL',
      partner: 'S. Queen Ahmed',
      createdAt: created,
    );
    expect(
      formatPersonForShare(person, myName: 'Elijah'),
      'Full Name: Favour Okhioya\n'
      'Phone Number: 8074816842\n'
      'Date of Birth: 16th Oct 2006\n'
      'Sex: Female\n'
      'Occupation: Student (Philosophy 200L)\n'
      'Address: Jagun, PPL\n'
      'Invited By: B. Elijah & S. Queen Ahmed',
    );
  });

  test('missing fields keep their label with an empty value', () {
    final person = Person(id: 'p2', firstname: 'Ada', createdAt: created);
    expect(
      formatPersonForShare(person),
      'Full Name: Ada\n'
      'Phone Number: \n'
      'Date of Birth: \n'
      'Sex: \n'
      'Occupation: \n'
      'Address: \n'
      'Invited By: ',
    );
  });

  test('invited by falls back to whichever name exists', () {
    final withPartner = Person(
      id: 'p3', firstname: 'A', partner: 'Queen', createdAt: created);
    expect(formatPersonForShare(withPartner).split('\n').last,
        'Invited By: Queen');
    final noPartner = Person(id: 'p4', firstname: 'A', createdAt: created);
    expect(formatPersonForShare(noPartner, myName: 'Elijah').split('\n').last,
        'Invited By: B. Elijah');
  });

  test('B. title is added once', () {
    expect(withBrotherTitle('Elijah'), 'B. Elijah');
    expect(withBrotherTitle('  Elijah '), 'B. Elijah');
    expect(withBrotherTitle('B. Elijah'), 'B. Elijah');
    expect(withBrotherTitle('b.Elijah'), 'b.Elijah');
    expect(withBrotherTitle(''), '');
    expect(withBrotherTitle(null), '');
  });

  test('birthday ordinals and year-less birthdays', () {
    String fmt(int day, [String? year]) => formatShareBirthday(
        Birthday(day: day, month: 'March', year: year));
    expect(fmt(1, '1990'), '1st Mar 1990');
    expect(fmt(2), '2nd Mar');
    expect(fmt(3), '3rd Mar');
    expect(fmt(11), '11th Mar');
    expect(fmt(12), '12th Mar');
    expect(fmt(13), '13th Mar');
    expect(fmt(21), '21st Mar');
    expect(fmt(22), '22nd Mar');
    expect(fmt(31), '31st Mar');
  });
}
