import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional/optional_internal.dart';
import 'package:tapis_antonello_ghezzi/model/model.dart';

class ModelNotifier extends StateNotifier<Model> {
  ModelNotifier(Model model) : super(model);

  void updateCmBetweenSignals(int cmBetweenSignals) {
    this.state = this.state.copyWith(cmBetweenSignals: cmBetweenSignals);
  }

  void updateSignals(int signals) {
    this.state = this.state.updateSignals(signals);
    debugPrint(
        "Signals updated with $signals: saved ${this.state.savedSignals}, total ${this.state.totalSignals()}");
  }

  void updateMeters(int meters) {
    final newSignals = (meters * 100) ~/ this.state.cmBetweenSignals;

    var deviceInitialSignals = null;
    if (this.state.deviceInitialSignals.isPresent) {
        deviceInitialSignals = Optional.of(this.state.deviceSignals);
    }

    debugPrint(
        "$newSignals ${this.state.deviceSignals} ${this.state.savedSignals} ${this.state.deviceInitialSignals}");

    this.state = this.state.copyWith(
          savedSignals: newSignals,
          deviceInitialSignals: deviceInitialSignals,
        );
  }

  void resetSignals() {
    this.state = this.state.copyWith(
          savedSignals: this.state.totalSignals(),
          deviceSignals: 0,
          deviceInitialSignals: const Optional.empty(),
        );
  }
}
