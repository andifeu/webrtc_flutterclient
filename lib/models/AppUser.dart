class AppUser {

  String uid;

  String name;

  bool online;

  int lastSeen;

  AppUser(this.uid);

  AppUser.fromMap(Map<String, dynamic> data) {
    this.uid = data['uid'];
    this.name = data['name'];
    this.online = data['online'];
    this.lastSeen = data['last_seen'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'uid': this.uid,
      'name': this.name,
      'online': this.online,
      'last_seen': this.lastSeen,
    };
    return data;
  }

}