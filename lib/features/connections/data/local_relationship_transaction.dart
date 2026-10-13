import 'dart:async';
import '../../../core/storage/local_storage.dart';

// Serialize relationship mutations and chat authorization for repositories that
// share local storage, so an in-flight acceptance cannot outlive a block.
final _pending = Expando<Future<void>>();

Future<T> localRelationshipTransaction<T>(
  LocalStorage storage,
  Future<T> Function() action,
) async {
  final previous = _pending[storage] ?? Future<void>.value();
  final released = Completer<void>();
  _pending[storage] = released.future;
  await previous;
  try {
    return await action();
  } finally {
    released.complete();
  }
}
