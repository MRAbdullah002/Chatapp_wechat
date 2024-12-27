

import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static late ChatUser me;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static User get user => auth.currentUser!;
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
        .update({'name': me.name, 'about': me.about});
  }

  // static Stream<QuerySnapshot<Map<String, dynamic>>> getAllmsg(ChatUser user) {
  //   return firestore.collection('chats/${getConversationID(user.id.toString())}/messages/').snapshots();
  // }s

  static String getConversationID(String ID) => user.uid.hashCode <= ID.hashCode
      ? '${user.uid}_$ID'
      : '${ID}_${user.uid}';
  static Future<void> sendMessage(ChatUser chatuser, String msg) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a message object
      final MessageUser message = MessageUser(
        msg: msg,
        toID: chatuser.id,
        type: Type.text, 
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

// send chat image
// static Future<void>  sendChatImage (ChatUser chatUser, File file){

// }

}
