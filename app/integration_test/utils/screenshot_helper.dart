import 'dart:io';

import 'package:integration_test/integration_test.dart';

/// Helper for taking screenshots during integration tests
class ScreenshotHelper {
  ScreenshotHelper(this.binding);

  final IntegrationTestWidgetsFlutterBinding binding;

  /// Directory where screenshots will be saved
  static const String screenshotDir = 'screenshots';

  /// Take a screenshot with the given name
  /// Screenshots are saved to app/screenshots/ with a timestamp
  Future<void> takeScreenshot(String name) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${name}_$timestamp.png';

    // Ensure screenshots directory exists
    final dir = Directory(screenshotDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Take the screenshot
    await binding.takeScreenshot(fileName);
  }

  /// Take a screenshot with a simple name (no timestamp)
  Future<void> takeSimpleScreenshot(String name) async {
    // Ensure screenshots directory exists
    final dir = Directory(screenshotDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    await binding.takeScreenshot('$name.png');
  }

  /// Take a numbered screenshot for step-by-step documentation
  Future<void> takeStepScreenshot(String testName, int stepNumber, String stepDescription) async {
    final fileName = '${testName}_step${stepNumber.toString().padLeft(2, '0')}_$stepDescription';
    await takeSimpleScreenshot(fileName);
  }
}

/// Extension to easily create a ScreenshotHelper from the binding
extension ScreenshotBindingExtension on IntegrationTestWidgetsFlutterBinding {
  ScreenshotHelper get screenshotHelper => ScreenshotHelper(this);
}
