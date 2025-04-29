import 'package:flutter/material.dart';

class AppRouter {
  static void close(BuildContext context, {String? callback}) => Navigator.pop(context, callback);

  static void go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  static void open(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (Route<dynamic> route) => false,
    );
  }
}
