import 'package:achievement_view/achievement_view.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';


class Floatingwidget {
  final String title;
  final String subtitle;

  Floatingwidget({required this.title, required this.subtitle});

  showAchievement(BuildContext context) {
    AchievementView(
      title: title,
      subTitle: subtitle,
 
      duration: const Duration(milliseconds: 1500), 
    ).show(context);
  }
}
class Loading {
  static void showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: SizedBox(height:20,width:100 ,child: LoadingIndicator(indicatorType: Indicator.ballPulse,
          colors: [Color.fromARGB(255, 54, 120, 244),Color.fromARGB(255, 34, 74, 255),Colors.cyan],
          ),
          )
          , // You can customize this
        );
      },
    );
  }

  static void hideLoadingIndicator(BuildContext context) {
    Navigator.of(context).pop(); // Dismiss the dialog
  }
}

