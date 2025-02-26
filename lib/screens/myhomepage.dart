import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/cardofchat.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/requests/invite.dart';
import 'package:chatting_application/screens/Profilescreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';

/// **Provider to manage initialization state**
final appInitProvider = Provider<void>((ref) {
  APIs.getAcceptedFriends();
  APIs.updateActiveStatus(true);

  // Listen to app lifecycle changes for updating online status
  SystemChannels.lifecycle.setMessageHandler((message) {
    if (APIs.auth.currentUser != null) {
      if (message == AppLifecycleState.resumed.toString()) {
        APIs.updateActiveStatus(true);
      } else if (message == AppLifecycleState.paused.toString() ||
          message == AppLifecycleState.inactive.toString() ||
          message == AppLifecycleState.detached.toString()) {
        APIs.updateActiveStatus(false);
      }
    }
    return Future.value(message);
  });
});

/// **Make MyHomePage a ConsumerWidget**
class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  List<ChatUser> _list = [];
  List<ChatUser> _searchlist = [];
  bool _issearching = false;

  @override
  void initState() {
    super.initState();
    ref.read(appInitProvider);
    APIs.getSelfInfo(); // Ensure initialization runs once
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext _) => const MyHomePage(),
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
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    } else {
                      _list = snapshot.data ?? [];

                      if (_issearching && _searchlist.isEmpty) {
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
                              showStatus: true,
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

  Widget _buildEmptyState() {
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
              Navigator.pushReplacement(
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
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.black.withOpacity(0.1),
      highlightColor: Colors.grey.withOpacity(0.2),
      child: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
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
                      Container(height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, color: Colors.white),
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
  void _showDeleteDialog(ChatUser user) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Delete Chat"),
        content: Text("Are you sure you want to delete the chat with ${user.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              APIs.deleteChat(user);
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}

}
