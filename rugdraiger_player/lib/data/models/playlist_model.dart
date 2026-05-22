class PlaylistModel {
  final int id;
  final String name;
  final String? description;
  final List<int> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverPath;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.songIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.coverPath,
  });

  int get songCount => songIds.length;

  PlaylistModel copyWith({
    int? id,
    String? name,
    String? description,
    List<int>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverPath,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'cover_path': coverPath,
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      coverPath: map['cover_path'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlaylistModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
