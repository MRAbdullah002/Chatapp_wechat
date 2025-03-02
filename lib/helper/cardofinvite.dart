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
    required this.status,
    required this.showProfilePicture,
  });

  final ChatUser user;
  final bool showStatus;
  final VoidCallback onRemove;
  final String status;
  final bool showProfilePicture;

  @override
  State<CarduserInvite> createState() => _CarduserInviteState();
}

class _CarduserInviteState extends State<CarduserInvite> {
  String _requestStatus = 'none'; // none, pending, accepted, rejected
  bool _isLoading = true; // Indicates if status is being fetched

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  // Check the status of the friend request
  Future<void> _checkRequestStatus() async {
    try {
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
        _requestStatus = outgoingSnapshot.docs.first['status'];
      } else if (incomingSnapshot.docs.isNotEmpty) {
        _requestStatus = incomingSnapshot.docs.first['status'];
      } else {
        _requestStatus = 'none';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking request status: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Status has been fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1),
      child: Card(
        color: Colors.grey[100],
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          title: Text(widget.user.name ?? 'Unknown User',maxLines: 1,),
          subtitle: Text(widget.user.about ?? "No status available",maxLines: 1,),
          leading: widget.showProfilePicture
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl: widget.user.image ?? '',
                    errorWidget: (context, url, error) => const CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                )
              : const CircleAvatar(
                  child: Icon(CupertinoIcons.person),
                ),
          trailing: _isLoading ? _buildLoadingIndicator() : _buildTrailingButtons(),
        ),
      ),
    );
  }

  // Show loading indicator while checking request status
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  // Build the trailing buttons based on the request status
  // Build the trailing buttons based on the request status
Widget _buildTrailingButtons() {
  final mq = MediaQuery.of(context).size; // Get screen size

  switch (_requestStatus) {
    case 'pending':
      return const Icon(Icons.access_time, color: Colors.orange);
    case 'accepted':
      return SizedBox(
        width: mq.width * 0.4, // 40% of screen width
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, // Align to the end
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * 0.02, // 2% of screen width
                  vertical: mq.height * 0.01, // 1% of screen height
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Message",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mq.width * 0.03, // 3% of screen width
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Chatscreen(user: widget.user),
                  ),
                );
              },
            ),
            SizedBox(width: mq.width * 0.02), // 2% of screen width
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * 0.02, // 2% of screen width
                  vertical: mq.height * 0.01, // 1% of screen height
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Remove",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mq.width * 0.03, // 3% of screen width
                ),
              ),
              onPressed: _removeFriend,
            ),
          ],
        ),
      );
    case 'rejected':
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.red),
        onPressed: _removeCard,
      );
    default:
      return SizedBox(
        width: mq.width * 0.4, // 40% of screen width
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, // Align to the end
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            // Request Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * 0.02, // 2% of screen width
                  vertical: mq.height * 0.01, // 1% of screen height
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _sendFriendRequest,
              child: Text(
                'Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mq.width * 0.03, // 3% of screen width
                ),
              ),
            ),
            SizedBox(width: mq.width * 0.02), // 2% of screen width
            // Reject Button
            IconButton(
              icon: Container(
                height: mq.height * 0.04, // 4% of screen height
                width: mq.width * 0.08, // 8% of screen width
                decoration: BoxDecoration(
                  color: Colors.red[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.black,
                  size: mq.width * 0.04, // 4% of screen width
                ),
              ),
              onPressed: _removeCard,
            ),
          ],
        ),
      );
  }
}

  // Send a friend request
  Future<void> _sendFriendRequest() async {
    try {
      setState(() {
        _requestStatus = 'pending';
      });

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

  // Remove the card when a request is rejected
  void _removeCard() {
    widget.onRemove();
  }

  // Remove a friend
  Future<void> _removeFriend() async {
    try {
      await APIs.removeFriend(widget.user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.user.name} removed from friends')),
      );
      setState(() {
        _requestStatus = 'none';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }
  
}