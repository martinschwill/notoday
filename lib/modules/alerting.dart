import '../common_imports.dart';


class Alerting {
  /// Checks if the given value is above the threshold
  static bool isAboveThreshold(double value, double threshold) {
    return value > threshold;
  }

  /// Checks if the given value is below the threshold
  static bool isBelowThreshold(double value, double threshold) {
    return value < threshold;
  }

  /// Checks if the given value is within the acceptable range
  static bool isWithinRange(double value, double min, double max) {
    return value >= min && value <= max;
  }
}


