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
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (deletedAt != null)
          'deletedAt': deletedAt!.toIso8601String(),
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
