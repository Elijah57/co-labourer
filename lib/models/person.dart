import '../../utils/birthday.dart';

class Person {
  final String id;
  final String firstname;
  final String? lastname;
  final String? othername;
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
    phoneno: m['phoneno'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    photoPath: m['photo_path'] as String?,
    birthday: m['birthday'] == null
        ? null
        : Birthday.fromText(m['birthday'] as String),
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
    String? phoneno,
    String? email,
    String? address,
    String? photoPath,
    bool clearPhoto = false,
    String? metAt,
    DateTime? followUpDate,
    bool? clearLastname,
    bool? clearOthername,
    bool? clearPhoneno,
    bool? clearEmail,
    bool? clearAddress,
    Birthday? birthday,
    String? partner,
    String? intro,
    DateTime? metOn,
  }) => Person(
    id: id,
    firstname: firstname ?? this.firstname,
    lastname: clearLastname == true ? null : (lastname ?? this.lastname),
    othername: clearOthername == true ? null : (othername ?? this.othername),
    phoneno: clearPhoneno == true ? null : (phoneno ?? this.phoneno),
    email: clearEmail == true ? null : (email ?? this.email),
    address: clearAddress == true ? null : (address ?? this.address),
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    metAt: metAt ?? this.metAt,
    followUpDate: followUpDate ?? this.followUpDate,
    birthday: birthday ?? this.birthday,
    partner: partner ?? this.partner,
    intro: intro ?? this.intro,
    metOn: metOn ?? this.metOn,
    createdAt: createdAt,
  );
}