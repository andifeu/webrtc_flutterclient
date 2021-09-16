import 'package:flutter/material.dart';
import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/services/auth_service.dart';
import 'package:webrtc_client/services/database_service.dart';

class Auth extends StatefulWidget {

  final String nameFieldLabel = 'Name';

  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: widget.nameFieldLabel
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return '"' + widget.nameFieldLabel + '" muss befüllt sein.';
                  }

                  if (value.length < 3) {
                    return 'Der Name sollte mindestens Zeichen lang sein.';
                  }

                  return null;
                },
                onChanged: (val) {
                  username = val;
                }
              ),
              ElevatedButton(
                child: Text('Login'),
                onPressed: () async {
                  if (!_formKey.currentState.validate()) {
                    return;
                  }

                  await _auth.signInAnon(username);
                  // if (user.uid == null) {
                  //   print('ERROR: Login failed');
                  //   return;
                  // }

                }
              )
            ],
          ),
        )
      )
    );
  }
}
