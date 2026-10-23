class UserModel {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String password; // Local-only simulated password (not hashed)
  final String role;
  final bool isActive;
  final String? avatarUrl;
  final String? residenceDepartment;
  final String? residenceProvince;
  final String? residenceCity;

  /// Versión de Términos y Privacidad que aceptó (null = aún no aceptó la versión vigente).
  final String? acceptedTermsVersion;

  UserModel({
    required this.id,
    required this.name,
    this.lastName = '',
    required this.email,
    this.password = '',
    this.role = 'user',
    this.isActive = true,
    this.avatarUrl,
    this.residenceDepartment,
    this.residenceProvince,
    this.residenceCity,
    this.acceptedTermsVersion,
  });

  /// Full display name.
  String get fullName =>
      lastName.isNotEmpty ? '$name $lastName' : name;

  /// Verifica si la residencia está completa.
  bool get hasCompleteResidence =>
      (residenceDepartment?.trim().isNotEmpty ?? false) &&
      (residenceProvince?.trim().isNotEmpty ?? false) &&
      (residenceCity?.trim().isNotEmpty ?? false);

  /// Construye un usuario desde el backend (GET /users/demo o /users/{id}).
  factory UserModel.fromApiJson(Map<String, dynamic> json) => UserModel(
        id: json['user_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'user',
        isActive: json['is_active'] ?? true,
        avatarUrl: json['avatar_url'],
        residenceDepartment: json['residence_department'],
        residenceProvince: json['residence_province'],
        residenceCity: json['residence_city'],
        acceptedTermsVersion: json['accepted_terms_version'],
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['user_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        password: '', // NO persistir password local
        role: json['role'] ?? 'user',
        isActive: json['is_active'] ?? true,
        avatarUrl: json['avatar_url'],
        residenceDepartment: json['residence_department'],
        residenceProvince: json['residence_province'],
        residenceCity: json['residence_city'],
        acceptedTermsVersion: json['accepted_terms_version'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': id,
        'name': name,
        'lastName': lastName,
        'email': email,
        'role': role,
        'is_active': isActive,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (residenceDepartment != null) 'residence_department': residenceDepartment,
        if (residenceProvince != null) 'residence_province': residenceProvince,
        if (residenceCity != null) 'residence_city': residenceCity,
        if (acceptedTermsVersion != null) 'accepted_terms_version': acceptedTermsVersion,
      };

  /// Serializa el usuario para enviarlo al backend (POST /users).
  Map<String, dynamic> toApiJson() => {
        'name': lastName.isNotEmpty ? '$name $lastName'.trim() : name,
        'email': email,
        'password': password,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (residenceDepartment != null) 'residence_department': residenceDepartment,
        if (residenceProvince != null) 'residence_province': residenceProvince,
        if (residenceCity != null) 'residence_city': residenceCity,
      };
}
