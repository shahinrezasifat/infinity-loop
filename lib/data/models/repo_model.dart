class RepoModel {
  const RepoModel({
    required this.id,
    required this.name,
    required this.ecosystem,
    required this.category,
    required this.manifestUrl,
    required this.isNsfw,
    this.shortcode,
  });

  final int id;
  final String name;
  final String ecosystem;
  final String category;
  final String manifestUrl;
  final bool isNsfw;
  final String? shortcode;

  factory RepoModel.fromMap(Map<String, Object?> map) => RepoModel(
    id: map['id'] as int,
    name: map['name'] as String,
    ecosystem: map['ecosystem'] as String,
    category: map['category'] as String,
    manifestUrl: map['manifestUrl'] as String,
    isNsfw: (map['isNsfw'] as int?) == 1,
    shortcode: map['shortcode'] as String?,
  );

  factory RepoModel.fromAsset(Map<String, dynamic> map) => RepoModel(
    id: 0,
    name: map['name'] as String,
    ecosystem: map['ecosystem'] as String,
    category: map['category'] as String,
    manifestUrl: map['manifestUrl'] as String,
    isNsfw: map['isNsfw'] == true,
    shortcode: map['shortcode'] as String?,
  );

  Map<String, Object?> toMap() => {
    'name': name,
    'ecosystem': ecosystem,
    'category': category,
    'manifestUrl': manifestUrl,
    'isNsfw': isNsfw ? 1 : 0,
    'shortcode': shortcode,
  };
}
