import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/cardofchat.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/requests/invite.dart';
import 'package:chatting_application/screens/Profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ChatUser> _list = [];
  List<ChatUser> _searchlist = [];
  bool _issearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
    APIs.getAcceptedFriends();
    APIs.updateActiveStatus(true);
    
    

    // Listen to app lifecycle changes for updating online status
    SystemChannels.lifecycle.setMessageHandler((message) {
      print('Lifecycle message: $message');
      if (message.toString().contains('resume')) {
        APIs.updateActiveStatus(true);
      }
      if (message.toString().contains('pause')) {
        APIs.updateActiveStatus(false);
      }
      return Future.value(message);
    },);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        
        onWillPop: () {
          if (_issearching) {
            setState(() {
              _issearching = !_issearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.white,
            leading: IconButton(

              icon: const Icon(Icons.home_outlined),
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext _) =>
                        const MyHomePage(),
                  ),
                );
              },
            ),
            title: _issearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Name, Email...'),
                    autofocus: true,
                    onChanged: (value) async {
                      setState(() {
                        _searchlist.clear();
                      });

                      // Simulate a delay for searching
                      await Future.delayed(const Duration(milliseconds: 500));

                      for (var i in _list) {
                        if (i.name!
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            i.email!
                                .toLowerCase()
                                .contains(value.toLowerCase())) {
                          _searchlist.add(i);
                        }
                      }
                      setState(() {
                        _searchlist;
                      });
                    },
                  )
                : Text(
                    "We Chat",
                    style: GoogleFonts.nunito(
                        letterSpacing: 2,
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w800),
                  ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _issearching = !_issearching;
                    _searchlist.clear();
                  });
                },
                icon: Icon(_issearching ? Icons.cancel_outlined : Icons.search),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext _) =>
                            ProfileScreen(user: APIs.me),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert_outlined))
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 10),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Invite(),
                    ));
              },
              elevation: 1,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ),
          body: Column(
            children: [
              const Divider(
                thickness: 2,
                height: 3,
              ),
              Expanded(
                child: StreamBuilder<List<ChatUser>>(
                  stream: APIs.getAcceptedFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Show shimmer effect while fetching data
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      // Show error message
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // Show empty state UI
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Make New Friends',
                              style: GoogleFonts.poppins(fontSize: 25),
                            ),
                            Lottie.asset('assets/images/friends.json'),
                            MaterialButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.fade,
                                    child: const Invite(),
                                  ),
                                );
                              },
                              elevation: 5,
                              color: Colors.blueGrey,
                              child: const Text(
                                'Invite',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: Colors.white,
                                    letterSpacing: 2),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Data is available
                      final data = snapshot.data;
                      _list = data ?? [];
                
                      if (_issearching && _searchlist.isEmpty) {
                        // Show shimmer effect while searching
                        return _buildShimmerEffect();
                      }
                
                      return ListView.builder(
                        itemCount:
                            _issearching ? _searchlist.length : _list.length,
                        itemBuilder: (context, index) {
                          final user =
                              _issearching ? _searchlist[index] : _list[index];
                          return GestureDetector(
                            onLongPress: () => _showDeleteDialog(user),
                            child: CarduserChat(
                              user: user,
                              showStatus: true, // Show status
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteChat(ChatUser user) async {
    print("Deleting chat for user: ${user.name} (${user.id})");
    try {
      await APIs.deleteChat(user); // Ensure Firestore chat is deleted
      print("Chat deleted from Firestore!");

      setState(() {
        _list.removeWhere((u) => u.id == user.id); // Remove from local list
      });

      print("Chat removed from UI list!");
    } catch (e) {
      print("Error in _deleteChat: $e");
    }
  }

  Future<void> _showDeleteDialog(ChatUser user) async {
    print("Showing delete dialog for ${user.name}");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              onPressed: () {
                print("User canceled deletion");
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print("User confirmed deletion");
                await _deleteChat(user); // Wait for deletion
                Navigator.pop(context); // Close dialog after deletion
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.black.withOpacity(0.1), // Base color with opacity
      highlightColor: Colors.grey.withOpacity(0.2), // Highlight color with opacity
      child: ListView.builder(
        itemCount: 15, // Number of shimmering items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}