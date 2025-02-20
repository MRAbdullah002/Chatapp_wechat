import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/my_date.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.message,
  });
  final MessageUser message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    return APIs.user.uid == widget.message.formID
        ? blueMessage()
        : greenMessage();
  }

  Widget blueMessage() {
    final mq=MediaQuery.of(context).size;
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
            padding:  EdgeInsets.all(widget.message.type == Type.image? mq.width*.03: mq.width*.04),
            decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                border: Border.all(color: Colors.blue)),
            child: widget.message.type == Type.text
                ? Text(widget.message.msg.toString())
                : GestureDetector(
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
                    onLongPress: (){

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
                  ),
          ),
        ),
      ],
    );
  }

  Widget greenMessage() {
    if (widget.message.read!.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }
    final mq=MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding:   EdgeInsets.all(widget.message.type == Type.image? mq.width*.03: mq.width*.04),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 221, 247, 222),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border.all(color: Colors.green)),
            child: widget.message.type == Type.text
                ? Text(widget.message.msg.toString())
                : GestureDetector(
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
                  ),
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
              ? CachedNetworkImageProvider(imagePath) // Load from network
              : FileImage(File(imagePath)), // Load from file
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}
