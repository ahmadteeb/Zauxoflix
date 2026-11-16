class BackendUser {
  const BackendUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    phone: json['phone'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
  };
}

class LoginResult {
  const LoginResult({required this.user});
  final BackendUser user;
}
