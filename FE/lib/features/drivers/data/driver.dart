class Driver {
  const Driver({
    required this.id,
    required this.name,
    this.phone,
    this.defaultVehicleId,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? phone;
  final String? defaultVehicleId;
  final bool isActive;

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        defaultVehicleId: j['default_vehicle_id'] as String?,
        isActive: j['is_active'] as bool,
      );
}
