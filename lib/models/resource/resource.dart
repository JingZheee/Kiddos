import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';


enum ResourceStatus {
    active(1),
    inactive(0);

    final int value;

    const ResourceStatus(this.value);
}

class Resource {

    String id;
    String title;
    String description;
    String fileType;
    String fileUrl;
    String fileName;
    int size;
    String categoryId;
    String resourceCategoryId;
    ResourceStatus status;
    String uploadedBy;
    Timestamps timestamps;

    Resource({
        required this.id,
        required this.title,
        required this.description,
        required this.fileType,
        required this.fileUrl,
        required this.fileName,
        required this.size,
        required this.categoryId,
        required this.resourceCategoryId,
        required this.status,
        required this.uploadedBy,
        required this.timestamps,
    });

    factory Resource.fromJson(Map<String, dynamic> json) {
        return Resource(
            id: json['id'],
            title: json['title'],
            description: json['description'],
            fileType: json['fileType'],
            fileUrl: json['fileUrl'],
            fileName: json['fileName'],
            size: json['size'],
            categoryId: json['categoryId'],
            resourceCategoryId: json['resourceCategoryId'],
            status: ResourceStatus.values.firstWhere((e) => e.value == json['status']),
            uploadedBy: json['uploadedBy'],
            timestamps: Timestamps.fromJson(json['timestamps']),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'title': title,
            'description': description,
            'fileType': fileType,
            'fileUrl': fileUrl,
            'fileName': fileName,
            'size': size,
            'categoryId': categoryId,
            'resourceCategoryId': resourceCategoryId,
            'status': status.value,
            'uploadedBy': uploadedBy,
            'createdAt': Timestamp.fromDate(timestamps.createdAt),
            'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
        };
    }

    factory Resource.fromFirestore(String id, Map<String, dynamic> json) {
        return Resource(
            id: id,
            title: json['title'],
            description: json['description'],
            fileType: json['fileType'],
            fileUrl: json['fileUrl'],
            fileName: json['fileName'],
            size: json['size'],
            categoryId: json['categoryId'],
            resourceCategoryId: json['resourceCategoryId'],
            status: ResourceStatus.values.firstWhere((e) => e.value == json['status']),
            uploadedBy: json['uploadedBy'],
            timestamps: Timestamps.fromJson(json['timestamps']),
        );
    }

    Resource copyWith({
        String? id,
        String? title,
        String? description,
        String? fileType,
        String? fileUrl,
        String? fileName,
        int? size,
        String? categoryId,
        String? resourceCategoryId,
        ResourceStatus? status,
        String? uploadedBy,
        Timestamps? timestamps,
    }) {
        return Resource(
            id: id ?? this.id,
            title: title ?? this.title,
            description: description ?? this.description,
            fileType: fileType ?? this.fileType,
            fileUrl: fileUrl ?? this.fileUrl,
            fileName: fileName ?? this.fileName,
            size: size ?? this.size,
            categoryId: categoryId ?? this.categoryId,
            resourceCategoryId: resourceCategoryId ?? this.resourceCategoryId,
            status: status ?? this.status,
            uploadedBy: uploadedBy ?? this.uploadedBy,
            timestamps: timestamps ?? this.timestamps,
        );
    }
}