import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/model/Inviteuser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FriendRequestCard extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback onRemove;
  final Function(String friendId) onMessage; // Callback for message navigation

  const FriendRequestCard({
    super.key,
    required this.request,
    required this.onRemove,
    required this.onMessage,
  });

  @override
  State<FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<FriendRequestCard> {
  String _requestStatus = 'pending'; // pending, accepted, rejected
  bool _isLoading = true; // To track if the status is being fetched

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  // Check request status from Firestore
  // Check request status from Firestore
Future<void> _checkRequestStatus() async {
  final snapshot = await APIs.firestore
      .collection('friendRequests')
      .where('senderId', isEqualTo: widget.request.senderId)
      .where('recipientId', isEqualTo: APIs.user.uid)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final requestStatus = snapshot.docs.first['status'];

    // ✅ Check if user has already updated their request
    bool alreadyUpdated = await APIs.hasUserUpdatedRequest(widget.request.senderId);

    setState(() {
      _requestStatus = alreadyUpdated ? requestStatus : 'pending';
      _isLoading = false;
    });
  } else {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    
    return Card(
      color: Colors.grey[200],
      
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        
        title: _isLoading
            ? _buildShimmerEffect(width: 150, height: 16) // Shimmer for title
            : Text("Friend Request from ${widget.request.senderName}"),
        subtitle: _isLoading
            ? _buildShimmerEffect(width: 200, height: 12) // Shimmer for subtitle
            : const Text("Accept or decline the invitation"),
        trailing: _isLoading
            ? _buildShimmerEffect(width: 100, height: 40) // Shimmer for trailing buttons
            : _buildTrailingButtons(),
      ),
    );
  }

  // Build trailing UI based on request status
  Widget _buildTrailingButtons() {
    if (_requestStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () => widget.onMessage(widget.request.senderId),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message, color: Colors.white),
              SizedBox(width: 5),
              Text("Message", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: _acceptFriendRequest,
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: _declineFriendRequest,
        ),
      ],
    );
  }

  // Shimmer effect widget
  Widget _buildShimmerEffect({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Base color
      highlightColor: Colors.grey[100]!, // Highlight color
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Accept the friend request
  Future<void> _acceptFriendRequest() async {
    try {
      // Fetch the request document
      final snapshot = await APIs.firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: widget.request.senderId)
          .where('recipientId', isEqualTo: APIs.user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final requestId = snapshot.docs.first.id;

        // Update status to accepted
        await APIs.firestore.collection('friendRequests').doc(requestId).update({
          'status': 'accepted',
        });

        // Add each other as friends
        await APIs.firestore.collection('users').doc(APIs.user.uid).update({
          'friends': FieldValue.arrayUnion([widget.request.senderId]),
        });

        await APIs.firestore.collection('users').doc(widget.request.senderId).update({
          'friends': FieldValue.arrayUnion([APIs.user.uid]),
        });

        // Now remove the reverse friend request (if it exists)
        final reverseRequest = await APIs.firestore
            .collection('friendRequests')
            .where('senderId', isEqualTo: APIs.user.uid)
            .where('recipientId', isEqualTo: widget.request.senderId)
            .get();

        if (reverseRequest.docs.isNotEmpty) {
          await APIs.firestore.collection('friendRequests').doc(reverseRequest.docs.first.id).delete();
        }

        setState(() {
          _requestStatus = 'accepted';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are now friends with ${widget.request.senderName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }
  

  Future<void> _declineFriendRequest() async {
    try {
      final snapshot = await APIs.firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: widget.request.senderId)
          .where('recipientId', isEqualTo: APIs.user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final requestId = snapshot.docs.first.id;

        // Remove the friend request from Firestore
        await APIs.firestore.collection('friendRequests').doc(requestId).delete();

        setState(() {
          _requestStatus = 'request'; // Reset UI to allow new requests
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request declined from ${widget.request.senderName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining request: $e')),
      );
    }
  }
}