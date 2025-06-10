class MedicationAdministration {
  final String id;
  final String medicationId; //which medication is taken
  final DateTime administrationAt;
  final String administeredByUserId;  //Who reprted this administration
  final String? notes; //any observation
  final String proofOfPhotoUrl; 
  final DateTime createdAt;

  MedicationAdministration({
    required this.id,
    required this.medicationId,
    required this.administrationAt,
    required this.administeredByUserId,
    this.notes,
    required this.proofOfPhotoUrl,
    required this.createdAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'administrationAt': administrationAt.toIso8601String(),
      'administeredByUserId': administeredByUserId,
      'notes': notes,
      'proofOfPhotoUrl': proofOfPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert from Firestore map
  factory MedicationAdministration.fromFirestoreMap(Map<String, dynamic> map) {
    return MedicationAdministration(
      id: map['id'],
      medicationId: map['medicationId'],
      administrationAt: DateTime.parse(map['administrationAt']),
      administeredByUserId: map['administeredByUserId'],
      notes: map['notes'],
      proofOfPhotoUrl: map['proofOfPhotoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}