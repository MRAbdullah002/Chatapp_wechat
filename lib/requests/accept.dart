import 'package:chatting_application/api/Api.dart';

import 'package:chatting_application/model/Inviteuser.dart';
import 'package:chatting_application/requests/card_accept.dart';

import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Friend Requests")),
      body: StreamBuilder<List<FriendRequest>>(
        stream: APIs.getFriendInvites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending friend requests"));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return FriendRequestCard(
                request: requests[index],
                onRemove: () => requests.removeAt(index), onMessage: (String friendId) {  },
              );
            },
          );
        },
      ),
    );
  }
}
