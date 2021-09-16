import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:webrtc_client/pages/call.dart';
import 'package:webrtc_client/pages/wrapper.dart';
import 'package:webrtc_client/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: AuthService().onAuthStateChanged,
      child: MaterialApp(
        title: 'Simple WebRTC Client',
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => Wrapper(),
          '/call': (context) => Call()
        },
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // home: Wrapper()
      ),
    );
  }
}
