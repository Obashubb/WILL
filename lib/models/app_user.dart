class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.isGuest,
    required this.createdAt,
    this.email,
  });

  final String id;
  final String name;
  final String? email;
  final bool isGuest;
  final DateTime createdAt;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final spaceIndex = trimmed.indexOf(' ');
    return spaceIndex == -1 ? trimmed : trimmed.substring(0, spaceIndex);
  }

  AppUser copyWith({String? name, String? email, bool? isGuest}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        isGuest: isGuest ?? this.isGuest,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isGuest': isGuest,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as String?) ?? 'unknown',
        name: (json['name'] as String?) ?? 'Friend',
        email: json['email'] as String?,
        isGuest: (json['isGuest'] as bool?) ?? false,
        createdAt: json['createdAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
            : DateTime.now(),
      );
}
