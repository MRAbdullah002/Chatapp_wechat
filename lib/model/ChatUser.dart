class ChatUser {
  String? image;
  String? lastSeen;
  String? about;
  String? name;
  String? createdAt;
  String? id;
  String? email;
  String? pushToken;
  bool? status;
  bool? isdp;

  ChatUser({
    this.image,
    this.lastSeen,
    this.about,
    this.name,
    this.createdAt,
    this.id,
    this.email,
    this.pushToken,
    this.status,
    this.isdp,
  });

  ChatUser.fromJson(Map<String, dynamic> json)
    : image = json['image'] as String?,
      lastSeen = json['last_seen'] as String?,
      about = json['about'] as String?,
      name = json['name'] as String?,
      createdAt = json['created_at'] as String?,
      id = json['id'] as String?,
      email = json['email'] as String?,
      pushToken = json['push_token'] as String?,
      status = json['status'] as bool?,
      isdp = json['isdp'] as bool?;

  Map<String, dynamic> toJson() => {
    'image': image,
    'last_seen': lastSeen,
    'about': about,
    'name': name,
    'created_at': createdAt,
    'id': id,
    'email': email,
    'push_token': pushToken,
    'status': status,
    'isdp': isdp,
  };
}
