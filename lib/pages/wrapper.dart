import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:webrtc_client/pages/auth.dart';
import 'package:webrtc_client/pages/home.dart';

class Wrapper extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<User>(context);

    if (user == null) {
      return Auth();
    } else {
      return Home();
    }
  }
}
