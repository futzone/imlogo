import 'package:flutter/material.dart';

Color getRateColor(num kRate) {

  if (kRate == 0) {
    return Colors.black;
  } else if (kRate == 1) {
    return Colors.brown;
  } else if (kRate == 2) {
    return Colors.red;
  } else if (kRate == 3) {
    return Colors.amber;
  } else if (kRate == 4) {
    return Colors.blue;
  }

  return Colors.green;
}
