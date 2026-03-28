import 'package:frontend/features/auth/data/models/auth/user.dart';

class PasswordResetModel {
  final String id;
  final int idUsers;
  final String token;
  final DateTime expiredAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  final User? user;

  const PasswordResetModel({
    required this.id,
    required this.idUsers,
    required this.token,
    required this.expiredAt,
    this.usedAt,
    required this.createdAt,
    this.user,
  });

  factory PasswordResetModel.fromJson(Map<String, dynamic> json) {
    return PasswordResetModel(
      id: json['id'] as String,
      idUsers: json['id_users'] as int,
      token: json['token'] as String,
      expiredAt: DateTime.parse(json['expired_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_users': idUsers,
      'token': token,
      'expired_at': expiredAt.toIso8601String(),
      if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  PasswordResetModel copyWith({
    String? id,
    int? idUsers,
    String? token,
    DateTime? expiredAt,
    DateTime? usedAt,
    DateTime? createdAt,
    User? user,
  }) {
    return PasswordResetModel(
      id: id ?? this.id,
      idUsers: idUsers ?? this.idUsers,
      token: token ?? this.token,
      expiredAt: expiredAt ?? this.expiredAt,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiredAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordResetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PasswordResetModel(id: $id, isValid: $isValid, expiredAt: $expiredAt)';
  }
}
