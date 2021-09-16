import 'package:uuid/uuid.dart';
import 'package:webrtc_client/models/BaseModel.dart';

class Message extends BaseModel {

  static const TYPE_CALL_REQUEST = 'call_request';

  static const TYPE_CALL_RESPONSE = 'call_response';

  static const TYPE_CALL_END = 'call_end';

  static const TYPE_ICE_CANDIDATE = 'ice_candidate';

  static const TYPE_OFFER = 'offer';

  static const TYPE_ANSWER = 'answer';

  static const TYPE_ROOM_UPDATE = 'room_update';

  String senderId;

  String recipientId;

  String type;

  Map<String, dynamic> data;

  int created;

  Message({this.type, this.senderId, this.recipientId, this.data}) : super() {
    this.uid = Uuid().v1();
  }

  Message.fromMap(Map<String, dynamic> data) : super() {
    this.uid = data.keys.first;
    this.senderId = data[this.uid]['sender'];
    this.recipientId = data[this.uid]['recipient'];
    this.type = data[this.uid]['type'];
    this.data = data[this.uid]['data'];
    this.created = data[this.uid]['created'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> msgData = {
      'uid': this.uid,
      'type': this.type,
      'sender': this.senderId,
      'recipient': this.recipientId,
      'data': this.data,
      'created': DateTime.now().millisecondsSinceEpoch
    };
    return msgData;
  }

}