import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapis_antonello_ghezzi/controller/storage.dart';
import 'package:tapis_antonello_ghezzi/model/model.dart';
import 'package:tapis_antonello_ghezzi/model/notifier.dart';

final loadingModelProvider = FutureProvider<Model>((ref) {
  return loadModel();
});

final modelProvider = StateNotifierProvider<ModelNotifier, Model>((ref) {
  final model = ref.watch(loadingModelProvider);
  return model.when(
    data: (model) => ModelNotifier(model),
    loading: () => ModelNotifier(const Model.defaultValue()),
    error: (error, stackTrace) => ModelNotifier(const Model.defaultValue()),
  );
});
