class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.role = 'pharmacist',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String? ?? 'pharmacist',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
