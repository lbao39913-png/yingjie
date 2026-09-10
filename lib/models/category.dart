class Category {
  const Category({
    required this.id,
    required this.name,
    this.cover = '',
  });

  final String id;
  final String name;
  final String cover;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover': cover,
    };
  }
}
