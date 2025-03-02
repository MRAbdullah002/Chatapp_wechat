import 'dart:io';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/Inviteuser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class APIs {
  static firebase_auth.FirebaseAuth auth = firebase_auth.FirebaseAuth.instance;
  static late ChatUser me;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static firebase_auth.User get user => auth.currentUser!;
  static Future<bool> userExist() async {
    return (await firestore.collection('user').doc(user.uid).get()).exists;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('user').doc(user.uid).get().then(
      (user) async {
        if (user.exists) {
          me = ChatUser.fromJson(user.data()!);
          print("my data ${user.data()}");
        } else {
          await createUser().then(
            (value) => getSelfInfo(),
          );
        }
      },
    );
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatuser = ChatUser(
      email: user.email.toString(),
      id: user.uid.toString(),
      name: user.displayName.toString(),
      image: user.photoURL.toString(),
      about: 'hey, i am using wechat',
      createdAt: time,
      lastSeen: time,
      pushToken: '',
      status: false,
    );

    return await firestore
        .collection('user')
        .doc(user.uid)
        .set(chatuser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUser() {
    return firestore
        .collection('user')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  static Stream<List<Map<String, dynamic>>> getAllUserWithStatus() {
    return firestore
        .collection('user')
        .where('id', isNotEqualTo: user.uid)
        .snapshots()
        .asyncMap((usersSnapshot) async {
      final users = usersSnapshot.docs;
      final updatedUsers = await Future.wait(users.map((userDoc) async {
        final userId = userDoc.id;
        final statusSnapshot = await firestore
            .collection('friendRequests')
            .where('senderId', isEqualTo: userId)
            .where('recipientId', isEqualTo: user.uid)
            .get();

        final friendRequestStatus = statusSnapshot.docs.isNotEmpty
            ? statusSnapshot.docs.first['status']
            : 'none';

        return userDoc.data()
          ..['friendRequestStatus'] =
              friendRequestStatus; // Add friend request status
      }));

      return updatedUsers; // Return the list of users with their statuses
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserinfo(
      ChatUser chatuser) {
    return firestore
        .collection('user')
        .where('id', isEqualTo: chatuser.id)
        .snapshots();
  }

  // Update the user's active status (online/offline)
  static Future<void> updateActiveStatus(bool isOnline) async {
    final lastSeen =
        isOnline ? null : DateTime.now().millisecondsSinceEpoch.toString();
    await firestore.collection('user').doc(user.uid).update({
      'status': isOnline,
      'last_seen': lastSeen,
    });
  }

  static Future<void> updateUserinfo() async {
    firestore.collection('user').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // static Stream<QuerySnapshot<Map<String, dynamic>>> getAllmsg(ChatUser user) {
  //   return firestore.collection('chats/${getConversationID(user.id.toString())}/messages/').snapshots();
  // }s

  static String getConversationID(String ID) => user.uid.hashCode <= ID.hashCode
      ? '${user.uid}_$ID'
      : '${ID}_${user.uid}';
  static Future<void> sendMessage(
      ChatUser chatuser, String msg, Type type) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a message object
      final MessageUser message = MessageUser(
        msg: msg,
        toID: chatuser.id,
        type: type,
        formID: user.uid,
        read: '',
        sent: time,
      );

      print("Sending message: ${message.toJson()}");

      final ref = firestore.collection(
          'chats/${getConversationID(chatuser.id.toString())}/messages/');

      await ref.doc(time).set(message.toJson());
      print("Message sent successfully.");
    } catch (e) {
      // Handle any errors during the Firestore operation
      print("Error sending message: $e");
    }
  }

  static Stream<QuerySnapshot> getAllmsg(ChatUser chatUser) {
    final ref = firestore.collection(
        'chats/${getConversationID(chatUser.id.toString())}/messages/');
    return ref.orderBy('sent', descending: true).snapshots();
  }

  static Future<void> updateMessageReadStatus(MessageUser message) async {
    try {
      final conversationID = getConversationID(message.formID.toString());
      final docRef = firestore
          .collection('chats/$conversationID/messages/')
          .doc(message.sent.toString());

      print("Document Path: chats/$conversationID/messages/${message.sent}");

      final docSnapshot =
          await docRef.get(const GetOptions(source: Source.server));
      if (docSnapshot.exists) {
        print("Document Data: ${docSnapshot.data()}");
        await docRef.update({
          'read': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        print("Document updated successfully.");
      } else {
        print("Document does not exist. Unable to update.");
      }
    } catch (e) {
      print("Error updating message read status: $e");
    }
  }

  static Stream<QuerySnapshot> getlastsms(ChatUser chatUser) {
    final ref = firestore
        .collection(
            'chats/${getConversationID(chatUser.id.toString())}/messages/')
        .limit(1);
    return ref
        .orderBy('sent', descending: true)
        .snapshots(); // Real-time updates
  }

  static Future<void> updateProfilePic([String? imageUrl]) async {
    firestore.collection('user').doc(user.uid).update({'image': me.image});
    print(imageUrl);
  }

  static Future<void> deleteChat(ChatUser user) async {
    print("Attempting to delete chat for user: ${user.id}");
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats');

      // Find the chat document where the user is a participant
      final querySnapshot =
          await chatRef.where('participants', arrayContains: user.id).get();

      if (querySnapshot.docs.isEmpty) {
        print("No chat document found for ${user.name} (${user.id})");
        return;
      }

      for (var doc in querySnapshot.docs) {
        // Reference to messages subcollection
        final messagesRef = chatRef.doc(doc.id).collection('messages');

        // Delete all messages in the chat
        final messagesSnapshot = await messagesRef.get();
        for (var message in messagesSnapshot.docs) {
          await message.reference.delete();
        }
        print("Deleted all messages for chat: ${doc.id}");

        // Delete the chat document
        await doc.reference.delete();
        print("Deleted chat document: ${doc.id}");
      }
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  static Future<void> sendFriendRequest(ChatUser recipient) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      // Debug prints to check values
      print('Sender (APIs.me.name): ${APIs.me.name}');
      print('Recipient name: ${recipient.name}');
      print('Sender ID (APIs.user.uid): ${APIs.user.uid}');
      print('Recipient ID: ${recipient.id}');

      // Create a FriendRequest object
      final request = FriendRequest(
        senderName: APIs.me.name.toString(),
        senderId: APIs.user.uid,
        recipientId: recipient.id.toString(),
        status: 'pending',
        timestamp: time,
        recipientName: recipient.name.toString(),
      );

      // Debug print to check request object
      print('Request object: ${request.toJson()}');

      // Add the request to the 'friendRequests' collection
      await APIs.firestore.collection('friendRequests').add(request.toJson());
      print("Friend request sent to ${recipient.name}");
    } catch (e, stackTrace) {
      print('Error sending friend request: $e');
      print('Stack trace: $stackTrace');
      throw e; // Re-throw to handle in UI
    }
  }

  static Future<void> acceptFriendRequest(String requestId) async {
    // Update the request status to 'accepted'
    await APIs.firestore.collection('friendRequests').doc(requestId).update({
      'status': 'accepted',
    });

    // Add each other to the friends list
    final requestSnapshot =
        await APIs.firestore.collection('friendRequests').doc(requestId).get();
    final senderId = requestSnapshot['senderId'];
    final recipientId = requestSnapshot['recipientId'];

    // Add sender to recipient's friends list
    await APIs.firestore.collection('users').doc(recipientId).update({
      'friends': FieldValue.arrayUnion([senderId]),
    });

    // Add recipient to sender's friends list
    await APIs.firestore.collection('users').doc(senderId).update({
      'friends': FieldValue.arrayUnion([recipientId]),
    });

    print("Friend request accepted and added to friends list.");
  }

// reject
  static Future<void> rejectFriendRequest(String requestId) async {
    // Update the request status to 'rejected'
    await APIs.firestore.collection('friendRequests').doc(requestId).update({
      'status': 'rejected',
    });

    print("Friend request rejected.");
  }

// checkExisting
  static Future<bool> checkExistingRequest(ChatUser recipient) async {
    final snapshot = await APIs.firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: APIs.user.uid)
        .where('recipientId', isEqualTo: recipient.id)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.isNotEmpty;
  }

  static Stream<List<FriendRequest>> getFriendInvites() {
    return firestore
        .collection('friendRequests')
        .where('recipientId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        // Get only pending requests
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromJson(doc.data()))
            .toList());
  }

  static Stream<List<ChatUser>> getFriends() {
    return firestore
        .collection('user')
        .where('friends',
            arrayContains: user
                .uid) // Find users who have current user in their friends list
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatUser.fromJson(doc.data())).toList());
  }

  static Stream<List<ChatUser>> getAcceptedFriends() {
    return firestore
        .collection('friendRequests')
        .where('status', isEqualTo: 'accepted')
        .where(Filter.or(
            Filter('recipientId',
                isEqualTo: user.uid), // Current user is the recipient
            Filter('senderId',
                isEqualTo: user.uid) // Current user is the sender
            ))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> friendsWithTimestamps = [];

      for (var doc in snapshot.docs) {
        String senderId = doc['senderId'].toString();
        String recipientId = doc['recipientId'].toString();

        // Get the friend's ID (the other person in the conversation)
        String friendId = senderId == user.uid ? recipientId : senderId;

        // Get the latest message for each friend conversation
        final latestMessageSnapshot = await firestore
            .collection('chats/${getConversationID(friendId)}/messages/')
            .orderBy('sent', descending: true)
            .limit(1)
            .get();

        if (latestMessageSnapshot.docs.isNotEmpty) {
          final latestMessage = latestMessageSnapshot.docs.first;
          friendsWithTimestamps.add({
            'friendId': friendId,
            'lastMessageTime':
                latestMessage['sent'], // Timestamp of the latest message
          });
        }
      }

      // Sort friends based on the latest message timestamp
      friendsWithTimestamps
          .sort((a, b) => b['lastMessageTime'].compareTo(a['lastMessageTime']));

      // Extract ordered friend IDs
      List orderedFriendIds =
          friendsWithTimestamps.map((e) => e['friendId']).toList();

      if (orderedFriendIds.isEmpty) return [];

      // Fetch ChatUser data for friends in the correct order
      final friendsSnapshot = await firestore
          .collection('user')
          .where('id', whereIn: orderedFriendIds)
          .get();

      // Map the data while preserving order
      List<ChatUser> friendsList = orderedFriendIds
          .map((id) => friendsSnapshot.docs
              .map((doc) => ChatUser.fromJson(doc.data()))
              .firstWhere((friend) => friend.id == id))
          .toList();

      return friendsList;
    });
  }

  static Stream<List<ChatUser>> getFilteredFriends() {
    return firestore
        .collection('friendRequests')
        .where('status', isEqualTo: 'accepted')
        .where(Filter.or(
          Filter('recipientId',
              isEqualTo: user.uid), // Current user is the recipient
          Filter('senderId', isEqualTo: user.uid), // Current user is the sender
        ))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> friendsWithTimestamps = [];

      for (var doc in snapshot.docs) {
        String senderId = doc['senderId'].toString();
        String recipientId = doc['recipientId'].toString();

        // Get the friend's ID (the other person in the conversation)
        String friendId = senderId == user.uid ? recipientId : senderId;

        // Check if a chat exists for this friend
        final chatSnapshot = await firestore
            .collection('chats')
            .doc(getConversationID(friendId))
            .get();

        // If the chat exists and is not deleted, proceed
        if (chatSnapshot.exists && !chatSnapshot['isDeleted']) {
          // Get the latest message for each friend conversation
          final latestMessageSnapshot = await firestore
              .collection('chats/${getConversationID(friendId)}/messages/')
              .orderBy('sent', descending: true)
              .limit(1)
              .get();

          if (latestMessageSnapshot.docs.isNotEmpty) {
            final latestMessage = latestMessageSnapshot.docs.first;
            friendsWithTimestamps.add({
              'friendId': friendId,
              'lastMessageTime':
                  latestMessage['sent'], // Timestamp of the latest message
            });
          }
        }
      }

      // Sort friends based on the latest message timestamp
      friendsWithTimestamps
          .sort((a, b) => b['lastMessageTime'].compareTo(a['lastMessageTime']));

      // Extract ordered friend IDs
      List orderedFriendIds =
          friendsWithTimestamps.map((e) => e['friendId']).toList();

      if (orderedFriendIds.isEmpty) return [];

      // Fetch ChatUser data for friends in the correct order
      final friendsSnapshot = await firestore
          .collection('user')
          .where('id', whereIn: orderedFriendIds)
          .get();

      // Map the data while preserving order
      List<ChatUser> friendsList = orderedFriendIds
          .map((id) => friendsSnapshot.docs
              .map((doc) => ChatUser.fromJson(doc.data()))
              .firstWhere((friend) => friend.id == id))
          .toList();

      return friendsList;
    });
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final supabase = Supabase.instance.client;
    final ext = file.path.split('.').last; // Get file extension

    final fileName =
        '${getConversationID(chatUser.id.toString())}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = 'camera_image/$fileName';

    try {
      // Read file as bytes
      final fileBytes = await file.readAsBytes();

      // Upload file to Supabase Storage
      await supabase.storage.from('camera_image').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL of the uploaded image
      final imageURL =
          supabase.storage.from('camera_image').getPublicUrl(filePath);

      // Send the image message
      await sendMessage(chatUser, imageURL, Type.image);

      print('Image uploaded successfully: $imageURL');
    } catch (e, stackTrace) {
      print('Image upload failed: $e');
      print(stackTrace);
    }
  }

  static Future<bool> checkChatExists(String userId) async {
    var doc =
        await FirebaseFirestore.instance.collection('chats').doc(userId).get();
    return doc.exists; // Returns true if the document still exists
  }

  static Future<bool> hasUserUpdatedRequest(String senderId) async {
    final snapshot = await firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final requestStatus = snapshot.docs.first['status'];
      return requestStatus == 'accepted' || requestStatus == 'rejected';
    }
    return false;
  }

  static Future<String> checkFriendRequestStatus(String recipientId) async {
    final snapshot = await firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: user.uid)
        .where('recipientId', isEqualTo: recipientId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['status']; // Return the current status
    }
    return 'none'; // No request found
  }



