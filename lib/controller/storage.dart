import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapis_antonello_ghezzi/model/model.dart';

const String _cmBetweenSignalsKey = "CM_BETWEEN_SIGNALS";
const String _signalsKey = "SIGNALS";

void saveCmBetweenSignals(int cmBetweenSignals) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_cmBetweenSignalsKey, cmBetweenSignals);
}

void saveSignals(int signals) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_signalsKey, signals);
}

Future<Model> loadModel() async {
  final prefs = await SharedPreferences.getInstance();

  final cmBetweenSignals = prefs.getInt(_cmBetweenSignalsKey);
  final savedSignals = prefs.getInt(_signalsKey);
  debugPrint("Loaded model: $cmBetweenSignals, $savedSignals");

  return const Model.defaultValue().copyWith(
    cmBetweenSignals: cmBetweenSignals,
    savedSignals: savedSignals,
  );
}
