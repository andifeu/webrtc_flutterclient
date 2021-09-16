import 'package:cloud_firestore/cloud_firestore.dart';

class BaseRepository {

  CollectionReference firestoreReference;

  BaseRepository(String collectionName) {
    this.firestoreReference = FirebaseFirestore.instance.collection(collectionName);
  }

}
