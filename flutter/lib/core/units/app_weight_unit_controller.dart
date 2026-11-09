import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Weights are always stored in pounds; this only changes input and display.
enum WeightUnit {
  lb,
  kg;

  static const double _kgPerLb = 0.45359237;

  static WeightUnit fromStorage(String? raw) =>
      raw == 'kg' ? WeightUnit.kg : WeightUnit.lb;

  String get storageValue => name;

  String get symbol => name;

  double fromLb(double lb) => this == WeightUnit.lb ? lb : lb * _kgPerLb;

  double toLb(double value) => this == WeightUnit.lb ? value : value / _kgPerLb;

  /// `135`, `61.2`: no trailing `.0`, at most one decimal.
  String format(double lb) => formatNumber(fromLb(lb));

  static String formatNumber(double value) {
    final rounded = (value * 10).roundToDouble() / 10;
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }
}

class AppWeightUnitController extends ChangeNotifier {
  AppWeightUnitController();

  static const _prefKey = 'app_weight_unit';

  WeightUnit _unit = WeightUnit.lb;

  WeightUnit get unit => _unit;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _unit = WeightUnit.fromStorage(prefs.getString(_prefKey));
    notifyListeners();
  }

  Future<void> setUnit(WeightUnit value) async {
    if (_unit == value) return;
    _unit = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value.storageValue);
  }
}
