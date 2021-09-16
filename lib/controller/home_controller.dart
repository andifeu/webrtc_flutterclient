import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/models/Message.dart';
import 'package:webrtc_client/services/auth_service.dart';
import 'package:webrtc_client/services/database_service.dart';
import 'package:webrtc_client/services/message_service.dart';

class HomeController {

  final AuthService _auth = AuthService();

  MessageService _messageService;
  DatabaseService _database;

  User _firebaseUser;
  AppUser user;
  List<AppUser> users = [];

  Function setState;
  State _viewState;

  HomeController(this._viewState, this.setState);

  void onInit() {
    this._firebaseUser = _auth.getCurrentUser();

    if (this._firebaseUser != null) {
      this._database = DatabaseService(this._firebaseUser.uid);
      this._database.getUser(this._firebaseUser.uid).then((user) {
        this.setState(() {
          this.user = user;
        });
      });
      _handleMessages(this._firebaseUser.uid);
      this._database.updateUserPresence(() {
        _updateUserList();
      });
    }
  }


  void logout() {
    this._database.setOffline();
    this._database.deleteData();
    _auth.deleteAuthUser();
  }


  void closeApp() {
    this._database.setOffline();
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }


  void callGroup(List<AppUser> usersToCall) async {
    String roomId;

    usersToCall.add(this.user);
    roomId = await this._database.createCall(usersToCall);
    usersToCall.forEach((AppUser user) {
      if (user.uid != this.user.uid) {
        this._messageService.requestCall(user.uid, roomId);
      }
    });

    Navigator.pushNamed(this._viewState.context, '/call', arguments: {
      'room_id': roomId,
      'user': this.user,
      'database': this._database,
      'message': this._messageService
    });
  }

  void callUser(AppUser userToCall) async {
    String roomId;

    roomId = await this._database.createCall([userToCall, this.user]);
    this._messageService.requestCall(userToCall.uid, roomId);
    Navigator.pushNamed(this._viewState.context, '/call', arguments: {
      'room_id': roomId,
      'user': this.user,
      'database': this._database,
      'message': this._messageService
    });
  }


  void _handleMessages(String uid) {
    this._messageService = MessageService(
      uid,
      onMessageReceived: (Message msg) {
        switch (msg.type) {
          case Message.TYPE_CALL_REQUEST:
            if (msg.data == null || msg.data['room_id'] == null) {
              // error
              print('################# err');
              print(msg.data);
              return;
            }

            Navigator.pushNamed(this._viewState.context, '/call', arguments: {
              'user': this.user,
              'room_id': msg.data['room_id']
            });
            break;
        }
      }
    );
  }


  void _updateUserList() {
    this._database.getUsers().then((users) {
      if (!this._viewState.mounted) {
        return;
      }
      this.setState(() {
        this.users = users;
      });
    });
  }

}