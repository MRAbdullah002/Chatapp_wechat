class FriendRequest {
  String senderId;
  String senderName;
  String recipientId;
  String status; // Can be 'pending', 'accepted', or 'rejected'
  String timestamp;
  String recipantName;

  FriendRequest({
    required this.senderName,
    required this.recipantName,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.timestamp,
  });

  // Convert a FriendRequest object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'recipantName': recipantName,
      'senderName': senderName,
      'senderId': senderId,
      'recipientId': recipientId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  // Create a FriendRequest object from a JSON map
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      recipantName: json['recipantName'],
      senderName: json['senderName'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      status: json['status'],
      timestamp: json['timestamp'],
    );
  }
}