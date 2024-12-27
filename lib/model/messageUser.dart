class MessageUser {
  final String? msg;
  final String? toID;
  final String? formID;
  late final String? read;
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
  MessageUser.fromJson(Map<String, dynamic> json)
      : msg = json['msg'] as String?,
        toID = json['toID'] as String?,
        formID = json['formID'] as String?,
        read = json['read'] as String?,
        type = (json['type'] as String) == Type.image.name ? Type.image : Type.text,
        sent = json['sent'] as String?;

  // Serialize to JSON
  Map<String, dynamic> toJson() => {
        'msg': msg,
        'toID': toID,
        'formID': formID,
        'read': read,
        'type': type.name, 
        'sent': sent,
      };
}

// Enum for message types
enum Type { image, text }
