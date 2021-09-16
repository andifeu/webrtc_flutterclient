import 'package:webrtc_client/repositories/base_repository.dart';

class BaseModel {

  String uid;

  String collectionName;

  BaseRepository repository;

  BaseModel() {
    if (collectionName == null) {
      collectionName = this.runtimeType.toString().toLowerCase();
    }
    this.repository = BaseRepository(collectionName);
  }

}