import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/dialog/profile_dialogue.dart';
import 'package:chatting_application/helper/my_date.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:chatting_application/screens/ChatScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CarduserChat extends StatefulWidget {
  const CarduserChat({super.key, required this.user, required bool showStatus});
  final ChatUser user;

  @override
  State<CarduserChat> createState() => _CarduserChatState();
}

class _CarduserChatState extends State<CarduserChat> {
  MessageUser? _message;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1),
      child: Card(
        color: Colors.grey[100],
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Chatscreen(user: widget.user),
              ),
            );
          },
          child: StreamBuilder(
            stream: APIs.getAllmsg(widget.user),
            builder: (context, snapshot) {
              // Check if data is available and not null
              final data = snapshot.data?.docs;

              // If no data or empty data, return a basic ListTile
              if (data == null || data.isEmpty) {
                return ListTile(
                  title: Text(widget.user.name ?? 'unknown user'),
                  subtitle: Text(widget.user.about.toString(), maxLines: 1),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image.toString(),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                    ),
                  ),
                  trailing: Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }

              // Process data if available
              final _list = data.map((e) {
                var messageData = e.data() as Map<String, dynamic>;
                return MessageUser.fromJson(messageData);
              }).toList();

              // If the list is not empty, update the message
              if (_list.isNotEmpty) {
                _message = _list[0];
              }

              return ListTile(
                
                title: Text(widget.user.name ?? 'unknown user'),
                subtitle: Text(
                  _message != null
                      ? (_message!.type == Type.image
                          ? 'Image'
                          : (_message!.type == Type.video
                              ? 'Video'
                              : _message!.msg.toString()))
                      : widget.user.about.toString(),
                  maxLines: 1,
                ),
                leading: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ProfileDialogue(user: widget.user),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image.toString(),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                    ),
                  ),
                ),
                trailing: _message == null
                    ? null
                    : _message!.read!.isEmpty &&
                            _message!.formID != APIs.user.uid
                        ? Container(
                            height: 15,
                            width: 15,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                        : Text(MyDateUtil.getLastMessagetime(
                            context: context, time: _message!.sent.toString())),
              );
            },
          ),
        ),
      ),
    );
  }
}
