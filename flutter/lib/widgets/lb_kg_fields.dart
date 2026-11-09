import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/units/app_weight_unit_controller.dart';

/// Two linked inputs for a weight: typing pounds fills in kilograms and vice
/// versa. Always reports the value in pounds (null when both are empty).
///
/// Lays out lb then kg side by side; give it a bounded width (e.g. inside
/// an `Expanded`).
class LbKgFields extends StatefulWidget {
  const LbKgFields({
    super.key,
    required this.valueLb,
    required this.onChanged,
    required this.decoration,
    this.spacing = 8,
  });

  /// Current weight in pounds; null or 0 shows empty fields.
  final double? valueLb;
  final ValueChanged<double?> onChanged;

  /// Decoration for each field, given its unit symbol (`lb` / `kg`).
  final InputDecoration Function(String unit) decoration;
  final double spacing;

  @override
  State<LbKgFields> createState() => _LbKgFieldsState();
}

class _LbKgFieldsState extends State<LbKgFields> {
  late final TextEditingController _lb;
  late final TextEditingController _kg;
  final _lbFocus = FocusNode();
  final _kgFocus = FocusNode();

  static String _text(double? lb, WeightUnit unit) =>
      lb == null || lb <= 0 ? '' : unit.format(lb);

  static double? _parse(String v) => double.tryParse(v.replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    _lb = TextEditingController(text: _text(widget.valueLb, WeightUnit.lb));
    _kg = TextEditingController(text: _text(widget.valueLb, WeightUnit.kg));
  }

  @override
  void didUpdateWidget(LbKgFields old) {
    super.didUpdateWidget(old);
    // Follow outside changes (e.g. a copied set) unless the user is typing.
    if (widget.valueLb != old.valueLb &&
        !_lbFocus.hasFocus &&
        !_kgFocus.hasFocus) {
      _lb.text = _text(widget.valueLb, WeightUnit.lb);
      _kg.text = _text(widget.valueLb, WeightUnit.kg);
    }
  }

  @override
  void dispose() {
    _lb.dispose();
    _kg.dispose();
    _lbFocus.dispose();
    _kgFocus.dispose();
    super.dispose();
  }

  void _changed(String v, WeightUnit from) {
    final parsed = _parse(v);
    final lb = parsed == null || parsed <= 0 ? null : from.toLb(parsed);
    // Rewrite only the other field so the cursor in this one stays put.
    final other = from == WeightUnit.lb ? _kg : _lb;
    other.text = _text(
      lb,
      from == WeightUnit.lb ? WeightUnit.kg : WeightUnit.lb,
    );
    widget.onChanged(lb);
  }

  Widget _field(
    TextEditingController controller,
    FocusNode focus,
    WeightUnit unit,
  ) => TextField(
    controller: controller,
    focusNode: focus,
    textAlign: TextAlign.center,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: widget.decoration(unit.symbol),
    onChanged: (v) => _changed(v, unit),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _field(_lb, _lbFocus, WeightUnit.lb)),
      SizedBox(width: widget.spacing),
      Expanded(child: _field(_kg, _kgFocus, WeightUnit.kg)),
    ],
  );
}
