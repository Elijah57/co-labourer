import '../../utils/birthday.dart';

Birthday? _birthdayFrom(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  try {
    return Birthday.fromText(value);
  } on FormatException {
    return null;
  }
}

enum Sex {
  male('MALE', 'Male'),
  female('FEMALE', 'Female');

  const Sex(this.dbValue, this.label);

  /// Stored in the `sex` column. Do not change these strings.
  final String dbValue;
  final String label;

  /// Unknown or missing values load as null rather than crashing.
  static Sex? fromDb(Object? value) {
    if (value is! String) return null;
    final upper = value.trim().toUpperCase();
    for (final s in Sex.values) {
      if (s.dbValue == upper) return s;
    }
    return null;
  }
}

class Person {
  final String id;
  final String firstname;
  final String? lastname;
  final String? othername;
  final String? occupation;
  final Sex? sex;
  final String? phoneno;
  final String? email;
  final String? address;
  final String? photoPath;
  final Birthday? birthday;
  final String? partner;
  final String? intro;
  final DateTime? metOn;
  final String? metAt;
  final DateTime? followUpDate;
  final DateTime createdAt;

  Person({
    required this.id,
    required this.firstname,
    this.lastname,
    this.othername,
    this.occupation,
    this.sex,
    this.phoneno,
    this.email,
    this.address,
    this.photoPath,
    this.birthday,
    this.partner,
    this.intro,
    this.metOn,
    this.metAt,
    this.followUpDate,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    "id": id,
    "firstname": firstname,
    "lastname": lastname,
    "othername": othername,
    "occupation": occupation,
    "sex": sex?.dbValue,
    "phoneno": phoneno,
    "email": email,
    "address": address,
    "photo_path": photoPath,
    "birthday": birthday?.toDatabaseText(),
    "partner": partner,
    "intro": intro,
    "met_on": metOn?.toIso8601String(),
    "met_at": metAt,
    "follow_up_date": followUpDate?.toIso8601String(),
    "created_at": createdAt.toIso8601String(),
  };


  factory Person.fromMap(Map<String, Object?> m) => Person(
    id: m['id'] as String,
    firstname: m['firstname'] as String,
    lastname: m['lastname'] as String?,
    othername: m['othername'] as String?,
    occupation: m['occupation'] as String?,
    sex: Sex.fromDb(m['sex']),
    phoneno: m['phoneno'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    photoPath: m['photo_path'] as String?,
    birthday: _birthdayFrom(m['birthday']),
    partner: m['partner'] as String?,
    intro: m['intro'] as String?,
    metOn: m['met_on'] == null
        ? null
        : DateTime.parse(m['met_on'] as String),
    metAt: m['met_at'] as String?,
    followUpDate: m['follow_up_date'] == null
        ? null
        : DateTime.parse(m['follow_up_date'] as String),
    createdAt: DateTime.parse(m['created_at'] as String),
  );


  Person copyWith({
    String? firstname,
    String? lastname,
    String? othername,
    String? occupation,
    bool clearOccupation = false,
    Sex? sex,
    bool clearSex = false,
    String? phoneno,
    String? email,
    String? address,
    String? photoPath,
    bool clearPhoto = false,
    String? metAt,
    bool clearMetAt = false,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
    bool? clearLastname,
    bool? clearOthername,
    bool? clearPhoneno,
    bool? clearEmail,
    bool? clearAddress,
    Birthday? birthday,
    bool clearBirthday = false,
    String? partner,
    bool clearPartner = false,
    String? intro,
    bool clearIntro = false,
    DateTime? metOn,
    bool clearMetOn = false,
  }) => Person(
    id: id,
    firstname: firstname ?? this.firstname,
    lastname: clearLastname == true ? null : (lastname ?? this.lastname),
    othername: clearOthername == true ? null : (othername ?? this.othername),
    occupation: clearOccupation ? null : (occupation ?? this.occupation),
    sex: clearSex ? null : (sex ?? this.sex),
    phoneno: clearPhoneno == true ? null : (phoneno ?? this.phoneno),
    email: clearEmail == true ? null : (email ?? this.email),
    address: clearAddress == true ? null : (address ?? this.address),
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    metAt: clearMetAt ? null : (metAt ?? this.metAt),
    followUpDate:
        clearFollowUpDate ? null : (followUpDate ?? this.followUpDate),
    birthday: clearBirthday ? null : (birthday ?? this.birthday),
    partner: clearPartner ? null : (partner ?? this.partner),
    intro: clearIntro ? null : (intro ?? this.intro),
    metOn: clearMetOn ? null : (metOn ?? this.metOn),
    createdAt: createdAt,
  );
}