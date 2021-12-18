import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'chat.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final pages = [
    PageViewModel(
      pageColor: Colors.black,
     
      body: Text(
        "I'm Skull Face the man who can give you advice about anythings.",
        style: GoogleFonts.marcellus(fontSize: 20, color: Colors.white70),
      ),
      title: Text(
        'Welcome',
        style: GoogleFonts.marcellus(fontSize: 64, color: Color(0xffb49957)),
      ),
      titleTextStyle: TextStyle(fontFamily: 'MyFont', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'MyFont', color: Colors.white),
      mainImage: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              offset: Offset(2, 2),
              spreadRadius: 1,
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              offset: Offset(-2, -2),
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/skull.jpg',
          height: 325.0,
          width: 325.0,
          alignment: Alignment.center,
        ),
      ),
    ),
    PageViewModel(
      pageColor: Color(0xFF181818),
    
      body: Text(
        "If you are ready , please press DONE to talk with me.",
        style: GoogleFonts.marcellus(fontSize: 20, color: Colors.white70),
      ),
      title: Text(
        'Are you ready?',
        style: GoogleFonts.marcellus(fontSize: 50, color: Color(0xffb49957)),
      ),
      titleTextStyle: TextStyle(fontFamily: 'MyFont', color: Colors.white),
      bodyTextStyle: TextStyle(fontFamily: 'MyFont', color: Colors.white),
      mainImage: Container(
      
        child:Icon(CupertinoIcons.chat_bubble_text,color: Colors.white70,size: 200,),
      ),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroViewsFlutter(
        pages,
        showNextButton: true,
        showBackButton: true,
        onTapDoneButton: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Chat()),
          );
        },
        pageButtonTextStyles: GoogleFonts.marcellus(
            fontSize: 20,
            color: const Color(0xffb49957),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
