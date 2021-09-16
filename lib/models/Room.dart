import 'package:webrtc_client/models/AppUser.dart';

class Room {

  String uid;

  String name;

  List<AppUser> members;

  int created;

  Room(this.uid);

  Room.fromMap(Map<String, dynamic> data) {
    this.members = [];
    this.uid = data['uid'];
    this.name = data['name'];
    if (data['members'] != null) {
      data['members'].forEach((uid, userData) {
        this.members.add(AppUser.fromMap(userData));
      });
    }
    this.created = data['created'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'uid': this.uid,
      'name': this.name,
      'members': this.membersToMap(),
      'created': this.created,
    };
    return data;
  }

  Map<String, dynamic> membersToMap() {
    Map<String, dynamic> userList = {};
    this.members.forEach((AppUser appUser) {
      userList[appUser.uid] = appUser.toMap();
    });
    return userList;
  }


  void removeMember(userId) {
    this.members.removeWhere((member) => member.uid == userId);
  }

}