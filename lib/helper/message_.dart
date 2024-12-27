import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/my_date.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                MyDateUtil.getFormattedTime(context: context, time: widget.message.sent.toString()),
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                border: Border.all(color: Colors.blue)),
            child: Text(widget.message.msg.toString()),
          ),
        ),
      ],
    );
  }

  Widget greenMessage() {
     if(widget.message.read!.isEmpty){
      APIs.updateMessageReadStatus(widget.message);
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 221, 247, 222),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border.all(color: Colors.green)),
            child: Text(widget.message.msg.toString()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Text(
           MyDateUtil.getFormattedTime(context: context, time: widget.message.sent.toString()),
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
