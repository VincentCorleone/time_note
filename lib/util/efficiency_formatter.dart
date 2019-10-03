

import 'package:flutter/services.dart';

class EfficiencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text;
    int selectionIndex = newValue.selection.end;

    void revert() {
      //keep origin value because of invalid input
      value = oldValue.text;
      selectionIndex = oldValue.selection.end;
    }

    if (oldValue.text == "1.00" && value == "-") {
      value = "0.00";
      return new TextEditingValue(
        text: value,
        selection: new TextSelection.collapsed(offset: 4),
      );
    }
    //only allow double input
    double parsedValue;
    try {
      parsedValue = double.parse(value);
    } catch (e) {
      revert();
      return new TextEditingValue(
        text: value,
        selection: new TextSelection.collapsed(offset: selectionIndex),
      );
    }

    if (parsedValue > 1.0) {
      value = "1.00";
    } else if (parsedValue < 0.0) {
      value = "0.00";
    } else {
      value = parsedValue.toStringAsFixed(2);
    }

    return new TextEditingValue(
      text: value,
      selection: new TextSelection.collapsed(offset: selectionIndex),
    );
  }
}