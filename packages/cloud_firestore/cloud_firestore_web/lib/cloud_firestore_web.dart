
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart' as fs;

class CloudFirestorePlugin extends CloudFirestorePlatform {

    fs.Firestore store;
    Map<String, fs.CollectionReference> refs = {};

  /// Registers this class as the default instance of [WherMapFlutterPlatform].
  static void registerWith(Registrar registrar) {
    CloudFirestorePlatform.instance = CloudFirestorePlugin();
  }

  @override
  Stream<dynamic> getQuerySnapshots(String app, {String path, bool isCollectionGroup, Map<String, dynamic> parameters, bool includeMetadataChanges}) {
    if (store == null) {
      store = firestore();
    }
    if (refs[path] == null) {
      refs[path] = store.collection(path);
    }

    StreamController<dynamic> controller; // ignore: close_sinks
    controller = StreamController<dynamic>.broadcast(
      onListen: () {
        refs[path].onSnapshot.listen((onData) {
          controller.add(parseQuerySnapshot(path, onData));
        });
      }
    );

    return controller.stream;
  }

  Map<String, dynamic> parseQuerySnapshot (String path, fs.QuerySnapshot querySnapshot) {
    Map<String, dynamic> data = {};
    data["paths"] = querySnapshot.docs.map((doc) => '$path/${doc.id}').toList();
    data["documents"] = querySnapshot.docs.map((doc) => doc.data()).toList();
    data["documentChanges"] = querySnapshot.docChanges().map((docChange) => {
        "document": docChange.doc.data(),
        "path": '$path/${docChange.doc.id}',
        "metadata": {"hasPendingWrites": docChange.doc.metadata.hasPendingWrites, "isFromCache": docChange.doc.metadata.fromCache},
        "type": "DocumentChangeType.${docChange.type}",
        "oldIndex": docChange.oldIndex, 
        "newIndex": docChange.newIndex
      }).toList();
    data["metadatas"] = querySnapshot.docs.map((doc) => {"hasPendingWrites": doc.metadata.hasPendingWrites, "isFromCache": doc.metadata.fromCache}).toList();
    data["metadata"] = {"hasPendingWrites": querySnapshot.metadata.hasPendingWrites, "isFromCache": querySnapshot.metadata.fromCache};
    data["handle"] = 0;
    return data;
  }

  @override
  Future<void> setDocumentReferenceData(String app, {String path, Map<String, dynamic> data, Map<String, dynamic> options}) {
    if (store == null) {
      store = firestore();
    }
    return store.doc(path).set(data);
  }

  @override
  Future<void> updateDocumentReferenceData(String app, {String path, Map<String, dynamic> data}) {
    if (store == null) {
      store = firestore();
    }
    return store.doc(path).update(data: data);
  }
}