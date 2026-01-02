class User {
  final String id;
  final String email;
  final String username;
  final String password; // hashed
  final String avatar;
  final String? fullName;
  final String? dateOfBirth;
  final String? phoneNumber;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    this.avatar = '',
    this.fullName,
    this.dateOfBirth,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      avatar: json['avatar'] as String? ?? '',
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'password': password,
    'avatar': avatar,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth,
    'phoneNumber': phoneNumber,
  };
}
