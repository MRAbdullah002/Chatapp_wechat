class AcceptFriendRequest {
  String senderId;
  String recipientId;
  String acceptedAt;

  AcceptFriendRequest({
    required this.senderId,
    required this.recipientId,
    required this.acceptedAt,
  });

  // Convert an AcceptFriendRequest object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'acceptedAt': acceptedAt,
    };
  }

  // Create an AcceptFriendRequest object from a JSON map
  factory AcceptFriendRequest.fromJson(Map<String, dynamic> json) {
    return AcceptFriendRequest(
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      acceptedAt: json['acceptedAt'],
    );
  }
}
