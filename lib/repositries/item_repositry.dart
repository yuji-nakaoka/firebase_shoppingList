import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_list_app/extensions/firebase_firestore_extension.dart';
import 'package:flutter_firebase_list_app/models/item_model.dart';
import 'package:flutter_firebase_list_app/repositries/general_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'customException.dart';

abstract class BaseItemRepositry {
  Future<List<Item>> retrieveItems({required String userId});
  Future<String> createItem({required String userId, required Item item});
  Future<void> updateItem({required String userId, required Item item});
  Future<void> deleteItem({required String userId, required String itemId});
}

final itemRepositoryProvider =
    Provider<ItemRepositry>(((ref) => ItemRepositry(ref.read)));

class ItemRepositry implements BaseItemRepositry {
  final Reader _read;

  const ItemRepositry(this._read);

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      final snap =
          await _read(firebaseFirestoreProvider).usersListRef(userId).get();
      return snap.docs.map((doc) => Item.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<String> createItem(
      {required String userId, required Item item}) async {
    try {
      final docRef = await _read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .add(item.toDocument());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> deleteItem(
      {required String userId, required String itemId}) async {
    try {
      await _read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
    throw UnimplementedError();
  }

  @override
  Future<void> updateItem({required String userId, required Item item}) async {
    try {
      await _read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
}
