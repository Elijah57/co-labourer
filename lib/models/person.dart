class Person {
  final String id;
  final String firstname;
  final String? lastname;
  final String? othername;
  final String? phoneno;
  final String? email;
  final String? address;

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
    this.metAt,
    this.followUpDate,
    required this.createdAt,
  });

  Map<String, Object?> toMap ()=> {
    "id": id,
    "firstname": firstname,
    "lastname": lastname,
    "othername": othername,
    "phoneno": phoneno,
    "email": email,
    "address": address,
    "met_at": metAt,
    "created_at": createdAt.toIso8601String(),
    "follow_up_date": followUpDate?.toIso8601String(),
  };



  factory Person.fromMap(Map<String, Object?> m) => Person(
    id: m['id'] as String,
    firstname: m['firstname'] as String,
    lastname: m['lastname'] as String?,
    othername: m['othername'] as String?,
    phoneno: m['phoneno'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
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
    String? metAt,
    DateTime? followUpDate,
  }) =>
      Person(
        id: id,
        firstname: firstname ?? this.firstname,
        lastname: lastname ?? this.lastname,
        othername: othername ?? this.othername,
        phoneno: phoneno ?? this.phoneno,
        email: email ?? this.email,
        address: address ?? this.address,
        metAt: metAt ?? this.metAt,
        followUpDate: followUpDate ?? this.followUpDate,
        createdAt: createdAt,
      );
}