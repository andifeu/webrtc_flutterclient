import 'package:flutter/material.dart';
import 'package:webrtc_client/controller/call_controller.dart';
import 'package:webrtc_client/models/RTCUser.dart';
import 'package:webrtc_client/widgets/video_view_layout.dart';

class Call extends StatefulWidget {
  @override
  _CallState createState() => _CallState();
}

class _CallState extends State<Call> {

  CallController _controller;

  @override
  bool get mounted => super.mounted;

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    this._controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (this._controller == null) {
      this._controller = CallController(this, setState);
      this._controller.initialize();
    }
  }


  Widget getLayout(Orientation orientation) {

    List<Widget> videoViews = getWidgets(this._controller.rtcUsers);
    return Stack(
      children: [
        // getGroupLayout(videoViews, orientation),
        VideoViewLayout(
          children: videoViews,
          orientation: orientation
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            child: CircleAvatar(
              backgroundColor: Colors.red,
              radius: 30,
              child: IconButton(
                icon: Icon(Icons.call_end),
                color: Colors.white,
                onPressed: () {
                  this._controller.endCall();
                  this._controller.leaveRoom();
                }
              )
            ),
            padding: EdgeInsets.all(10),
          ),
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {

    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    return WillPopScope(
      onWillPop: this._onBackPressed,
      child: Scaffold(
        body: OrientationBuilder(builder: (_, orientation) {
          return getLayout(orientation);
        }),
        // body: getLayout(Orientation.landscape)
      ),
    );


  }


  List<Widget> getWidgets(List<RTCUser> rtcUsers) {
    Color color;
    List colors = [
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.red
    ];

    int i = 0, j = 0;
    List<Widget> widgets = [];

    for (i = 0; i < rtcUsers.length; i++) {
      if (j > colors.length - 1) {
        j = 0;
      }
      // color = colors[j];
      color = Colors.black;

      rtcUsers[i].videoView = this._controller.rtcService.createRTCVideoView(rtcUsers[i].renderer);
      print('################## built videoview for ${rtcUsers[i].name}');

      widgets.add(
        Expanded(
          child: Container(
            key: new Key('member_' + i.toString()),
            // margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
            decoration: new BoxDecoration(color: color),
            child: rtcUsers[i].videoView
            // child: Center(
            //   child: Text('member_' + i.toString()),
            // )
          ),
          // child: this._controller.rtcService.createRTCVideoView(rtcUsers[i].renderer),
          // key: new Key('member_' + i.toString()),
          flex: 1,
        )
      );

      j++;
    }


    return widgets;
  }

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave call?'),
        content: Text('Do you want leave the call?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              this._controller.endCall();
              this._controller.leaveRoom();
            },
            child: Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

}
