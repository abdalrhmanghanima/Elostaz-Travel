import 'package:flutter/material.dart';

import '../../main.dart';

class NavigatorHandler {
  static Future<dynamic> push(Widget page) async {
    return await Navigator.of(navigatorKey.currentContext!)
        .push(MaterialPageRoute(builder: (_) => page));
  }

  static Future<dynamic> pushReplacement(Widget page) async {
    return await Navigator.of(navigatorKey.currentContext!)
        .pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  static  Future<dynamic> pushAndRemoveUntil(Widget page) async{
    return await Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (route) => false);
  }

  static dynamic pop([Object? result]) {
    Navigator.of(navigatorKey.currentContext!).pop(result);
  }
}