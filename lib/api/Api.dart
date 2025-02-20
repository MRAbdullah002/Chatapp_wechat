

import 'dart:io';

import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/Inviteuser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart' ;

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
        .snapshots();}
static Stream<QuerySnapshot<Map<String, dynamic>>> getUserinfo(ChatUser chatuser) {
  return firestore
      .collection('user')
      .where('id', isEqualTo: chatuser.id)
      .snapshots();
}

 // Update the user's active status (online/offline)
 static Future<void> updateActiveStatus(bool isOnline) async {
  final lastSeen = isOnline ? null : DateTime.now().millisecondsSinceEpoch.toString();
  await firestore.collection('user').doc(user.uid).update({
    'status': isOnline,
    'last_seen': lastSeen,
  });
}

  static Future<void> updateUserinfo() async {
    firestore
        .collection('user')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about, });
        
  }

  // static Stream<QuerySnapshot<Map<String, dynamic>>> getAllmsg(ChatUser user) {
  //   return firestore.collection('chats/${getConversationID(user.id.toString())}/messages/').snapshots();
  // }s

  static String getConversationID(String ID) => user.uid.hashCode <= ID.hashCode
      ? '${user.uid}_$ID'
      : '${ID}_${user.uid}';
  static Future<void> sendMessage(ChatUser chatuser, String msg,Type type) async {
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

   
    final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
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
    final ref = firestore.collection(
        'chats/${getConversationID(chatUser.id.toString())}/messages/').limit(1);
    return ref
        .orderBy('sent', descending: true)
        .snapshots(); // Real-time updates
  }

 static Future<void> updateProfilePic([String? imageUrl]) async {
    firestore
        .collection('user')
        .doc(user.uid)
        .update({'image': me.image});
        print(imageUrl);
  }


static Future<void> deleteChat(ChatUser user) async {
  print("Attempting to delete chat for user: ${user.id}");
  try {
    final chatRef = FirebaseFirestore.instance.collection('chats');

    // Find the chat document where the user is a participant
    final querySnapshot = await chatRef
        .where('participants', arrayContains: user.id)
        .get();

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
  final time = DateTime.now().millisecondsSinceEpoch.toString();

  // Create a FriendRequest object
  final request = FriendRequest(
    senderName: recipient.name.toString(),
    senderId: APIs.user.uid,
    recipientId: recipient.id.toString(),
    status: 'pending',
    timestamp: time, recipantName: '',
  );

  // Add the request to the 'friendRequests' collection
  await APIs.firestore.collection('friendRequests').add(request.toJson());
  print("Friend request sent to ${recipient.name}");
}

static Future<void> acceptFriendRequest(String requestId) async {
  // Update the request status to 'accepted'
  await APIs.firestore.collection('friendRequests').doc(requestId).update({
    'status': 'accepted',
  });

  // Add each other to the friends list
  final requestSnapshot = await APIs.firestore.collection('friendRequests').doc(requestId).get();
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
      .where('friends', arrayContains: user.uid) // Find users who have current user in their friends list
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => ChatUser.fromJson(doc.data())).toList());
}
static Stream<List<ChatUser>> getAcceptedFriends() {
  return firestore
      .collection('friendRequests')
      .where('status', isEqualTo: 'accepted') 
      .where(Filter.or(
        Filter('recipientId', isEqualTo: user.uid), // Current user is the recipient
        Filter('senderId', isEqualTo: user.uid) // Current user is the sender
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
              'lastMessageTime': latestMessage['sent'], // Timestamp of the latest message
            });
          }
        }

        // Sort friends based on the latest message timestamp
        friendsWithTimestamps.sort((a, b) => b['lastMessageTime'].compareTo(a['lastMessageTime']));

        // Extract ordered friend IDs
        List orderedFriendIds = friendsWithTimestamps.map((e) => e['friendId']).toList();

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
    final imageURL = supabase.storage.from('camera_image').getPublicUrl(filePath);

    // Send the image message
    await sendMessage(chatUser, imageURL, Type.image);

    print('Image uploaded successfully: $imageURL');
  } catch (e, stackTrace) {
    print('Image upload failed: $e');
    print(stackTrace);
  }
}




 
}
