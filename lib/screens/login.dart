import 'dart:io';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/littlething.dart';
import 'package:chatting_application/screens/myhomepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isanimate = false;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 1000),
      () {
        setState(() {
          _isanimate = true;
        });
      },
    );
  }

  Future<void> _handlegooglesignin() async {
    Loading.showLoadingIndicator(context);

    final user = await _signInWithGoogle();

    if (user != null) {
      Loading.hideLoadingIndicator(context);
      if (await (APIs.userExist())) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MyHomePage(),
          ),
        );
      } else {
        await APIs.createUser().then((value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MyHomePage(),
            ),
          );
        });
      }

      print('\nAdditionalUserInfo: ${user.additionalUserInfo}');
      print('\nUser: ${user.user}');
    }
  }
 

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Check internet connection
      await InternetAddress.lookup('google.com');

      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create Google credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      Floatingwidget(title: 'Success', subtitle: "logged into the account")
          .showAchievement(context);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      Floatingwidget(title: 'ERROR', subtitle: 'Internet not connected')
          .showAchievement(context);
      throw Exception('Failed to sign in with Google');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "We Chat",
          style: GoogleFonts.nunito(
            letterSpacing: 2,
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(
            color: Colors.grey,
            thickness: 1,
            height: 1,
          ),
          Expanded(
            child: Stack(
              children: [
                Container(color: Colors.white),
                AnimatedPositioned(
                  top: mq.height * .15,
                  width: mq.width * .5,
                  right: _isanimate ? mq.width * .25 : -mq.width * .5,
                  duration: const Duration(milliseconds: 1000),
                  child: Image.asset("assets/images/comments.png"),
                ),
                Positioned(
                  bottom: mq.height * .15,
                  width: mq.width * .8,
                  left: mq.width * .1,
                  height: mq.height * .05,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
                    ),
                    onPressed: (){
                      _handlegooglesignin();
                      
                    },
                    label: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black, fontSize: 12),
                        children: [
                          TextSpan(text: "Sign In with "),
                          TextSpan(
                            text: "Google",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    icon: Image.asset(
                      "assets/images/google.png",
                      height: mq.height * .03,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
