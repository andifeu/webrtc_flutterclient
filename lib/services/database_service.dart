import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/models/Room.dart';

class DatabaseService {

  final String uid;

  final CollectionReference firestoreUsersRef = FirebaseFirestore.instance.collection('users');

  final CollectionReference firestoreRoomsRef = FirebaseFirestore.instance.collection('rooms');

  /**
   * RTDB Reference für Presence Handling:
   * onDisconnect wird vom Cloud Firestore nicht unterstützt
   */
  final DatabaseReference realtimeDBRef = FirebaseDatabase.instance.reference();

  DatabaseService(this.uid);

  // void initializeService() {
  //   DatabaseService.getUser(this.uid).then((user) {
  //     this._user = user;
  //     if (this.afterInitialized != null) {
  //       this.afterInitialized(user);
  //     }
  //   });
  // }

  Future saveOffer(Map offer) async {
    return await firestoreUsersRef.doc(this.uid).update({
      'offers': offer
    });
  }

  Future saveAnswer(Map answer) async {
    return await firestoreUsersRef.doc(this.uid).update({
      'answers': answer
    });
  }

  Future saveCandidate(List<Map<String, dynamic>> iceCandidates) async {
    return await firestoreUsersRef.doc(this.uid).update({
      'candidates': iceCandidates
    });
  }

  Future saveUser(AppUser user) async {
    return await firestoreUsersRef.doc(user.uid).set({
      'uid': user.uid,
      'name': user.name,
      'available': true
    });
  }

  Future<AppUser> getUser(uid) async {
    DocumentSnapshot snapshot = await firestoreUsersRef.doc(uid).get();
    Map<String, dynamic> data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUser.fromMap(data);
  }

  Future createCall(List<AppUser> users) async {
    String roomId;

    roomId = await this.saveRoom(users);
    await firestoreUsersRef.doc(this.uid).update({
      'call': roomId,
      'available': false
    });

    return roomId;
  }


  Future<String> saveRoom(List<AppUser> members) async {
    Map<String, dynamic> userList = {};
    Map<String, dynamic> userMap = {};
    String roomId = Uuid().v1();

    members.forEach((AppUser appUser) {
      // userList[appUser.uid] = appUser.name;
      // userList.add(appUser.toMap());
      userMap = appUser.toMap();
      // userMap['initialized'] = false;
      userList[appUser.uid] = userMap;
    });

    await firestoreRoomsRef.doc(roomId).set({
      'uid': roomId,
      'name': null,
      'members': userList,
      'created': DateTime.now().millisecondsSinceEpoch
    });

    return roomId;
  }

  Future<void> updateRoom(Room room) async {
    await firestoreRoomsRef.doc(room.uid).update(room.toMap());
  }

  Future<List<AppUser>> getUsers() async {
    QuerySnapshot snapshot = await firestoreUsersRef.get();
    DataSnapshot rtdbSnapshot = await realtimeDBRef.once();
    List<AppUser> appUsers = [];

    Map<String, dynamic> usersOnline = {};

    rtdbSnapshot.value.forEach((key, val) {
      usersOnline[key] = val;
    });

    snapshot.docs.forEach((doc) {
      Map<String, dynamic> userData = doc.data();
      String uid = userData['uid'];

      if (usersOnline[uid] == null || uid == this.uid) {
        return;
      }

      userData['online'] = usersOnline[uid]['online'];
      userData['last_seen'] = usersOnline[uid]['last_seen'];

      if (userData['online'] == true) {
        appUsers.add(AppUser.fromMap(userData));
      }
    });

    return appUsers;
  }


  void updateUserPresence(Function onChangeCallback) async {

    /**
     * Update list after presence changed
     */
    realtimeDBRef.onChildAdded.listen((event) {
      onChangeCallback();
    });

    realtimeDBRef.onChildChanged.listen((event) {
      onChangeCallback();
    });

    await realtimeDBRef
        .child(this.uid)
        .update(getPresenceStatus(true))
        .whenComplete(() => print('Updated your presence state'))
        .catchError((e) => print(e));

    realtimeDBRef.child(this.uid).onDisconnect().update(getPresenceStatus(false));
  }


  Map<String, dynamic> getPresenceStatus(bool online) {
    Map<String, dynamic> presenceStatus = {
      'online': online,
      'last_seen': DateTime.now().millisecondsSinceEpoch,
    };
    return presenceStatus;
  }

  void setOffline() async {
    Map<String, dynamic> presenceStatus = getPresenceStatus(false);
    print(this.uid + ': ' + presenceStatus.toString());
    await realtimeDBRef
        .child(this.uid)
        .update(getPresenceStatus(false))
        .whenComplete(() => print('Updated your presence to false'))
        .catchError((e) => print(e));
  }

  void deleteData() async {
    await realtimeDBRef.child(this.uid).remove().catchError((e) => print(e));
    await firestoreUsersRef.doc(this.uid).delete().catchError((e) => print(e));
  }


  void deleteRoom(String roomId) async {
    await firestoreRoomsRef.doc(roomId).delete().catchError((e) => print(e));
  }

  Future<Room> getRoom(String roomId) async {
    DocumentSnapshot snapshot = await firestoreRoomsRef.doc(roomId).get();
    Map<String, dynamic> data = snapshot.data();
    if (data == null) {
      return null;
    }
    return Room.fromMap(data);
  }


  // Future<void> leaveRoom(String roomId, )


  // void onCall(Function callback) {
  //   firestoreUsersRef.doc(uid).snapshots().listen((DocumentSnapshot userSnapshot) {
  //     Map<String, dynamic> userData = userSnapshot.data();
  //
  //     if (this._user != null && this._user.call != userData['call']) {
  //       firestoreRoomsRef.doc(userData['call']).get().then((DocumentSnapshot roomSnapshot) {
  //         Map<String, dynamic> roomData = roomSnapshot.data();
  //         print('########################## ROOOM');
  //         print(roomData);
  //       });
  //
  //       // Map<String, dynamic> data = snapshot.data();
  //       // return AppUser.fromMap(data);
  //       callback();
  //     }
  //   });
  // }


}