class Timestamps {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Timestamps({
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Timestamps.now() {
    final now = DateTime.now();
    return Timestamps(
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (deletedAt != null)
          'deleted_at': deletedAt!.toIso8601String(),
      };

  Timestamps copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Timestamps(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Timestamps markAsDeleted() {
    return copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Timestamps update() {
    return copyWith(
      updatedAt: DateTime.now(),
    );
  }
}
