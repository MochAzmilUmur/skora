class User {
  final int idUsers;
  final String nama;
  final String email;
  final String? createdAt;
  final String role; // 'asesor' | 'pelajar'
  final String? avatarUrl;

  User({
    required this.idUsers,
    required this.nama,
    required this.email,
    this.createdAt,
    this.role = 'pelajar',
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUsers: json['id_users'] ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'],
      role: json['role'] ?? 'pelajar',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_users': idUsers,
      'nama': nama,
      'email': email,
      'created_at': createdAt,
      'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  User copyWith({
    int? idUsers,
    String? nama,
    String? email,
    String? createdAt,
    String? role,
    String? avatarUrl,
  }) {
    return User(
      idUsers: idUsers ?? this.idUsers,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  bool get isAsesor => role == 'asesor';
}
