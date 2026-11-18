import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/theme/app_branding.dart';

void main() {
  group('AppBranding Tests', () {
    test('defines correct application branding constants', () {
      expect(AppBranding.appName, 'MyBudget');
      expect(AppBranding.appSubtitle, 'Personal Budget Tracker');
      expect(AppBranding.appIconAsset, 'assets/branding/app_icon.png');
      expect(AppBranding.splashBackgroundColor, Colors.white);
      expect(AppBranding.brandBlue, const Color(0xFF2563EB));
      expect(AppBranding.brandPurple, const Color(0xFF7C3AED));
      expect(AppBranding.brandGradient.colors, [
        const Color(0xFF2563EB),
        const Color(0xFF7C3AED),
      ]);
    });
  });
}
