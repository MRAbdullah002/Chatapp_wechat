import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/cardofinvite.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/requests/accept.dart';
import 'package:chatting_application/screens/myhomepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

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
    APIs.getAllUser();

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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            scrolledUnderElevation: 0,
            leading:IconButton(

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
          body: Column(
            children: [
              const Divider(
                thickness: 2,
                height: 3,
              ),
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllUser(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        // Show shimmer effect while loading
                        return _buildShimmerEffect();
                
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
                
                        // If searching, use _searchlist; otherwise, use _list
                        final displayList = _issearching ? _searchlist : _list;
                
                        if (displayList.isNotEmpty) {
                          return SingleChildScrollView(
                            child: ListView.builder(
                              shrinkWrap: true,
                              
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final user = displayList[index];
                                return CarduserInvite(
                                  user: user,
                                  showStatus: true, // Show status
                                  onRemove: () => _removeUser(user), status: '',
                                );
                              },
                            ),
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
            ],
          ),
        ),
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
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
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