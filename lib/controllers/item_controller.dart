import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firebase_list_app/controllers/auth_controller.dart';
import 'package:flutter_firebase_list_app/models/item_model.dart';
import 'package:flutter_firebase_list_app/repositries/customException.dart';
import 'package:flutter_firebase_list_app/repositries/item_repositry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final itemListExceptionProvider = StateProvider<CustomException?>((_) => null);

final itemListControllerProvider =
    StateNotifierProvider<ItemListController, AsyncValue<List<Item>>>(
  (ref) {
    final user = ref.watch(authControllerProvider);
    return ItemListController(ref.read, user?.uid);
  },
);

class ItemListController extends StateNotifier<AsyncValue<List<Item>>> {
  final Reader _read;
  final String? _userId;
  ItemListController(this._read, this._userId) : super(AsyncValue.loading()) {
    if (_userId != null) ;
    retrieveItems();
  }

  Future<void> retrieveItems({bool isRefreshing = false}) async {
    if (isRefreshing) state = AsyncValue.loading();
    try {
      final items =
          await _read(itemRepositoryProvider).retrieveItems(userId: _userId!);
      if (mounted) {
        state = AsyncValue.data(items);
      }
    } on CustomException catch (e) {
      state = AsyncValue.error(e);
    }
  }

  Future<void> addItem({required String name, bool obtained = false}) async {
    try {
      final item = Item(name: name, obtained: obtained);
      final itemId = await _read(itemRepositoryProvider).createItem(
        userId: _userId!,
        item: item,
      );
      state.whenData((items) =>
          state = AsyncValue.data(items..add(item.copyWith(id: itemId))));
    } on CustomException catch (e) {
      _read(itemListExceptionProvider.state).state = e;
    }
  }

  Future<void> updateItem({required Item updatedItem}) async {
    try {
      await _read(itemRepositoryProvider)
          .updateItem(userId: _userId!, item: updatedItem);
      state.whenData((items) => {
            state = AsyncValue.data([
              for (final item in items)
                if (item.id == updatedItem.id) updatedItem else item
            ])
          });
    } on CustomException catch (e) {
      _read(itemListExceptionProvider.state).state = e;
    }
  }

  Future<void> deleteItem({required String itemId}) async {
    try {
      await _read(itemRepositoryProvider)
          .deleteItem(userId: _userId!, itemId: itemId);
      state.whenData((items) =>
          AsyncValue.data(items..removeWhere((item) => item.id == itemId)));
    } on CustomException catch (e) {
      _read(itemListExceptionProvider.state).state = e;
    }
  }
}
