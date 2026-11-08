class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String username;
  final String name;
  final bool isActive;

  factory ManagedUser.fromJson(Map<String, dynamic> j) => ManagedUser(
        id: j['id'] as String,
        username: j['username'] as String,
        name: j['name'] as String,
        isActive: j['is_active'] as bool,
      );
}
