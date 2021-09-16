import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:provider/provider.dart';

import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/services/auth_service.dart';
import 'package:webrtc_client/services/database_service.dart';

class Call extends StatefulWidget {

  final String userId;
  // final String userId;
  final AuthService _auth = AuthService();
  //
  DatabaseService db;

  Call({Key key, this.userId}) : super(key: key) {
    // this.db = DatabaseService(uid: user.uid);
    // print('+++++ construct:' + this.user.uid + this.user.name);
    this.db = DatabaseService(this.userId);
    // this.user = AppUser(uid, name);
  }

  @override
  _CallState createState() => _CallState();
}

class _CallState extends State<Call> {

  AppUser _user;

  bool _offer = false;
  RTCPeerConnection _peerConnection;
  MediaStream _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  final sdpController = TextEditingController();

  @override
  dispose() {
    _disconnectRTC();
    super.dispose();
  }

  // @override
  // deactivate() {
  //   super.deactivate();
  //   _localRenderer.dispose();
  //   _remoteRenderer.dispose();
  // }


  void _disconnectRTC() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    sdpController.dispose();
  }

  @override
  void initState() {
    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    // Map<String, dynamic> offer = {
    //   'uid': _user.uid,
    //   'session': session
    // };

    // print('########################### offer');
    // print(json.encode(session));
    debugPrint(json.encode(session), wrapWidth: 1024);
    // print('########################### end');
    _offer = true;


    // saveOffer(json.encode(offer));
    widget.db.saveOffer(session);
    // print(json.encode({
    //       'sdp': description.sdp.toString(),
    //       'type': description.type.toString(),
    //     }));

    _peerConnection.setLocalDescription(description);
  }


  void _createAnswer() async {
    Map<String, String> data = {
      'antwdata': 'awdwadwad',
      'iaddaw': 'dwadaw'
    };
    widget.db.saveAnswer(data);
  }

  void _createAnswer_org() async {
    RTCSessionDescription description = await _peerConnection.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp);


    print('########################### answer');
    // print(json.encode(session));
    debugPrint(json.encode(session), wrapWidth: 1024);
    print('########################### end');

    // saveAnswer(json.encode(answer));
    widget.db.saveAnswer(session);
    // print(json.encode({
    //       'sdp': description.sdp.toString(),
    //       'type': description.type.toString(),
    //     }));

    _peerConnection.setLocalDescription(description);
  }

  // void _setRemoteDescription() async {
  //   String data, type;
  //   if (_offer) {
  //     type = 'answer';
  //   } else {
  //     type = 'offer';
  //   }
  //
  //   print('############################ MODE: ${type}');
  //   data = await getData(type);
  //   sdpController.text = data;
  //   String jsonString = data;
  //   dynamic session = await jsonDecode('$jsonString');
  //
  //   String sdp = write(session, null);
  //
  //   // RTCSessionDescription description =
  //   //     new RTCSessionDescription(session['sdp'], session['type']);
  //   RTCSessionDescription description = new RTCSessionDescription(sdp, type);
  //   print(description.toMap());
  //
  //   await _peerConnection.setRemoteDescription(description);
  // }

  // void _addCandidate() async {
  //   List<String> jsonCandidates = await getCandidates();
  //   // sdpController.text = jsonString;
  //   jsonCandidates.forEach((jsonString) async {
  //     dynamic session = await jsonDecode('$jsonString');
  //     print('####### Candidate:::${session['candidate']}');
  //     dynamic candidate = new RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
  //     await _peerConnection.addCandidate(candidate);
  //   });
  // }

  _createPeerConnection() async {
    List<Map> iceCandidates = [];
    Map<String, dynamic> iceCandidate;
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);
    // if (pc != null) print(pc);
    pc.addStream(_localStream);

    pc.onIceCandidate = (RTCIceCandidate e) {

      if (e == null) {
        print('########### ICE GATTERING STATE #######');
        widget.db.saveCandidate(iceCandidates);
        return;
      }

      iceCandidate = {
        'candidate': e.candidate,
        'sdpMid': e.sdpMid,
        'sdpMlineIndex': e.sdpMlineIndex,
      };

      iceCandidates.add(iceCandidate);
      widget.db.saveCandidate(iceCandidates);

      print('################# ICE CANDIDATE:' + jsonEncode({
        'candidate': e.candidate.toString(),
        'sdpMid': e.sdpMid.toString(),
        'sdpMlineIndex': e.sdpMlineIndex,
      }));
    };

    // pc.onIceGatheringState = (e) {
    //
    //   print(e);
    // };


    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };


    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream = await navigator.getUserMedia(mediaConstraints);

    // _localStream = stream;
    _localRenderer.srcObject = stream;
    // _localRenderer.mirror = true;

    // _peerConnection.addStream(stream);

    return stream;
  }

  SizedBox videoRenderers() => SizedBox(
      height: 210,
      child: Row(children: [
        Flexible(
          child: new Container(
              key: new Key("local"),
              margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: new BoxDecoration(color: Colors.black),
              child: new RTCVideoView(_localRenderer, mirror: true)
          ),
        ),
        Flexible(
          child: new Container(
              key: new Key("remote"),
              margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: new BoxDecoration(color: Colors.black),
              child: new RTCVideoView(_remoteRenderer, mirror: true)
          ),
        )
      ]));

  Row offerAndAnswerButtons() =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        new RaisedButton(
          // onPressed: () {
          //   return showDialog(
          //       context: context,
          //       builder: (context) {
          //         return AlertDialog(
          //           content: Text(sdpController.text),
          //         );
          //       });
          // },
          onPressed: _createOffer,
          child: Text('Offer'),
          color: Colors.amber,
        ),
        RaisedButton(
          onPressed: _createAnswer,
          // onPressed: () {
          //   saveAnswer();
          // },
          child: Text('Answer'),
          color: Colors.amber,
        ),
      ]);

  Row sdpCandidateButtons() =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        RaisedButton(
          // onPressed: _setRemoteDescription,
          child: Text('Set Remote Desc'),
          color: Colors.amber,
        ),
        RaisedButton(
          // onPressed: _addCandidate,
          child: Text('Add Candidate'),
          color: Colors.amber,
        )
      ]);

  Padding sdpCandidatesTF() => Padding(
    padding: const EdgeInsets.all(16.0),
    child: TextField(
      controller: sdpController,
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      maxLength: TextField.noMaxLength,
    ),
  );

  @override
  Widget build(BuildContext context) {

    Map data = ModalRoute.of(context).settings.arguments;
    this._user = data['user'];


    // _user = Provider.of<String>(context);
    // AppUser user = Provider.of<AppUser>(context);
    // widget.db.saveUser(_user);
    // print('Call ####### USER #######:::  ' + user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter WebRTC Client'),
        actions: [
          FlatButton.icon(
            onPressed: () async {
              await widget._auth.signOut();
              _disconnectRTC();
            },
            icon: Icon(Icons.person),
            label: Text('logout')
          )
        ],
      ),
      body: Container(
        child: Column(
          children: [
            videoRenderers(),
            offerAndAnswerButtons(),
            sdpCandidatesTF(),
            sdpCandidateButtons(),
          ]
        )
      )
    );
  }
}
