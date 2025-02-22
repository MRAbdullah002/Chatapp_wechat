
import 'package:chatting_application/screens/root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
 @override
void initState() {
  super.initState();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, 
      systemNavigationBarColor: Colors.white,
    ),
  );
  Future.delayed(
    const Duration(milliseconds: 2000),
    () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "",
          style: GoogleFonts.nunito(
            letterSpacing: 2,
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          
          
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.white,
                ),
                 Positioned(
                  top: mq.height * .20,
                  width: mq.width * .5,
                  
                  right: mq.width * .16,
                  child: Text('We Chat',
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                Positioned(
                  top: mq.height * .35,
                  width: mq.width * .5,
                  right: mq.width * .25,
                  child: Image.asset(
                    "assets/images/wechat.png",
                  ),
                ),
                // Positioned(
                //   bottom: mq.height * .15,
                //   width: mq.width * .8,
                //   left: mq.width * .1,
                //   child: Center(
                //     child: Text(
                //       "Made By OUR Group",
                //       style: GoogleFonts.nunito(
                //         fontSize: 26,
                //         letterSpacing: 2,
                //         fontWeight: FontWeight.w400,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
