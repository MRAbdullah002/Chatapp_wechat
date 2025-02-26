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
  bool _isInitialized = false; // Prevents multiple initializations

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
  }

  void _initializeData() {
    APIs.updateActiveStatus(true);

    // Listen to app lifecycle changes for updating online status
    SystemChannels.lifecycle.setMessageHandler((message) {

    if(APIs.auth.currentUser!=null){
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

  // Search function
  void _searchUsers(String query) {
    setState(() {
      _searchlist = _list
          .where((user) =>
              user.name!.toLowerCase().contains(query.toLowerCase()) ||
              user.email!.toLowerCase().contains(query.toLowerCase()))
          .toList();
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
            leading: IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                Navigator.pop(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            title: _issearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Search Name or Email...'),
                    autofocus: true,
                    onChanged: (value) => _searchUsers(value),
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
                    MaterialPageRoute(builder: (context) => const FriendRequestsScreen()),
                  );
                },
                icon: const Icon(Icons.read_more),
              ),
            ],
          ),
          body: Column(
            children: [
              const Divider(thickness: 2, height: 3),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshUsers,
                  child: StreamBuilder(
                    stream: APIs.getAllUser(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerEffect();
                      }
                  
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                  
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildNoUsersFound();
                      }
                  
                      _list = snapshot.data!.docs
                          .map((e) => ChatUser.fromJson(e.data()))
                          .toList();
                  
                      final displayList = _issearching ? _searchlist : _list;
                  
                      if (displayList.isEmpty) {
                        return _buildNoUsersFound();
                      }
                  
                      return ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final user = displayList[index];
                          return CarduserInvite(
                            user: user,
                            showStatus: true,
                            onRemove: () => _removeUser(user),
                            status: '',
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _refreshUsers() async {
  setState(() {
    _list.clear();
    _searchlist.clear();
  });

  // Fetch the latest data from Firestore
  await Future.delayed(const Duration(seconds: 1)); // Simulating network delay
}


  void _removeUser(ChatUser user) {
    setState(() {
      _list.remove(user);
      _searchlist.remove(user);
    });
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 16,
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

  Widget _buildNoUsersFound() {
    return Center(
      child: Text(
        'No users found',
        style: GoogleFonts.poppins(fontSize: 22),
      ),
    );
  }
}
