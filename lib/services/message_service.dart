import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webrtc_client/models/Message.dart';

class MessageService {

  final CollectionReference firestoreRef = FirebaseFirestore.instance.collection('messages');

  final String uid;

  MessageService(this.uid, {Function onMessageReceived}) {
    if (onMessageReceived != null) {
      this.onMessageReceived(onMessageReceived);
    }
  }


  void onMessageReceived(Function callback) {
    Message msg;
    Map<String, dynamic> msgData;
    firestoreRef.doc(this.uid).snapshots().listen((DocumentSnapshot msgSnapshot) {
      msgData = msgSnapshot.data();
      if (msgData != null && msgData.length > 0) {
        msg = Message.fromMap(msgData);
        this.delete(msg);
        callback(msg);
      }
    });
  }

  Future delete(Message msg) {
    firestoreRef.doc(this.uid).update({
      msg.uid: FieldValue.delete()
    });
  }

  Future _send(String type, String recipientUid, [Map<String, dynamic> data = const {}]) async {
    Message message = Message(
      senderId: this.uid,
      recipientId: recipientUid,
      type: type,
      data: data
    );

    if (type != 'ice_candidate') {
      print('##################### MSG ${type} to ${recipientUid}');
      print(json.encode(message.toMap()));
    }

    return await firestoreRef.doc(recipientUid).set({
      message.uid: message.toMap()
    });
  }

  void requestCall(String calleeId, String roomId) {
    Map<String, String> roomData = {
      'room_id': roomId
    };

    this._send(Message.TYPE_CALL_REQUEST, calleeId, roomData);
    // calleeIds.forEach((calleeId) {
    //   this._send(Message.TYPE_CALL_REQUEST, calleeId, roomData);
    // });
  }

  // void responseCall(List)

  // Future sendCallStart(String recipientUid, Map<String, dynamic> answer) {
  //   return this._send(Message.TYPE_ANSWER, recipientUid, answer);
  // }

  Future sendIceCandidate(String recipientUid, Map<String, dynamic> icData) {
    return this._send(Message.TYPE_ICE_CANDIDATE, recipientUid, icData);
  }

  Future sendOffer(String recipientUid, Map<String, dynamic> offer) {
    return this._send(Message.TYPE_OFFER, recipientUid, offer);
  }

  Future sendAnswer(String recipientUid, Map<String, dynamic> answer) {
    return this._send(Message.TYPE_ANSWER, recipientUid, answer);
  }

  Future sendCallEnd(String recipientUid) {
    return this._send(Message.TYPE_CALL_END, recipientUid);
  }

  void sendRoomUpdate(String recipientUid) {
    this._send(Message.TYPE_ROOM_UPDATE, recipientUid);
  }

}
