import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webrtc_client/models/AppUser.dart';

final CollectionReference firestoreUsersRef = FirebaseFirestore.instance.collection('users');
final DatabaseReference realtimeDBRef = FirebaseDatabase.instance.reference();


class AppUserRepository {

  Future<AppUser> get(uid) async {
    DocumentSnapshot snapshot = await firestoreUsersRef.doc(uid).get();
    Map<String, dynamic> data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUser.fromMap(data);
  }

  Future<List<AppUser>> getAll() async {
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

      appUsers.add(AppUser.fromMap(userData));
    });

    return appUsers;
  }
}
