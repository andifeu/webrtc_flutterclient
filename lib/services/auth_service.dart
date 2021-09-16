import 'package:firebase_auth/firebase_auth.dart';
import 'package:webrtc_client/models/AppUser.dart';
import 'package:webrtc_client/services/database_service.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AppUser _convertToAppUser(User firebaseUser) {
  //   if (firebaseUser == null) {
  //     return null;
  //   }
  //
  //   return DatabaseService.getUser(firebaseUser.uid);
  // }

  Stream<User> get onAuthStateChanged {
    return _auth.authStateChanges().map((User user) => user);
    // return _auth.authStateChanges().map((User user) => _convertToAppUser(user));
    // return _auth.authStateChanges().map((User user) {
    //   if (user == null) {
    //     return null;
    //   }
    //
    //   return DatabaseService.getUser(user.uid);
    //
    //   // return this._convertToAppUser(user);
    // });
  }

  Future<User> signInAnon(String username) async {
    AppUser user;
    UserCredential userCredential;

    try {
      userCredential = await _auth.signInAnonymously();
      if (userCredential.user == null) {
        return null;
      }

      user = AppUser(userCredential.user.uid);
      user.name = username;
      await DatabaseService(userCredential.user.uid).saveUser(user);
      // await DatabaseService.saveUser(user);

      // await userCredential.user.updateProfile(displayName: username);
      // await userCredential.user.reload();
      return userCredential.user;
      // return _convertToAppUser(userCredential.user);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  User getCurrentUser() {
    return _auth.currentUser;
  }


  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  void deleteAuthUser() async {
    await _auth.currentUser.delete().onError((error, stackTrace) => print(error));
  }

}