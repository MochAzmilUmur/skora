class User {
  final int idUsers;
  final String nama;
  final String email;
  final String? createdAt;

  User({
    required this.idUsers,
    required this.nama,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUsers: json['id_users'] ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_users': idUsers,
      'nama': nama,
      'email': email,
      'created_at': createdAt,
    };
  }
}
