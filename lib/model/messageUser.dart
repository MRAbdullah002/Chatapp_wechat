class MessageUser {
  final String? msg;
  final String? toID;
  final String? formID;
  final String? read;
  final Type type;
  final String? sent;

  MessageUser({
    required this.msg,
    required this.toID,
    required this.formID,
    required this.read,
    required this.type,
    required this.sent,
  });

  // Deserialize from JSON
  factory MessageUser.fromJson(Map<String, dynamic> json) {
    return MessageUser(
      msg: json['msg'] as String?,
      toID: json['toID'] as String?,
      formID: json['formID'] as String?,
      read: json['read'] as String?,
      type: Type.values.byName(json['type']), // Correct way to parse enum
      sent: json['sent'] as String?,
    );
  }

  // Serialize to JSON
  Map<String, dynamic> toJson() => {
        'msg': msg,
        'toID': toID,
        'formID': formID,
        'read': read,
        'type': type.name, // Stores the enum as a string
        'sent': sent,
      };
}

// Enum for message types
enum Type { image, text, video }
