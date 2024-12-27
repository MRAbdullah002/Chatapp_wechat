import 'package:flutter/material.dart';

class MyDateUtil{

  static String getFormattedTime({required BuildContext context,required String time}){
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);


  }
  static String getLastMessagetime({required BuildContext context,required String time}){
    final DateTime senttime = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now=DateTime.now();
    if (senttime.day==now.day&&senttime.month==now.month&&senttime.year==now.year) {
      return TimeOfDay.fromDateTime(senttime).format(context);

    }
    return '${senttime.day} ${_getmonth(senttime)}'; 
  }
  static String _getmonth(DateTime date){
    switch (date.month) {
      case 1:
      return  'Jan';
        case 2:
      return  'Feb';
        case 3:
      return  'Mar';
        case 4:
      return  'Apr';
        case 5:
      return  'May';
        case 6:
      return  'Jun';
        case 7:
      return  'Jul';
        case 8:
      return  'Aug';
        case 9:
      return  'Sep';
        case 10:
      return  'Oct';
        case 11:
      return  'Nov';
        case 12:
      return  'Dec';
        
        
      
    }
    return'N/A';

 }
static String getLastActiveTime({required BuildContext context, required String last_seen}) {
  final int i = int.tryParse(last_seen) ?? -1;
  
  if (i == -1) return 'Last seen is not available';
  
  DateTime now = DateTime.now();
  DateTime time = DateTime.fromMillisecondsSinceEpoch(i);

  
  print("Now: $now");
  print("Last Seen: $time");

  String formattedTime = TimeOfDay.fromDateTime(time).format(context);

 
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return 'Last seen at $formattedTime';
  }

 
  if (now.difference(time).inDays == 1) {
    return 'Last seen yesterday at $formattedTime';
  }

 
  String month = _getmonth(time);
  return 'Last seen on ${time.day} $month at $formattedTime';
}

 }