static Future<void> sendChatVideo(ChatUser chatUser, File file) async {
  final supabase = Supabase.instance.client;
  final ext = file.path.split('.').last.toLowerCase();
  final fileSize = file.lengthSync(); // Get file size in bytes
  final maxFileSize = 50 * 1024 * 1024; // 50MB limit

  if (fileSize > maxFileSize) {
    print('Error: File size exceeds the 50MB limit.');
    return;
  }

  final fileName =
      '${getConversationID(chatUser.id.toString())}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  final filePath = 'videos_user/$fileName';

  try {
    final fileBytes = await file.readAsBytes();
    print('✅ Video file read successfully: ${file.path}');
    print('📏 File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

    // Upload video with proper content-type
    await supabase.storage.from('videos_user').uploadBinary(
      filePath,
      fileBytes,
      fileOptions: FileOptions(contentType: 'video/mp4', cacheControl: '3600', upsert: true),
    );

    // Generate public URL
    final videoURL = supabase.storage.from('videos_user').getPublicUrl(filePath);
    print('✅ Video uploaded successfully: $videoURL');

    // Send message with video URL
    await sendMessage(chatUser, videoURL, Type.video);
    print('✅ Video message sent successfully.');

  } catch (e, stackTrace) {
    print('❌ Video upload failed: $e');
    print('🛠️ Stack trace: $stackTrace');
  }
}

static Future<void> deleteMessage(MessageUser message, String chatUserId) async {
  try {
    // Ensure only the sender can delete their messages
    if (APIs.user.uid != message.formID) {
      print("Unauthorized deletion attempt: Only the sender can delete this message.");
      return;
    }

    final conversationID = getConversationID(chatUserId); // Ensure we pass only the ID
    final messageID = message.sent.toString(); // Ensure Firestore uses the same ID format

    print("Generated conversation ID: $conversationID");
    print("Message ID to delete: $messageID");

    final docRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(conversationID)
        .collection('messages')
        .doc(messageID);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      print("Message exists. Proceeding with deletion...");
      await docRef.delete();
      print("Message deleted successfully.");
    } else {
      print("Message with ID '$messageID' does NOT exist in chat '$conversationID'.");
    }
  } catch (e) {
    print("Error deleting message: $e");
  }
}





  static Future<void> deleteMedia(String url) async {
    // Delete media from Supabase
    // Assuming you have a Supabase client initialized
    final supabase = Supabase.instance.client;
    final filePath = url.split('/').last; // Extract file name from URL
    await supabase.storage.from('camera_image').remove([filePath]);
    await supabase.storage.from('videos_user').remove([filePath]);
  }


}
