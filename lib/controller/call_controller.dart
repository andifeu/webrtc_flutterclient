import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/models/Message.dart';
import 'package:webrtc_client/models/RTCUser.dart';
import 'package:webrtc_client/models/Room.dart';
import 'package:webrtc_client/services/database_service.dart';
import 'package:webrtc_client/services/message_service.dart';
import 'package:webrtc_client/services/rtc_service.dart';

class CallController {

  Function setState;
  State _viewState;

  RTCService rtcService;
  DatabaseService _database;
  MessageService _messageService;

  bool iceCandidate = false;

  AppUser user;
  Room room;

  List<RTCUser> rtcUsers = [];

  CallController(this._viewState, this.setState);

  void initialize() async {
    String roomId;
    Room room;

    Map data = ModalRoute.of(this._viewState.context).settings.arguments;
    print(data);
    this.user = data['user'];
    roomId = data['room_id'];

    this.rtcService = RTCService();

    await this.rtcService.initialize(MediaQuery.of(this._viewState.context).size);
    this._messageService = this._handleMessages(this.user.uid);

    this._database = DatabaseService(this.user.uid);

    room = await this._database.getRoom(roomId);
    if (room == null || room.members.length == 0) {
      return;
    }

    await this._setupRenderers(room);

    this._updateRoom(room);
    Timer(Duration(milliseconds: 2000), () async {
      this._sendOffers();
    });
  }


  void dispose() {
    for (RTCUser rtcUser in this.rtcUsers) {
      this._disconnectPeer(rtcUser);
    }
    this.rtcService.dispose();
    // this.rtcService = null;
  }

  void _disconnectPeer(RTCUser rtcUser) async {
    await rtcUser.renderer.dispose();
    if (rtcUser.peerConnection != null) {
      await rtcUser.peerConnection.close();
      // await rtcUser.peerConnection.dispose();
      rtcUser.peerConnection = null;
      rtcUser.videoView = null;
    }
  }

  void endCall() async {
    this.room.removeMember(this.user.uid);
    await this._database.updateRoom(this.room);

    for (RTCUser rtcUser in this.rtcUsers) {
      if (rtcUser.uid == this.user.uid) {
        continue;
      }
      this._messageService.sendCallEnd(rtcUser.uid);
    }
  }


  void _updateRoom(room) {
    if (this._viewState.mounted == false) {
      print('################# ROOM UPDATE ABORTED');
      return;
    }
    print('################################ MEMBERS::${room.members.length}');
    this.setState(() {
      print('################# ROOM UPDATE EXECUTED');
      this.room = room;
    });
  }


  MessageService _handleMessages(String uid) {
    return MessageService(
      uid,
      onMessageReceived: (Message msg) async {
        RTCUser sender = this._getRtcUserById(msg.senderId);

        print('################# MESSAGE: ${msg.type} from ${msg.senderId}');

        switch (msg.type) {
          case Message.TYPE_OFFER:
            Map<String, dynamic> answer;
            await this.rtcService.setRemoteDescription(sender, msg.data);
            answer = await this.rtcService.createAnswer(sender);
            if (answer != null) {
              this._messageService.sendAnswer(sender.uid, answer);
            }

            break;

          case Message.TYPE_ANSWER:
            await this.rtcService.setRemoteDescription(sender, msg.data, true);
            break;

          case Message.TYPE_ICE_CANDIDATE:

            await this.rtcService.setCandidate(sender, msg.data);
            break;

          case Message.TYPE_CALL_END:
            Room room = await this._database.getRoom(this.room.uid);
            if (room == null) {
              return;
            }
            if (room.members == null || room.members.length == 1) {
              this.leaveRoom();
              this._database.deleteRoom(room.uid);
            } else {
              print('################################## ${sender.name} left room ${room.members.length}');
              this.rtcUsers.removeWhere((rtcUser) => rtcUser.uid == sender.uid);
              this._updateRoom(room);
              // this._disconnectPeer(sender);
            }
            break;

          case Message.TYPE_ROOM_UPDATE:
            this._updateRoom(this.room);
            break;

          default:
            print('######### UNKNOWN MESSAGE TYPE');
            print(msg);
        }
      }
    );
  }

