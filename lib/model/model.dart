import 'package:meta/meta.dart';
import 'package:optional/optional_internal.dart';

@immutable
class Model {
  static const int earthMoonCm = 384400 * 100000;

  final int cmBetweenSignals;
  final int savedSignals;
  final int deviceSignals;
  final Optional<int> deviceInitialSignals;
  final int lastSignalTimestamp;

  const Model({
    required this.cmBetweenSignals,
    this.deviceSignals = 0,
    this.savedSignals = 0,
    this.lastSignalTimestamp = 0,
    required this.deviceInitialSignals,
  });

  const Model.defaultValue()
      : this.cmBetweenSignals = 100,
        this.deviceSignals = 0,
        this.deviceInitialSignals = const Optional.empty(),
        this.savedSignals = 0,
        this.lastSignalTimestamp = 0;

  Model updateSignals(int deviceSignals) {
    final deviceInitialSignals = this.deviceInitialSignals.isPresent
        ? this.deviceInitialSignals
        : Optional.of(deviceSignals);

    return this.copyWith(
        deviceSignals: deviceSignals,
        deviceInitialSignals: deviceInitialSignals);
  }

  Model copyWith(
      {int? cmBetweenSignals,
      int? deviceSignals,
      Optional<int>? deviceInitialSignals,
      int? savedSignals}) {
    return Model(
      cmBetweenSignals: cmBetweenSignals ?? this.cmBetweenSignals,
      deviceSignals: deviceSignals ?? this.deviceSignals,
      deviceInitialSignals: deviceInitialSignals ?? this.deviceInitialSignals,
      savedSignals: savedSignals ?? this.savedSignals,
      lastSignalTimestamp: deviceSignals != null
          ? DateTime.now().millisecondsSinceEpoch
          : this.lastSignalTimestamp,
    );
  }

  int distanceInCentimeters() {
    return (this.totalSignals() * this.cmBetweenSignals);
  }

  int remainingDistanceInMeters() {
    return (earthMoonCm > this.distanceInCentimeters()
            ? earthMoonCm - this.distanceInCentimeters()
            : 0) ~/
        100;
  }

  double getSpeedPercentage() {
    const speed = 0.025;
    final sinceLastSignal =
        DateTime.now().millisecondsSinceEpoch - this.lastSignalTimestamp;
    if (sinceLastSignal > 7000) {
      return 0;
    } else if (sinceLastSignal > 5000) {
      return ((2000 - (sinceLastSignal - 5000)) * speed) / 2000;
    } else {
      return speed;
    }
  }

  bool isRunning() {
    final sinceLastSignal =
        DateTime.now().millisecondsSinceEpoch - this.lastSignalTimestamp;
    return sinceLastSignal < 5000;
  }

  int totalSignals() {
    return (this.deviceSignals - this.deviceInitialSignals.orElse(0)) +
        this.savedSignals;
  }
}
