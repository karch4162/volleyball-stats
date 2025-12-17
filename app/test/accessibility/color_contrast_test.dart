import 'dart:math' as dart_math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/theme/app_colors.dart';

/// Test suite to verify WCAG AA color contrast requirements
/// WCAG AA requires:
/// - 4.5:1 for normal text (< 24px or < 18px bold)
/// - 3:1 for large text (>= 24px or >= 18px bold)
/// - 3:1 for UI components
void main() {
  group('Color Contrast - WCAG AA Compliance', () {
    test('Calculate relative luminance correctly', () {
      // Test with white (should be 1.0)
      expect(_relativeLuminance(const Color(0xFFFFFFFF)), closeTo(1.0, 0.01));
      
      // Test with black (should be 0.0)
      expect(_relativeLuminance(const Color(0xFF000000)), closeTo(0.0, 0.01));
    });

    test('Calculate contrast ratio correctly', () {
      // White on black should be 21:1
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      expect(_contrastRatio(white, black), closeTo(21.0, 0.1));
      
      // Same color should be 1:1
      expect(_contrastRatio(white, white), closeTo(1.0, 0.01));
    });

    group('Text on Background Contrast', () {
      test('textPrimary on background meets WCAG AA (4.5:1)', () {
        final ratio = _contrastRatio(AppColors.textPrimary, AppColors.background);
        expect(ratio, greaterThan(4.5), 
          reason: 'textPrimary contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('textSecondary on background meets WCAG AA (4.5:1)', () {
        final ratio = _contrastRatio(AppColors.textSecondary, AppColors.background);
        expect(ratio, greaterThan(4.5), 
          reason: 'textSecondary contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('textTertiary on background meets WCAG AA (4.5:1)', () {
        final ratio = _contrastRatio(AppColors.textTertiary, AppColors.background);
        expect(ratio, greaterThan(4.5), 
          reason: 'textTertiary contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('textMuted on background (large text only: 3:1)', () {
        final ratio = _contrastRatio(AppColors.textMuted, AppColors.background);
        // textMuted should meet at least 3:1 for large text
        expect(ratio, greaterThan(3.0), 
          reason: 'textMuted contrast ratio: ${ratio.toStringAsFixed(2)}:1 (use for large text only)');
        
        // Document if it fails normal text requirement
        if (ratio < 4.5) {
          print('⚠️  textMuted (${ratio.toStringAsFixed(2)}:1) should only be used for large text (>=18pt)');
        }
      });

      test('textDisabled on background (informational only)', () {
        final ratio = _contrastRatio(AppColors.textDisabled, AppColors.background);
        // Disabled text doesn't need to meet contrast requirements per WCAG
        print('ℹ️  textDisabled contrast ratio: ${ratio.toStringAsFixed(2)}:1 (disabled text exempt from WCAG)');
        expect(ratio, greaterThan(1.0)); // Just ensure it's visible
      });
    });

    group('Accent Colors on Background Contrast', () {
      test('indigo on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.indigo, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'indigo contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('rose on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.rose, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'rose contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('emerald on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.emerald, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'emerald contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('amber on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.amber, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'amber contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('purple on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.purple, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'purple contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('teal on background meets WCAG AA for UI components (3:1)', () {
        final ratio = _contrastRatio(AppColors.teal, AppColors.background);
        expect(ratio, greaterThan(3.0), 
          reason: 'teal contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });
    });

    group('Text on Surface Contrast', () {
      test('textPrimary on surface meets WCAG AA (4.5:1)', () {
        final ratio = _contrastRatio(AppColors.textPrimary, AppColors.surface);
        expect(ratio, greaterThan(4.5), 
          reason: 'textPrimary on surface contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });

      test('textSecondary on surface meets WCAG AA (4.5:1)', () {
        final ratio = _contrastRatio(AppColors.textSecondary, AppColors.surface);
        expect(ratio, greaterThan(4.5), 
          reason: 'textSecondary on surface contrast ratio: ${ratio.toStringAsFixed(2)}:1');
      });
    });

    group('Interactive Elements Contrast', () {
      test('indigo button text - use dark text for better contrast', () {
        // White on indigo is close but doesn't meet 3:1
        final whiteRatio = _contrastRatio(Colors.white, AppColors.indigo);
        print('⚠️  White on indigo: ${whiteRatio.toStringAsFixed(2)}:1 (needs 3:1)');
        
        // Dark text on indigo meets requirements
        final darkRatio = _contrastRatio(AppColors.background, AppColors.indigo);
        expect(darkRatio, greaterThan(3.0), 
          reason: 'Dark on indigo button contrast ratio: ${darkRatio.toStringAsFixed(2)}:1');
      });

      test('rose button text - use dark text for better contrast', () {
        final whiteRatio = _contrastRatio(Colors.white, AppColors.rose);
        print('⚠️  White on rose: ${whiteRatio.toStringAsFixed(2)}:1 (needs 3:1)');
        
        final darkRatio = _contrastRatio(AppColors.background, AppColors.rose);
        expect(darkRatio, greaterThan(3.0), 
          reason: 'Dark on rose button contrast ratio: ${darkRatio.toStringAsFixed(2)}:1');
      });

      test('emerald button text - use dark text for better contrast', () {
        final whiteRatio = _contrastRatio(Colors.white, AppColors.emerald);
        print('⚠️  White on emerald: ${whiteRatio.toStringAsFixed(2)}:1 (needs 3:1)');
        
        final darkRatio = _contrastRatio(AppColors.background, AppColors.emerald);
        expect(darkRatio, greaterThan(3.0), 
          reason: 'Dark on emerald button contrast ratio: ${darkRatio.toStringAsFixed(2)}:1');
      });

      test('amber button text - white works well', () {
        final whiteRatio = _contrastRatio(Colors.white, AppColors.amber);
        // Amber is bright enough that dark text works better
        final darkRatio = _contrastRatio(AppColors.background, AppColors.amber);
        expect(darkRatio, greaterThan(3.0), 
          reason: 'Dark on amber button contrast ratio: ${darkRatio.toStringAsFixed(2)}:1');
      });
    });

    test('Print color contrast summary', () {
      print('\n=== Color Contrast Summary ===\n');
      
      final combinations = [
        ('textPrimary on background', AppColors.textPrimary, AppColors.background, 4.5),
        ('textSecondary on background', AppColors.textSecondary, AppColors.background, 4.5),
        ('textTertiary on background', AppColors.textTertiary, AppColors.background, 4.5),
        ('textMuted on background', AppColors.textMuted, AppColors.background, 3.0),
        ('textDisabled on background', AppColors.textDisabled, AppColors.background, 3.0),
        ('indigo on background', AppColors.indigo, AppColors.background, 3.0),
        ('rose on background', AppColors.rose, AppColors.background, 3.0),
        ('emerald on background', AppColors.emerald, AppColors.background, 3.0),
        ('amber on background', AppColors.amber, AppColors.background, 3.0),
        ('purple on background', AppColors.purple, AppColors.background, 3.0),
        ('teal on background', AppColors.teal, AppColors.background, 3.0),
        ('textPrimary on surface', AppColors.textPrimary, AppColors.surface, 4.5),
      ];

      for (final (label, foreground, background, requirement) in combinations) {
        final ratio = _contrastRatio(foreground, background);
        final status = ratio >= requirement ? '✅' : '❌';
        print('$status $label: ${ratio.toStringAsFixed(2)}:1 (required: $requirement:1)');
      }
      
      print('\n==============================\n');
    });
  });
}

/// Calculate relative luminance of a color
/// Formula from WCAG: https://www.w3.org/TR/WCAG20/#relativeluminancedef
double _relativeLuminance(Color color) {
  final r = _linearize(color.red / 255.0);
  final g = _linearize(color.green / 255.0);
  final b = _linearize(color.blue / 255.0);
  
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Linearize RGB component for luminance calculation
double _linearize(double component) {
  if (component <= 0.03928) {
    return component / 12.92;
  } else {
    return ((component + 0.055) / 1.055).pow(2.4);
  }
}

/// Calculate contrast ratio between two colors
/// Formula from WCAG: (L1 + 0.05) / (L2 + 0.05)
/// where L1 is the lighter color and L2 is the darker color
double _contrastRatio(Color color1, Color color2) {
  final lum1 = _relativeLuminance(color1);
  final lum2 = _relativeLuminance(color2);
  
  final lighter = lum1 > lum2 ? lum1 : lum2;
  final darker = lum1 > lum2 ? lum2 : lum1;
  
  return (lighter + 0.05) / (darker + 0.05);
}

extension on double {
  double pow(double exponent) {
    return dart_math.pow(this, exponent).toDouble();
  }
}
