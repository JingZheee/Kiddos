class Child {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String? photoUrl;
  final List<String> parentIds;
  final String classId;
  final Map<String, dynamic>? medicalInfo;
  final List<String>? allergies;
  final List<String>? emergencyContacts;
  final List<String>? authorizedPickup;
  
  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    required this.parentIds,
    required this.classId,
    this.medicalInfo,
    this.allergies,
    this.emergencyContacts,
    this.authorizedPickup,
  });
  
  String get fullName => '$firstName $lastName';
  
  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month || 
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'photoUrl': photoUrl,
      'parentIds': parentIds,
      'classId': classId,
      'medicalInfo': medicalInfo,
      'allergies': allergies,
      'emergencyContacts': emergencyContacts,
      'authorizedPickup': authorizedPickup,
    };
  }
  
  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      gender: map['gender'],
      photoUrl: map['photoUrl'],
      parentIds: List<String>.from(map['parentIds']),
      classId: map['classId'],
      medicalInfo: map['medicalInfo'],
      allergies: map['allergies'] != null 
          ? List<String>.from(map['allergies']) 
          : null,
      emergencyContacts: map['emergencyContacts'] != null 
          ? List<String>.from(map['emergencyContacts']) 
          : null,
      authorizedPickup: map['authorizedPickup'] != null 
          ? List<String>.from(map['authorizedPickup']) 
          : null,
    );
  }
} 