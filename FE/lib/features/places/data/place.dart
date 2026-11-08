class Place {
  const Place({required this.id, required this.nameEn, required this.nameGu, required this.isSeed});

  final String id;
  final String nameEn;
  final String nameGu;
  final bool isSeed;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        nameEn: j['name_en'] as String,
        nameGu: j['name_gu'] as String,
        isSeed: j['is_seed'] as bool,
      );

  /// Name in the app language.
  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameGu;

  /// The other language, shown small underneath.
  String otherNameFor(String languageCode) => languageCode == 'en' ? nameGu : nameEn;
}
