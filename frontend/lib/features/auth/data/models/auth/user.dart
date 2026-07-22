class User {
  final int idUsers;
  final String nama;
  final String email;
  final String? createdAt;
  // ponytail: role is inferred from room ownership - asesor = created rooms, pelajar = joined rooms
  // We store it locally from server response to avoid an extra API call
  final String role; // 'asesor' | 'pelajar'

  User({
    required this.idUsers,
    required this.nama,
    required this.email,
    this.createdAt,
    this.role = 'pelajar',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUsers: json['id_users'] ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'],
      role: json['role'] ?? 'pelajar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_users': idUsers,
      'nama': nama,
      'email': email,
      'created_at': createdAt,
      'role': role,
    };
  }

  User copyWith({
    int? idUsers,
    String? nama,
    String? email,
    String? createdAt,
    String? role,
  }) {
    return User(
      idUsers: idUsers ?? this.idUsers,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }

  bool get isAsesor => role == 'asesor';
}
