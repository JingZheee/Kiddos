import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/resource/resource_category.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ResourceCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'resource_categories';

  /// Fetch all resource categories from Firebase
  Future<List<ResourceCategory>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ResourceCategory.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get active resource categories only
  Future<List<ResourceCategory>> getActiveCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: ResourceCategoryStatus.active.value)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ResourceCategory.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific resource category by ID
  Future<ResourceCategory?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (doc.exists && doc.data() != null) {
        return ResourceCategory.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new resource category
  Future<ResourceCategory> createCategory(String name) async {
    try {
      // Create new category document reference
      final docRef = _firestore.collection(_collectionName).doc();
      
      final newCategory = ResourceCategory(
        id: docRef.id,
        name: name.trim(),
        status: ResourceCategoryStatus.active,
        timestamps: Timestamps.now(),
      );

      await docRef.set(newCategory.toJson());
      
      return newCategory;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing resource category
  Future<ResourceCategory> updateCategory(ResourceCategory category) async {
    try {
      // Update timestamps
      final updatedCategory = category.copyWith(
        timestamps: category.timestamps.copyWith(updatedAt: DateTime.now()),
      );

      await _firestore
          .collection(_collectionName)
          .doc(category.id)
          .update(updatedCategory.toJson());
      
      return updatedCategory;
    } catch (e) {
      rethrow;
    }
  }

  /// Deactivate a resource category (soft delete)
  Future<void> deactivateCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(categoryId)
          .update({
        'status': ResourceCategoryStatus.inactive.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Activate a resource category
  Future<void> activateCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(categoryId)
          .update({
        'status': ResourceCategoryStatus.active.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently delete a resource category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_collectionName).doc(categoryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a category name already exists
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: name.trim())
          .get();
      
      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
} 