import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double card = 16.0;
  static const double sheet = 24.0;
  static const double pill = 999.0;

  static const Radius smRadius = Radius.circular(sm);
  static const Radius mdRadius = Radius.circular(md);
  static const Radius cardRadius = Radius.circular(card);
  static const Radius sheetRadius = Radius.circular(sheet);

  static const BorderRadius smBorder = BorderRadius.all(smRadius);
  static const BorderRadius mdBorder = BorderRadius.all(mdRadius);
  static const BorderRadius cardBorder = BorderRadius.all(cardRadius);
  static const BorderRadius sheetBorder = BorderRadius.vertical(top: sheetRadius);
}
