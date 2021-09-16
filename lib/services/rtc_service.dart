import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:webrtc_client/models/RTCUser.dart';

class RTCService {

  RTCVideoRenderer localRenderer;
  MediaStream _localStream;

  Map<String, dynamic> _queuedOperations = {
    'answer': false,
    'description': null,
    'candidates': []
  };


  // final Map<String, dynamic> _configuration = {
  //   "iceServers": [
  //     {"url": {'stun:stun.l.google.com:19302"},
  //   ]
  // };

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // {
      //   'urls': 'stun:numb.viagenie.ca',
      //   'credential': 'webrtcapp',
      //   'username': 'andreas.feuerstein@mail.de'
      // },
      // {
      //   'urls': 'turn:numb.viagenie.ca',
      //   'credential': 'webrtcapp',
      //   'username': 'andreas.feuerstein@mail.de'
      // }
      // {
      //   'urls': 'stun:40.85.216.95:3478',
      //   'credential': 'onemandev',
      //   'username': 'SecureIt'
      // },
      // {
      //   'urls': 'turn:40.85.216.95:3478',
      //   'credential': 'onemandev',
      //   'username': 'SecureIt'
      // }
    ]
  };


  final Map<String, dynamic> _offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };


  Future<void> initialize(Size size) async {
    this.localRenderer = await this.createVideoRenderer();
    this._localStream = await this._getUserMedia(size);
  }


  void dispose() {
    if (this._localStream != null) {
      print('------------------------ DISPOSE MEDIA STREAM');
      this._localStream.dispose();
      this._localStream = null;
    }
  }


  Future<RTCVideoRenderer> createVideoRenderer() async {
    RTCVideoRenderer renderer = RTCVideoRenderer();
    await renderer.initialize();
    return renderer;
  }


  RTCVideoView createRTCVideoView(RTCVideoRenderer renderer) {
    // return RTCVideoView(renderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
    return RTCVideoView(renderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain);
  }


  Future<RTCPeerConnection> createRTCConnection(
      RTCUser user,
      Function onIceCandidate,
      Function onConnectionStateCompleted,
      Function onConnectionStateFailed
  ) async {

    RTCPeerConnection pc;

    pc = await createPeerConnection(this._configuration, this._offerSdpConstraints);
    pc.addStream(this._localStream);

    pc.onIceCandidate = (RTCIceCandidate e) {
      onIceCandidate(user, e);
    };

    pc.onIceGatheringState = (RTCIceGatheringState state) {
      print('#################################### RTCIceGatheringState ${user.name}');
      print(state);
      print('####################################');

      // if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      //   onConnectionStateCompleted();
      // }
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      print('#################################### onIceConnectionState ${user.name}');
      print(state);
      print('####################################');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onConnectionStateFailed();
      } else if (
        state == RTCIceConnectionState.RTCIceConnectionStateConnected
        // state == RTCIceConnectionState.RTCIceConnectionStateCompleted
      ) {
        onConnectionStateCompleted();
      }
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      user.renderer.srcObject = stream;
    };

    return pc;
  }


  Future<MediaStream> _getUserMedia(Size size) async {
    MediaStream stream;

    String w = (size.width.toInt()).toString();
    String h = (size.height ~/ 2).toString();
    // print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> width ${w}');
    // print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Height ${h}');

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        // 'width': size.width,
        // 'height': size.height / 2,
        // 'width': 180,
        // 'height': 320,
        // 'mandatory': {
        //   'minWidth': w, // Provide your own width, height and frame rate here
        //   'minHeight': h,
        //   'maxWidth': w, // Provide your own width, height and frame rate here
        //   'maxHeight': h,
        //   // 'minFrameRate': '30',
        //   // 'minWidth': 180,
        //   // 'minHeight': 320
        // },
        'facingMode': 'user',
        'optional': [],
      },
    };

    // final Map<String, dynamic> mediaConstraints = {
    //   'audio': true,
    //   'video': false,
    // };

    stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    // await this.localRenderer.initialize();

    // localStream = stream;
    this.localRenderer.srcObject = stream;
    return stream;
  }


  Future<Map<String, dynamic>> createOffer(RTCUser rtcUser) async {
    RTCSessionDescription description = await rtcUser.peerConnection.createOffer({'offerToReceiveVideo': 1});
    Map<String, dynamic> session = parse(description.sdp);

    await rtcUser.peerConnection.setLocalDescription(description);
    return session;
  }


  Future<Map<String, dynamic>> createAnswer(RTCUser rtcUser) async {
    if (rtcUser.peerConnection == null) {
      this._queuedOperations['answer'] = true;
      return null;
    }
    RTCSessionDescription description = await rtcUser.peerConnection.createAnswer({'offerToReceiveVideo': 1});
    Map<String, dynamic> session = parse(description.sdp);

    await rtcUser.peerConnection.setLocalDescription(description);
    return session;
  }


  Future<void> setRemoteDescription(RTCUser rtcUser, Map<String, dynamic> session, [bool isAnswer = false]) async {
    String sdp = write(session, null);
    RTCSessionDescription description = new RTCSessionDescription(sdp, isAnswer ? 'answer' : 'offer');
    if (rtcUser.peerConnection == null) {
      this._queuedOperations['description'] = description;
    } else {
      await rtcUser.peerConnection.setRemoteDescription(description);
    }
  }

  Future<void> setCandidate(RTCUser rtcUser, Map<String, dynamic> session) async {
    RTCIceCandidate candidate = new RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    if (rtcUser.peerConnection == null) {
      this._queuedOperations['candidates'].add(candidate);
    } else {
      await rtcUser.peerConnection.addCandidate(candidate);
    }
  }

  void processQueuedOperations(RTCUser rtcUser) async {
    if (rtcUser.peerConnection == null) {
      print('################ PEEER CONNECTION = NULL');
      return;
    }

    if (this._queuedOperations['answer']) {
      await this.createAnswer(rtcUser);
      this._queuedOperations['answer'] = false;
    }

    if (this._queuedOperations['description'] != null) {
      await this.setRemoteDescription(rtcUser, this._queuedOperations['description']);
      this._queuedOperations['description'] = null;
    }

    if (this._queuedOperations['candidates'].length > 0) {
      for (Map candidate in this._queuedOperations['candidates']) {
        await this.setCandidate(rtcUser, candidate);
      }
      this._queuedOperations['candidates'] = [];
    }
  }

}