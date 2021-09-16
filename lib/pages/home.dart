import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webrtc_client/controller/home_controller.dart';

class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  HomeController _controller;

  @override
  bool get mounted => super.mounted;


  @override
  void initState() {
    this._controller = HomeController(this, setState);
    // WidgetsBinding.instance.addObserver(this);
    this._controller.onInit();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // WidgetsBinding.instance.removeObserver(this);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //
  //   // switch (state) {
  //   //   case AppLifecycleState
  //   // }
  //
  //   print('Life circle state:' + state.toString());
  //
  //   switch (state) {
  //     // case AppLifecycleState.resumed:
  //     // case AppLifecycleState.inactive:
  //     //   print('online');
  //     //   break;
  //     // case AppLifecycleState.paused:
  //     case AppLifecycleState.detached:
  //       print('offline');
  //       this._database.setOffline();
  //       break;
  //   }
  //
  //   // if (state == AppLifecycleState.resumed) {
  //     // chatRepository.setPresence(true);
  //   // } else {
  //   //   chatRepository.setPresence(false);
  //   // }
  // }


  @override
  Widget build(BuildContext context) {

    String name = this._controller.user != null ? this._controller.user.name : '';

    return WillPopScope(
      onWillPop: this._onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                this._controller.logout();
              },
              icon: Icon(Icons.person),
              label: Text('logout'),
            )
          ],
        ),
        body: ListView.separated(
          // itemCount: this._users.length,
          itemCount: this._controller.users.length,
          itemBuilder: (context, index) {
            String subtitle = 'Online';
            DateTime lastSeen;

            if (this._controller.users[index].online == false) {
              subtitle = 'Offline';
              if (this._controller.users[index].lastSeen != null && this._controller.users[index].lastSeen > 0) {
                lastSeen = DateTime.fromMillisecondsSinceEpoch(this._controller.users[index].lastSeen);
                subtitle += ' - ' + DateFormat.yMMMd().format(lastSeen);
              }
            }

            return ListTile(
              leading: Icon(
                Icons.call,
                color: Colors.green,
                size: 40
              ),
              title: Text(this._controller.users[index].name),
              subtitle: Text(subtitle),
              onTap: () async {
                // this._controller.callGroup(this._controller.users);
                this._controller.callUser(this._controller.users[index]);
              },
            );
          },
          separatorBuilder: (context, index) {
            return Divider(
              color: Colors.black
            );
          }
        )
      )
    );
  }

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you want to exit an App'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              this._controller.closeApp();
            },
            child: Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }



}