  // void _forEachRoomMember(Function functionToApply) {
  //   for (RTCUser rtcUser in this.rtcUsers) {
  //     functionToApply(rtcUser);
  //   }
  // }


  void leaveRoom() {
    if (this._viewState.mounted) {
      Navigator.of(this._viewState.context).pop(true);
    }
  }


  RTCUser _getRtcUserById(String uid) {
    for (RTCUser rtcUser in this.rtcUsers) {
      if (rtcUser.uid == uid) {
        return rtcUser;
      }
    }
    return null;
  }


  // Future<void> _setupRenderers(List<AppUser> members) async {
  Future<void> _setupRenderers(Room room) async {
    for (AppUser member in room.members) {
      RTCUser rtcUser = RTCUser(member);

      if (this.user.uid == member.uid) {
        rtcUser.renderer = this.rtcService.localRenderer;
      } else {
        rtcUser.renderer = await this.rtcService.createVideoRenderer();
        rtcUser.peerConnection = await this.rtcService.createRTCConnection(
          rtcUser,
          this._handleIceCandidate,
          this._connectionStateCompleted,
          () async {

            print('++++++++++++++++++++++++++++++++++++++++ CONNECTION FAILED with ${rtcUser.name}');


            // this.rtcUsers.where((user) => false)
            // this.rtcUsers.where((user) {
            //   if (user.uid == rtcUser.uid && rtcUser.offerSent == false) {
            //     this._sendOffer(rtcUser);
            //   }
            // });
            if (room.members.length > 1) {
              if (rtcUser.offerSent == false) {
                print('didnt sent offer to ${rtcUser.name}');
                this._sendOffer(rtcUser);
                rtcUser.offerSent = true;
              }
            }

            // this._disconnectPeer(rtcUser);
            // Timer(Duration(milliseconds: 2000), () async {
            //   this._sendOffers();
            // });

            // this.endCall();
            // this.leaveRoom();
            // await this._setupRenderers(this.room.members);
            // Timer(Duration(milliseconds: 2000), () async {
            //   await this._sendOffers();
            // });
          }
        );
        this.rtcService.processQueuedOperations(rtcUser);
      }
      this.rtcUsers.add(rtcUser);
    }
  }


  void _sendOffers() {
    bool sendOffer = false;

    for (RTCUser rtcUser in this.rtcUsers) {
      if (rtcUser.uid == this.user.uid) {
        sendOffer = true;
        continue;
      }

      if (!sendOffer) {
        continue;
      }

      this._sendOffer(rtcUser);
      rtcUser.offerSent = true;
    }
  }


  Future<void> _sendOffer(RTCUser rtcUser) async {
    Map<String, dynamic> offer = {};

    print('################################################################');
    print('++++++++++++++++++++++++++++++++++++++++ send offer to ${rtcUser.name}');
    print('################################################################');
    offer = await this.rtcService.createOffer(rtcUser);
    this._messageService.sendOffer(rtcUser.uid, offer);
  }

  void _handleIceCandidate(RTCUser user, RTCIceCandidate iceCandidate) {
    Map<String, dynamic> icData;

    if (iceCandidate == null) {
      return;
    }

    icData = {
      'candidate': iceCandidate.candidate,
      'sdpMid': iceCandidate.sdpMid,
      'sdpMlineIndex': iceCandidate.sdpMlineIndex,
    };

    this._messageService.sendIceCandidate(user.uid, icData);

    // this._connectionStateCompleted();

    // debugPrint('################# ICE CANDIDATE:' + json.encode(iceCandidate), wrapWidth: 1024);
    // print('################# ICE CANDIDATE:' + jsonEncode({
    //   'candidate': iceCandidate.candidate.toString(),
    //   'sdpMid': iceCandidate.sdpMid.toString(),
    //   'sdpMlineIndex': iceCandidate.sdpMlineIndex,
    // }));
  }


  void _connectionStateCompleted() {
    if (this.room.members.length > 0) {
      this._updateRoom(this.room);
    }
    // _forEachRoomMember((RTCUser rtcUser) {
    //   if (rtcUser.uid != this.user.uid) {
    //     this._messageService.sendRoomUpdate(rtcUser.uid);
    //   }
    // });
  }

}