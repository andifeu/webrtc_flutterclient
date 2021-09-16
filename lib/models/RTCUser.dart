import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_client/models/AppUser.dart';

class RTCUser {

  String uid;

  String name;

  AppUser appUser;

  RTCPeerConnection peerConnection;

  RTCVideoRenderer renderer;

  RTCVideoView videoView;

  bool offerSent = false;

  RTCUser(AppUser appUser) {
    this.appUser = appUser;
    this.uid = appUser.uid;
    this.name = appUser.name;
  }

}