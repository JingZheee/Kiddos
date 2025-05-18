enum ActivityType {
  meal,
  nap,
  learning,
  play,
  bathroom,
  medication,
  observation,
  incident,
  mood,
}

enum MoodType {
  happy,
  calm,
  tired,
  sad,
  angry,
  sick,
}

class DailyActivity {
  final String id;
  final String childId;
  final String teacherId;
  final ActivityType activityType;
  final DateTime timestamp;
  final String title;
  final String description;
  final Map<String, dynamic>? metadata;
  final List<String>? photoUrls;

  DailyActivity({
    required this.id,
    required this.childId,
    required this.teacherId,
    required this.activityType,
    required this.timestamp,
    required this.title,
    required this.description,
    this.metadata,
    this.photoUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'teacherId': teacherId,
      'activityType': activityType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'description': description,
      'metadata': metadata,
      'photoUrls': photoUrls,
    };
  }

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      id: map['id'],
      childId: map['childId'],
      teacherId: map['teacherId'],
      activityType: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == map['activityType'],
        orElse: () => ActivityType.observation,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      title: map['title'],
      description: map['description'],
      metadata: map['metadata'],
      photoUrls: map['photoUrls'] != null 
          ? List<String>.from(map['photoUrls']) 
          : null,
    );
  }
}

class MealActivity extends DailyActivity {
  final String mealType; // breakfast, lunch, snack, etc.
  final bool eaten; // did the child eat?
  final String? amount; // how much did they eat?
  final String? menu; // what was served?

  MealActivity({
    required String id,
    required String childId,
    required String teacherId,
    required DateTime timestamp,
    required String title,
    required String description,
    required this.mealType,
    required this.eaten,
    this.amount,
    this.menu,
    Map<String, dynamic>? metadata,
    List<String>? photoUrls,
  }) : super(
          id: id,
          childId: childId,
          teacherId: teacherId,
          activityType: ActivityType.meal,
          timestamp: timestamp,
          title: title,
          description: description,
          metadata: {
            'mealType': mealType,
            'eaten': eaten,
            'amount': amount,
            'menu': menu,
            ...?metadata,
          },
          photoUrls: photoUrls,
        );

  factory MealActivity.fromDailyActivity(DailyActivity activity) {
    final metadata = activity.metadata ?? {};
    return MealActivity(
      id: activity.id,
      childId: activity.childId,
      teacherId: activity.teacherId,
      timestamp: activity.timestamp,
      title: activity.title,
      description: activity.description,
      mealType: metadata['mealType'] ?? 'Unknown',
      eaten: metadata['eaten'] ?? false,
      amount: metadata['amount'],
      menu: metadata['menu'],
      photoUrls: activity.photoUrls,
    );
  }
}

class NapActivity extends DailyActivity {
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? quality; // good, restless, etc.

  NapActivity({
    required String id,
    required String childId,
    required String teacherId,
    required DateTime timestamp,
    required String title,
    required String description,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.quality,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          childId: childId,
          teacherId: teacherId,
          activityType: ActivityType.nap,
          timestamp: timestamp,
          title: title,
          description: description,
          metadata: {
            'startTime': startTime.toIso8601String(),
            'endTime': endTime?.toIso8601String(),
            'durationMinutes': durationMinutes,
            'quality': quality,
            ...?metadata,
          },
        );

  factory NapActivity.fromDailyActivity(DailyActivity activity) {
    final metadata = activity.metadata ?? {};
    return NapActivity(
      id: activity.id,
      childId: activity.childId,
      teacherId: activity.teacherId,
      timestamp: activity.timestamp,
      title: activity.title,
      description: activity.description,
      startTime: DateTime.parse(metadata['startTime']),
      endTime: metadata['endTime'] != null 
          ? DateTime.parse(metadata['endTime']) 
          : null,
      durationMinutes: metadata['durationMinutes'],
      quality: metadata['quality'],
    );
  }
}

class MoodActivity extends DailyActivity {
  final MoodType mood;
  final String? note;

  MoodActivity({
    required String id,
    required String childId,
    required String teacherId,
    required DateTime timestamp,
    required String title,
    required String description,
    required this.mood,
    this.note,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          childId: childId,
          teacherId: teacherId,
          activityType: ActivityType.mood,
          timestamp: timestamp,
          title: title,
          description: description,
          metadata: {
            'mood': mood.toString().split('.').last,
            'note': note,
            ...?metadata,
          },
        );

  factory MoodActivity.fromDailyActivity(DailyActivity activity) {
    final metadata = activity.metadata ?? {};
    return MoodActivity(
      id: activity.id,
      childId: activity.childId,
      teacherId: activity.teacherId,
      timestamp: activity.timestamp,
      title: activity.title,
      description: activity.description,
      mood: MoodType.values.firstWhere(
        (e) => e.toString().split('.').last == metadata['mood'],
        orElse: () => MoodType.happy,
      ),
      note: metadata['note'],
    );
  }
} 