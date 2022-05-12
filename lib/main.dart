import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_list_app/controllers/auth_controller.dart';
import 'package:flutter_firebase_list_app/models/item_model.dart';
import 'package:flutter_firebase_list_app/repositries/auth_repositry.dart';
import 'package:flutter_firebase_list_app/repositries/customException.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'controllers/item_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen());
  }
}

class HomeScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CustomException?>(
      itemListExceptionProvider,
      (previous, next) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(next!.message!),
        ));
      },
    );
    final authControllerState = ref.watch(authControllerProvider);
    final toggleObtained = ref.watch(itemListFilterProvider);
    final toggleValue = toggleObtained == ItemListFilter.obtained;
    return Scaffold(
      appBar: AppBar(
        title: Text('shopping List'),
        leading: authControllerState != null
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              toggleValue ? Icons.check_circle : Icons.check_circle_outline,
            ),
            onPressed: () {
              ref.read(itemListFilterProvider.state).state =
                  toggleValue ? ItemListFilter.all : ItemListFilter.obtained;
            },
          ),
        ],
      ),
      body: Container(
        child: const ItemList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddItemDialog.show(context, Item.empty()),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddItemDialog extends HookConsumerWidget {
  static void show(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(item: item),
    );
  }

  final Item item;

  const AddItemDialog({Key? key, required this.item}) : super(key: key);

  bool get isUpdating => item.id != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: item.name);
    return Dialog(
        child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name')),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: isUpdating
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  isUpdating
                      ? ref
                          .read(itemListControllerProvider.notifier)
                          .updateItem(
                            updatedItem: item.copyWith(
                              name: textController.text.trim(),
                              obtained: item.obtained,
                            ),
                          )
                      : ref
                          .read(itemListControllerProvider.notifier)
                          .addItem(name: textController.text.trim());
                  Navigator.of(context).pop();
                },
                child: Text(isUpdating ? 'Update' : 'Add'),
              )),
        ],
      ),
    ));
  }
}

final currentItem = Provider<Item>((ref) => throw UnimplementedError());

class ItemList extends HookConsumerWidget {
  const ItemList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemListState = ref.watch(itemListControllerProvider);
    final filteredItemList = ref.watch(filteredItemListProvider);
    return itemListState.when(
        data: (items) => items.isEmpty
            ? const Center(
                child: Text(
                  'アイテムを入力してください',
                  style: TextStyle(fontSize: 20),
                ),
              )
            : ListView.builder(
                itemCount: filteredItemList.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = filteredItemList[index];
                  return ProviderScope(
                    overrides: [currentItem.overrideWithValue(item)],
                    child: ItemTile(),
                  );
                }),
        error: (error, _) => ItemListError(
            message: error is CustomException ? error.message! : 'エラーです'),
        loading: () => const Center(
              child: CircularProgressIndicator(),
            ));
  }
}

class ItemTile extends HookConsumerWidget {
  const ItemTile({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.read(currentItem);
    return ListTile(
      key: ValueKey(item.id),
      title: Text(item.name),
      trailing: Checkbox(
          value: item.obtained,
          onChanged: (val) => ref
              .read(itemListControllerProvider.notifier)
              .updateItem(
                  updatedItem: item.copyWith(obtained: !item.obtained))),
      onTap: () => AddItemDialog.show(context, item),
      onLongPress: () => ref
          .read(itemListControllerProvider.notifier)
          .deleteItem(itemId: item.id!),
    );
  }
}

class ItemListError extends HookConsumerWidget {
  final String message;
  const ItemListError({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 20),
        ),
        SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => ref
                .read(itemListControllerProvider.notifier)
                .retrieveItems(isRefreshing: true),
            child: const Text('リトライ'))
      ],
    ));
  }
}
