class FriendRequest {
  String senderId;
  String senderName;
  String recipientId;
  String status; // Can be 'pending', 'accepted', or 'rejected'
  String timestamp;
  String recipientName;

  FriendRequest({
    required this.senderName,
    required this.recipientName,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.timestamp,
  });

  // Convert a FriendRequest object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'recipientName': recipientName, // Use the correct field name
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
      recipientName: json['recipientName'] ?? json['recipantName'], // Handle both
      senderName: json['senderName'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      status: json['status'],
      timestamp: json['timestamp'],
    );
  }
}