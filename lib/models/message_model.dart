enum MessageStatus {
  sent,
  delivered,
  read,
}

enum MessageType {
  text,
  image,
  document,
  announcement,
}

class Message {
  final String id;
  final String senderId;
  final String? receiverId; // null for group messages
  final String? childId; // optional, if message is about a specific child
  final String? classId; // optional, if message is for a class
  final MessageType type;
  final DateTime timestamp;
  final String content;
  final List<String>? attachments;
  final MessageStatus status;
  final bool isGroup;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.childId,
    this.classId,
    required this.type,
    required this.timestamp,
    required this.content,
    this.attachments,
    required this.status,
    required this.isGroup,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'childId': childId,
      'classId': classId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'attachments': attachments,
      'status': status.toString().split('.').last,
      'isGroup': isGroup,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      childId: map['childId'],
      classId: map['classId'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      content: map['content'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      isGroup: map['isGroup'] ?? false,
    );
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final DateTime lastMessageTime;
  final Message? lastMessage;
  final bool isGroup;
  final String? childId;
  final String? classId;
  final String? name; // for group conversations
  final String? photoUrl; // for group conversations

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessageTime,
    this.lastMessage,
    required this.isGroup,
    this.childId,
    this.classId,
    this.name,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessage': lastMessage?.toMap(),
      'isGroup': isGroup,
      'childId': childId,
      'classId': classId,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      participants: List<String>.from(map['participants']),
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(map['lastMessage'])
          : null,
      isGroup: map['isGroup'] ?? false,
      childId: map['childId'],
      classId: map['classId'],
      name: map['name'],
      photoUrl: map['photoUrl'],
    );
  }
} 