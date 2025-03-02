import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/Inviteuser.dart';
import 'package:chatting_application/requests/card_accept.dart';
import 'package:chatting_application/requests/invite.dart';
import 'package:chatting_application/screens/myhomepage.dart';
import 'package:chatting_application/screens/veiw_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  initState() {
    super.initState();
    APIs.updateActiveStatus(true);
    APIs.getFriendInvites();
    // Listen to app lifecycle changes for updating online status
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
        return Future.value(message);
      }
      return Future.value(message);
    });
  }

  // Fetch sender's user data
 Future<ChatUser> _fetchSenderUserData(String senderId) async {
  try {
    print("Fetching user data for senderId: $senderId"); // Debug print

    final snapshot = await APIs.firestore.collection('user').doc(senderId).get();

    if (snapshot.exists) {
      print("User data found: ${snapshot.data()}");
      return ChatUser.fromJson(snapshot.data()!);
    } else {
      print("User not found for senderId: $senderId");
      throw Exception('User not found');
    }
  } catch (e) {
    print("Error fetching user data: $e");
    throw Exception('Failed to fetch user data: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text(
          "Friend Requests",
          style: GoogleFonts.nunito(
            letterSpacing: 2,
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Invite()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(
                context,
                MaterialPageRoute(builder: (_) => const MyHomePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(thickness: 2, height: 3),
          Expanded(
            child: StreamBuilder<List<FriendRequest>>(
              stream: APIs.getFriendInvites(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show shimmer effect while loading
                  return _buildShimmerEffect();
                } else if (snapshot.hasError) {
                  // Show error message
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Show empty state UI
                  return Center(
                    child: Text(
                      "No pending friend requests",
                      style: GoogleFonts.nunito(
                        letterSpacing: 2,
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else {
                  // Data is available, show the list
                  final requests = snapshot.data!;

                  return SingleChildScrollView(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            try {
                              // Fetch sender's user data
                              final senderUser = await _fetchSenderUserData(requests[index].senderId);

                              // Navigate to ViewProfileScreen with sender's user data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewProfileScreen(user: senderUser),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error fetching user data: $e')),
                              );
                            }
                          },
                          child: FriendRequestCard(
                            request: requests[index],
                            onRemove: () => requests.removeAt(index),
                            onMessage: (String friendId) {
                              // Handle message navigation
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer effect widget
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Base color
      highlightColor: Colors.grey[100]!, // Highlight color
      child: ListView.builder(
        itemCount: 16, // Number of shimmering items
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Container(
                width: 150,
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                width: 200,
                height: 12,
                color: Colors.white,
              ),
              trailing: Container(
                width: 100,
                height: 40,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}