import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/screens/ChatScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CarduserInvite extends StatefulWidget {
  const CarduserInvite({
    super.key,
    required this.user,
    required this.showStatus,
    required this.onRemove,
  });

  final ChatUser user;
  final bool showStatus;
  final VoidCallback onRemove;

  @override
  State<CarduserInvite> createState() => _CarduserInviteState();
}

class _CarduserInviteState extends State<CarduserInvite> {
  String _requestStatus = 'none'; // none, pending, accepted, rejected

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  // Check the status of the friend request
  Future<void> _checkRequestStatus() async {
    final outgoingSnapshot = await APIs.firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: APIs.user.uid)
        .where('recipientId', isEqualTo: widget.user.id)
        .get();

    final incomingSnapshot = await APIs.firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: widget.user.id)
        .where('recipientId', isEqualTo: APIs.user.uid)
        .get();

    if (outgoingSnapshot.docs.isNotEmpty) {
      setState(() {
        _requestStatus = outgoingSnapshot.docs.first['status'];
      });
    } else if (incomingSnapshot.docs.isNotEmpty) {
      setState(() {
        _requestStatus = incomingSnapshot.docs.first['status'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: () {
            // Handle tapping on the card (e.g., navigate to user profile)
          },
          child: ListTile(
            title: Text(widget.user.name ?? 'Unknown User'),
            subtitle: Text(widget.user.about ?? "No status available"),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(mq.height * .3),
              child: CachedNetworkImage(
                width: mq.height * .055,
                height: mq.height * .055,
                imageUrl: widget.user.image ?? '',
                errorWidget: (context, url, error) => const CircleAvatar(
                  child: Icon(CupertinoIcons.person),
                ),
              ),
            ),
            trailing: _buildTrailingButtons(),
          ),
        ),
      ),
    );
  }

  // Build the trailing buttons based on the request status
  Widget _buildTrailingButtons() {
    final mq = MediaQuery.of(context).size;

    switch (_requestStatus) {
      case 'pending':
        return const Icon(Icons.access_time, color: Colors.orange);
      case 'accepted':
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.lightBlueAccent,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Message", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chatscreen(user: widget.user),
              ),
            );
          },
        );
      case 'rejected':
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: _removeCard,
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Request Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Request', style: TextStyle(color: Colors.white)),
              onPressed: _sendFriendRequest,
            ),
            const SizedBox(width: 5),
            // Reject Button
            IconButton(
              icon: Container(
                height: mq.height * .031,
                width: mq.width * .099,
                decoration: BoxDecoration(
                  color: Colors.red[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: Colors.black),
              ),
              onPressed: _removeCard,
            ),
          ],
        );
    }
  }

  // Send a friend request
  Future<void> _sendFriendRequest() async {
    setState(() {
      _requestStatus = 'pending';
    });

    try {
      await APIs.sendFriendRequest(widget.user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${widget.user.name}')),
      );
    } catch (e) {
      setState(() {
        _requestStatus = 'none';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send friend request: $e')),
      );
    }
  }

  // Accept a friend request
 

  // Remove the card when a request is rejected
  void _removeCard() {
    widget.onRemove();
  }
}
