import 'package:flutter/foundation.dart';

/// The signed-in user (mirrors the backend `SessionUser`).
@immutable
class AppUser {
  const AppUser({required this.id, required this.email, required this.name, required this.role});

  final String id;
  final String email;
  final String name;
  final String role;

  bool get isAdmin => role == 'admin' || role == 'editor';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        role: (j['role'] ?? 'user').toString(),
      );

  /// First-letter initials for the avatar.
  String get initials {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return 'EA';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}
