class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.phone,
    this.companyName = '',
  });

  final String id;
  final String username;
  final String name;
  final String role;
  final String? phone;
  final String companyName;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        companyName: json['company_name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role,
        'phone': phone,
        'company_name': companyName,
      };
}
