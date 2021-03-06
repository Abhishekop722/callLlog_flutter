import 'package:flutter/material.dart';

class Constants {
  //App related strings
  static String appName = "Sales CRM";
  //development
  // static String apiUrl = "192.168.43.97:8083";
  //production
  static String apiUrl = "sales-r.ht-india.com";

  //Colors for theme
  static Color lightPrimary = Color(0xff025dfa);
  static Color lightAccent = Color(0xff597ef7);
  static Color lightBG = Color(0xfff3f4f9);

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColor: lightPrimary,
    accentColor: lightAccent,
    cursorColor: lightAccent,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      textTheme: TextTheme(
        headline6: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  static List sortList = [
    "File name (A to Z)",
    "File name (Z to A)",
    "Date (oldest first)",
    "Date (newest first)",
    "Size (largest first)",
    "Size (Smallest first)",
  ];
}
