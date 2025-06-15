import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

enum ResourceCategoryStatus {
    active(1),
    inactive(0);

    final int value;

    const ResourceCategoryStatus(this.value);
}

class ResourceCategory {

    String id;
    String name;
    ResourceCategoryStatus status;
    Timestamps timestamps;

    ResourceCategory({
        required this.id,
        required this.name,
        required this.status,
        required this.timestamps,
    });

    factory ResourceCategory.fromJson(Map<String, dynamic> json) {
        return ResourceCategory(
            id: json['id'],
            name: json['name'],
            status: ResourceCategoryStatus.values.firstWhere((e) => e.value == json['status']),
            timestamps: Timestamps.fromJson(json['timestamps']),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'name': name,
            'status': status.value,
            'createdAt': Timestamp.fromDate(timestamps.createdAt),
            'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
        };
    }

    factory ResourceCategory.fromFirestore(String id, Map<String, dynamic> json) {
        return ResourceCategory(
            id: id,
            name: json['name'],
            status: ResourceCategoryStatus.values.firstWhere((e) => e.value == json['status']),
            timestamps: Timestamps.fromJson(json['timestamps']),
        );
    }

    ResourceCategory copyWith({
        String? id,
        String? name,
        ResourceCategoryStatus? status,
        Timestamps? timestamps,
    }) {
        return ResourceCategory(
            id: id ?? this.id,
            name: name ?? this.name,
            status: status ?? this.status,
            timestamps: timestamps ?? this.timestamps,
        );
    }
}