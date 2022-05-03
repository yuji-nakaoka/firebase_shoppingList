import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_list_app/models/item_model.dart';
import 'package:flutter_firebase_list_app/repositries/general_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'customException.dart';

abstract class BaseItemRepositry {
  Future<List<Item>> retrieveItems({required String userId});
  Future<String> createItems({required String userId, required Item item});
  Future<void> updateItems({required String userId, required Item item});
  Future<void> deleteItems({required String userId, required String itemId});
}

class ItemRepositry implements BaseItemRepositry {
  final Reader _read;

  const ItemRepositry(this._read);

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      final snap = await _read(firebaseFirestoreProvider)
          .collection('lists')
          .doc(userId)
          .collection('userList')
          .get();
      return snap.docs.map((doc) => Item.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<String> createItems(
      {required String userId, required Item item}) async {
    try {
      final docRef = await _read(firebaseFirestoreProvider)
          .collection('lists')
          .doc(userId)
          .collection('userList')
          .add(item.toDocument());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> deleteItems(
      {required String userId, required String itemId}) async {
    try {
      await _read(firebaseFirestoreProvider)
          .collection('lists')
          .doc(userId)
          .collection('userList')
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
    throw UnimplementedError();
  }

  @override
  Future<void> updateItems({required String userId, required Item item}) async {
    try {
      await _read(firebaseFirestoreProvider)
          .collection('lists')
          .doc(userId)
          .collection('userLists')
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
}
