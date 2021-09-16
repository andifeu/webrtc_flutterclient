import 'package:firebase_database/firebase_database.dart';
import 'package:webrtc_client/services/database_service.dart';

// import 'package:firebase_database/ui/firebase_animated_list.dart';
// import 'package:firebase_core/firebase_core.dart';

final databaseRef = FirebaseDatabase.instance.reference();

void deleteEntries(String table) async {
  await databaseRef.child(table + '/').remove();
}

DatabaseReference saveOffer(Map offer) {
  var id;

  deleteEntries('offer');

  id = databaseRef.child('offer/').push();
  id.set(offer);
  return id;
}

DatabaseReference saveAnswer(String answer) {
  var id;

  deleteEntries('answer');

  id = databaseRef.child('answer/').push();
  id.set(answer);
  return id;
}

Future<String> getData(String table) async {
  String offer;
  DataSnapshot dataSnap = await databaseRef.child(table).limitToLast(1).once();
  print('############################# LAST OFFERS');
  print(dataSnap.value);

  if (dataSnap.value == null) {
    return null;
  }

  dataSnap.value.forEach((index, data)  {
    offer = data;
  });
  return offer;
}

Future<List<String>> getCandidates() async {
  List<String> jsonIceCandidates = [];
  DataSnapshot dataSnap = await databaseRef.child('candidate/').once();

  if (dataSnap.value == null) {
    return null;
  }

  dataSnap.value.forEach((index, candidate)  {
    jsonIceCandidates.add(candidate);
  });
  return jsonIceCandidates;
}

void saveCandidate(String iceCandidate) {
  var id;
  // deleteEntries('candidate');
  id = databaseRef.child('candidate/').push();
  id.set(iceCandidate);
  return id;
}

void deleteIceCandidates(String uid) {

}
