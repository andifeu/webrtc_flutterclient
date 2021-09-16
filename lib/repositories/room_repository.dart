import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/models/Room.dart';
import 'package:webrtc_client/repositories/base_repository.dart';

class RoomRepository extends BaseRepository {

  RoomRepository() : super('rooms');

  Future<Room> get(roomId) async {
    Room room;
    DocumentSnapshot snapshot = await this.firestoreReference.doc(roomId).get();
    Map<String, dynamic> data = snapshot.data();

    if (data == null) {
      return null;
    }

    room = Room.fromMap(data);
    room.members.forEach((element) {
      AppUser user;
    });

    return room;
  }

}
