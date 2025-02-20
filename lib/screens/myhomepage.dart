import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/Api.dart';
import '../helper/cardofchat.dart';
import '../model/ChatUser.dart';
import '../requests/invite.dart';
import '../screens/Profilescreen.dart';


class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  List<ChatUser> _searchlist = [];
  bool _issearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
    APIs.updateActiveStatus(true);

    // Listen to app lifecycle changes for updating online status
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (message.toString().contains('resume')) {
        APIs.updateActiveStatus(true);
      }
      if (message.toString().contains('pause')) {
        APIs.updateActiveStatus(false);
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendList = ref.watch(chatProvider); // Fetch friends using Riverpod

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          if (_issearching) {
            setState(() {
              _issearching = !_issearching;
            });
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
            leading: const Icon(Icons.home_outlined, color: Colors.black, size: 26),
            title: _issearching
                ? TextField(
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Name, Email...'),
                    autofocus: true,
                    onChanged: (value) {
                      _searchlist = friendList.where((user) =>
                        user.name!.toLowerCase().contains(value.toLowerCase()) ||
                        user.email!.toLowerCase().contains(value.toLowerCase())
                      ).toList();
                      setState(() {}); // Refresh UI
                    },
                  )
                : Text(
                    "We Chat",
                    style: GoogleFonts.nunito(
                        letterSpacing: 2, color: Colors.black, fontSize: 26, fontWeight: FontWeight.w800),
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
                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext _) => ProfileScreen(user: APIs.me)));
                },
                icon: const Icon(Icons.more_vert_outlined),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 10),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Invite()));
              },
              elevation: 1,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ),
          body: Container(
            color: Colors.white,
            child: friendList.isNotEmpty
                ? ListView.builder(
                    itemCount: _issearching ? _searchlist.length : friendList.length,
                    itemBuilder: (context, index) {
                      final user = _issearching ? _searchlist[index] : friendList[index];
                      return GestureDetector(
                        onLongPress: () => _showDeleteDialog(user),
                        child: CarduserChat(user: user, showStatus: true),
                      );
                    },
                  )
                : _buildEmptyState(),
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
          Text('Make New Friends', style: GoogleFonts.poppins(fontSize: 25)),
          Lottie.asset('assets/images/friends.json'),
          MaterialButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(type: PageTransitionType.fade, child: const Invite()),
              );
            },
            elevation: 5,
            color: Colors.blueGrey,
            child: const Text('Invite',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatUser user) async {
    try {
      await APIs.deleteChat(user);
      ref.read(chatProvider.notifier).removeFriend(user.id.toString());
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  Future<void> _showDeleteDialog(ChatUser user) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteChat(user);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class ChatNotifier extends StateNotifier<List<ChatUser>> {
  ChatNotifier() : super([]) {
    fetchAcceptedFriends(); // Fetch friends on initialization
  }

  void fetchAcceptedFriends() {
    APIs.getAcceptedFriends().listen((users) {
      state = users;
    });
  }

  void removeFriend(String userId) {
    state = state.where((user) => user.id != userId).toList();
  }
}

// Riverpod provider for managing chat users
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatUser>>((ref) {
  return ChatNotifier();
});