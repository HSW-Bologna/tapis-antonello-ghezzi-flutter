import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapis_antonello_ghezzi/controller/storage.dart';
import 'package:tapis_antonello_ghezzi/model/model.dart';

class ModelPersistence extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (previousValue != null && newValue != null) {
      if (previousValue is Model && newValue is Model) {
        if (previousValue.cmBetweenSignals != newValue.cmBetweenSignals) {
          debugPrint("Saving cm between signals: ${newValue.cmBetweenSignals}");
          saveCmBetweenSignals(newValue.cmBetweenSignals);
        }
        if (previousValue.totalSignals() != newValue.totalSignals()) {
          debugPrint("Saving signals: ${newValue.totalSignals()}");
          saveSignals(newValue.totalSignals());
        }
      }
    }
  }
}
