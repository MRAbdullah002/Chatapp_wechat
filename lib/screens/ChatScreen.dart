import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/message_.dart';
import 'package:chatting_application/helper/my_date.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/model/messageUser.dart';
import 'package:chatting_application/screens/myhomepage.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Chatscreen extends StatefulWidget {
  const Chatscreen({super.key, required this.user});
  final ChatUser user;

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  List<MessageUser> _list = [];
  final textcontroller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _emojishow = false;
@override
@override
void initState() {
  super.initState();
  
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark, 
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        // ignore: deprecated_member_use
        child: WillPopScope(
          onWillPop: () {
            if (_emojishow) {
              setState(() {
                _emojishow = !_emojishow;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 207, 231, 250),
            appBar: AppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding:  EdgeInsets.only(top: mq.height*.03),
                child: _appbar(),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllmsg(widget.user),
                    // ignore: non_constant_identifier_names
                    builder: (context, Snapshot) {
                      // Handle the different states for the StreamBuilder
                      if (Snapshot.connectionState == ConnectionState.waiting || Snapshot.connectionState == ConnectionState.none) {
                        return const Center(child:  CircularProgressIndicator());
                      }

                      if (Snapshot.connectionState == ConnectionState.active || Snapshot.connectionState == ConnectionState.done) {
                        final data = Snapshot.data?.docs;

                        if (data == null || data.isEmpty) {
                          return Center(
                            child: Text(
                              'Say hii......',
                              style: GoogleFonts.poppins(fontSize: 26),
                            ),
                          );
                        }

                        _list = data.map((e) {
                          var messageData = e.data() as Map<String, dynamic>;
                          return MessageUser.fromJson(messageData);
                        }).toList();

                        _list = _list.toList();

                       
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(_scrollController));

                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: _list.length,
                          padding: EdgeInsets.only(top: mq.height * .01),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return MessageCard(message: _list[index]);
                          },
                        );
                      }

                      return Center(child: Text('No messages found.', style: GoogleFonts.poppins(fontSize: 26)));
                    },
                  ),
                ),
                _inputrow(),
                if (_emojishow)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: textcontroller,
                      onBackspacePressed: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }



Widget _appbar() {
  final mq = MediaQuery.of(context).size; // Get screen size
  const minProfileSize = 50.0; // Minimum size to prevent shrinking on high DPI screens

  return InkWell(
    onTap: () {},
    child: StreamBuilder(
      stream: APIs.getUserinfo(widget.user),
      builder: (context, snapshot) {
        final data = snapshot.data?.docs;
        final _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
        final user = _list.isNotEmpty ? _list[0] : widget.user; // Use latest user data
      
        return Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyHomePage()),
                );
              },
              icon: Icon(Icons.arrow_back, size: max(mq.width * 0.06, 22)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(mq.height * 0.5),
              child: CachedNetworkImage(
                width: max(mq.height * 0.05, minProfileSize), // Adaptive size
                height: max(mq.height * 0.05, minProfileSize),
                imageUrl: user.image.toString(),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: max(mq.height * 0.035, minProfileSize / 2),
                  child: const Icon(CupertinoIcons.person),
                ),
              ),
            ),
            SizedBox(width: max(mq.width * 0.02, 6)), // Ensures minimum spacing
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox( // Auto-scales text size
                  fit: BoxFit.scaleDown,
                  child: Text(
                    user.name.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: max(mq.width * 0.04, 14), // Minimum font size
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    
                  ),
                ),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    user.status == true
                        ? 'Online'
                        : MyDateUtil.getLastActiveTime(
                            context: context,
                            last_seen: user.lastSeen.toString(),
                          ),
                    style: GoogleFonts.poppins(
                      fontSize: max(mq.width * 0.035, 12), // Adaptive size
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                    
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}




  Widget _inputrow() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              elevation: 1,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _emojishow = !_emojishow;
                      });
                    },
                    icon: const Icon(
                      Icons.emoji_emotions,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: textcontroller,
                      onChanged: (value) {
                        print('data $value');
                      },
                      onTap: () {
                        setState(() {
                          if (_emojishow) _emojishow = !_emojishow;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.image,
                      color: Colors.blueAccent,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              if (textcontroller.text.isNotEmpty) {
                APIs.sendMessage(widget.user, textcontroller.text);
                textcontroller.clear();
                _scrollToBottom(_scrollController);
              } else {
                print('error');
              }
            },
            shape: const CircleBorder(),
            minWidth: 0,
            color: Colors.greenAccent,
            padding: const EdgeInsets.all(13),
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.jumpTo(controller.position.minScrollExtent);
      }
    });
  }
}
