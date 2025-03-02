import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/screens/veiw_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class ProfileDialogue extends StatelessWidget {
  const ProfileDialogue({super.key, required this.user});
  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    // ignore: deprecated_member_use
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      backgroundColor: Colors.white.withOpacity(.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .1),
                child: CachedNetworkImage(
                  width: mq.height * .2,
                  height: mq.height * .2,
                  fit: BoxFit.cover,
                  imageUrl: user.image.toString(),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    child: Icon(CupertinoIcons.person),
                  ),
                ),
              ),
            ),
            Positioned(
                left: mq.width * .05,
                top: mq.height * .02,
                width: mq.width * .55,
                child: Text(user.name.toString(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500))),
            Positioned(
              right: 8,
              top: 4,
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.fade,
                            child: ViewProfileScreen(user: user)));
                  },
                  icon: const Icon(
                    Icons.info_outline,
                    size: 30,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
