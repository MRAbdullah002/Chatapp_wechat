import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/my_date.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.message, required this.chatUser,
  });
  final MessageUser message;
  final ChatUser chatUser;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
void showDeleteDialog(MessageUser message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              APIs.deleteMessage(message,widget.chatUser.id.toString());
 // Pass message and chat ID
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  return GestureDetector(
  
      onLongPress: () {
        if (APIs.user.uid == widget.message.formID) {
          showDeleteDialog(widget.message);
        }
      },
    child: APIs.user.uid == widget.message.formID
        ? blueMessage()
        : greenMessage(),
  );
}


  Widget blueMessage() {
    final mq = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.message.read!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Icon(
                  Icons.done_all_outlined,
                  color: Colors.blue,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: widget.message.sent.toString()),
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: EdgeInsets.all(mq.width * .04),
            decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                border: Border.all(color: Colors.blue)),
            child: _buildMessageContent(),
          ),
        ),
      ],
    );
  }

  Widget greenMessage() {
    if (widget.message.read!.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }
    final mq = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: EdgeInsets.all(mq.width * .04),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 221, 247, 222),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border.all(color: Colors.green)),
            child: _buildMessageContent(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent.toString()),
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    if (widget.message.type == Type.text) {
      return Text(widget.message.msg.toString());
    } else if (widget.message.type == Type.image) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageView(
                imagePath: widget.message.msg.toString(),
                isNetworkImage: true,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: widget.message.msg.toString(),
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
                const Icon(Icons.image, size: 70),
          ),
        ),
      );
    } else if (widget.message.type == Type.video) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenVideoView(
                videoPath: widget.message.msg.toString(),
                isNetworkVideo: true,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 150,
                width: 200,
                color: Colors.black12,
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  final bool isNetworkImage;

  const FullScreenImageView(
      {super.key, required this.imagePath, this.isNetworkImage = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: PhotoView(
          imageProvider: isNetworkImage
              ? CachedNetworkImageProvider(imagePath)
              : FileImage(File(imagePath)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class FullScreenVideoView extends StatefulWidget {
  final String videoPath;
  final bool isNetworkVideo;

  const FullScreenVideoView({
    super.key,
    required this.videoPath,
    this.isNetworkVideo = false,
  });

  @override
  State<FullScreenVideoView> createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<FullScreenVideoView> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _enterFullScreen();
  }

  Future<void> _initializePlayer() async {
    _videoController = widget.isNetworkVideo
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));

    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      allowPlaybackSpeedChanging: true,
      allowFullScreen: true,
      allowMuting: true,
      showControlsOnInitialize: true,
    );

    setState(() {});
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _exitFullScreen();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

