import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/cardofinvite.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/requests/accept.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';

class Invite extends StatefulWidget {
  const Invite({super.key});

  @override
  State<Invite> createState() => _InviteState();
}

class _InviteState extends State<Invite> {
  List<ChatUser> _list = [];
  List<ChatUser> _searchlist = [];
  bool _issearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
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
    });
  }

  // Function to search users in Firestore
  Stream<QuerySnapshot> searchUsers(String query) {
    return APIs.firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }

  // Function to remove a user from the list
  void _removeUser(ChatUser user) {
    setState(() {
      _list.remove(user);
      _searchlist.remove(user);
    });
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
          appBar: AppBar(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
            leading: const Icon(
              Icons.home_outlined,
              color: Colors.black,
              size: 26,
            ),
            title: _issearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Name, Email...'),
                    autofocus: true,
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        final snapshot = await searchUsers(value).first;
                        _searchlist = snapshot.docs
                            .map((doc) => ChatUser.fromJson(
                                doc.data() as Map<String, dynamic>))
                            .toList();
                        setState(() {});
                      } else {
                        _searchlist.clear();
                        setState(() {});
                      }
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
                      builder: (context) => const FriendRequestsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.read_more),
              ),
            ],
          ),
          body: Container(
            color: Colors.white,
            child: StreamBuilder(
              stream: APIs.getAllUser().distinct(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(
                      child: SizedBox(
                        height: 100,
                        width: 50,
                        child: LoadingIndicator(
                          indicatorType: Indicator.ballPulse,
                          colors: [
                            Color.fromARGB(255, 54, 120, 244),
                            Color.fromARGB(255, 34, 74, 255),
                            Colors.cyan
                          ],
                        ),
                      ),
                    );
                  case ConnectionState.active:
                  case ConnectionState.done:
                    final data = snapshot.data?.docs;
                    _list = data
                            ?.map(
                              (e) => ChatUser.fromJson(
                                e.data(),
                              ),
                            )
                            .toList() ??
                        [];
                    if (_list.isNotEmpty) {
                      return ListView.builder(
                        itemCount:
                            _issearching ? _searchlist.length : _list.length,
                        itemBuilder: (context, index) {
                          final user =
                              _issearching ? _searchlist[index] : _list[index];
                          return CarduserInvite(
                            user: user,
                            showStatus: true, // Show status
                            onRemove: () => _removeUser(user),
                          );
                        },
                      );
                    } else {
                      return Center(
                          child: Text(
                        'No connection found',
                        style: GoogleFonts.poppins(fontSize: 25),
                      ));
                    }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
