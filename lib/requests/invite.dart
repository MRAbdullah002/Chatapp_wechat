import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/cardofinvite.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/requests/accept.dart';
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
  List<ChatUser> _list = []; // All users
  List<ChatUser> _searchlist = []; // Filtered search results
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

  // Local search function (Filters _list)
  void _searchUsers(String query) {
    query = query.toLowerCase();

    setState(() {
      _searchlist = _list
          .where((user) =>
              user.name!.toLowerCase().contains(query) || user.email!.toLowerCase().contains(query))
          .toList();
    });
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
        onWillPop: () async {
          if (_issearching) {
            setState(() {
              _issearching = false;
              _searchlist.clear();
            });
            return false;
          }
          return true;
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
                        border: InputBorder.none, hintText: 'Search Name or Email...'),
                    autofocus: true,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _searchUsers(value);
                      } else {
                        setState(() {
                          _issearching = false;
                          _searchlist.clear();
                        });
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
              stream: APIs.getAllUser(),
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
                    _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

                    // If searching, use _searchlist; otherwise, use _list
                    final displayList = _issearching ? _searchlist : _list;

                    if (displayList.isNotEmpty) {
                      return ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final user = displayList[index];
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
                          'No users found',
                          style: GoogleFonts.poppins(fontSize: 22),
                        ),
                      );
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
