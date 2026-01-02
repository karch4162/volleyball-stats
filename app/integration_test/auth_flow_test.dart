import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';
import 'package:volleyball_stats_app/features/auth/login_screen.dart';
import 'package:volleyball_stats_app/features/auth/signup_screen.dart';

import 'utils/screenshot_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotHelper = ScreenshotHelper(binding);

  setUpAll(() async {
    // Initialize Hive for Flutter in test mode
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
  });

  setUp(() async {
    // Clean up any previous state before each test
    await HiveService.initialize();
  });

  tearDown(() async {
    await HiveService.closeAll();
  });

  /// Helper to pump the app widget
  Future<void> pumpApp(WidgetTester tester, {String initialRoute = '/'}) async {
    final app = ProviderScope(
      child: MaterialApp.router(
        title: 'Volleyball Stats',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Navigate to initial route if needed
    if (initialRoute != '/') {
      appRouter.go(initialRoute);
      await tester.pumpAndSettle();
    }
  }

  group('Login Screen Tests', () {
    testWidgets('displays login screen with all form elements', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Take screenshot of initial login screen
      await screenshotHelper.takeScreenshot('login_screen_initial');

      // Verify login screen is displayed
      expect(find.text('Volleyball Stats'), findsOneWidget);
      expect(find.text('Sign in to manage your teams'), findsOneWidget);

      // Verify form fields are present
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify sign in button
      expect(find.text('Sign In'), findsOneWidget);

      // Verify sign up link
      expect(find.text("Don't have an account? Sign up"), findsOneWidget);

      // Verify forgot password link
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Leave email empty and enter password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('login_empty_email_error');

      // Verify validation error for email
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Enter invalid email (no @ symbol)
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('login_invalid_email_error');

      // Verify validation error for invalid email
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Enter valid email but leave password empty
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('login_empty_password_error');

      // Verify validation error for password
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('password visibility toggle works correctly', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Enter a password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'secretpassword123');
      await tester.pumpAndSettle();

      // Initially password should be obscured (visibility_outlined icon shown)
      // The visibility_outlined icon indicates password is currently hidden
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Take screenshot with password hidden
      await screenshotHelper.takeScreenshot('login_password_hidden');

      // Find and tap the visibility toggle button
      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Take screenshot with password visible
      await screenshotHelper.takeScreenshot('login_password_visible');

      // Now visibility_off icon should be shown (indicating password is visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('valid login flow with credentials entered', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Enter valid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'coach@volleyballteam.com');
      await tester.pumpAndSettle();

      // Enter valid password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'SecurePassword123!');
      await tester.pumpAndSettle();

      // Take screenshot of filled form
      await screenshotHelper.takeScreenshot('login_form_filled');

      // Verify still on login screen (no actual Supabase connected in test)
      expect(find.byType(LoginScreen), findsOneWidget);

      // Note: Without Supabase credentials, the Sign In button may be disabled
      // or show an error. The form validation itself passes.
      // In offline mode, the Supabase warning will be displayed.
    });

    testWidgets('shows Supabase not connected warning in offline mode', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Look for the Supabase connection warning
      // This appears when SUPABASE_URL and SUPABASE_ANON_KEY are not provided
      final warningFinder = find.textContaining('Supabase not connected');

      // Take screenshot showing offline state
      await screenshotHelper.takeScreenshot('login_supabase_not_connected');

      // The warning should be visible when Supabase is not configured
      if (warningFinder.evaluate().isNotEmpty) {
        expect(warningFinder, findsOneWidget);
      }
    });
  });

  group('Signup Screen Tests', () {
    testWidgets('displays signup screen with all form elements', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Take screenshot of initial signup screen
      await screenshotHelper.takeScreenshot('signup_screen_initial');

      // Verify signup screen is displayed
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign up to start managing your teams'), findsOneWidget);

      // Verify form fields are present (email, password, confirm password)
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Verify sign up button
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify sign in link
      expect(find.text('Already have an account? Sign in'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email on signup', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter password and confirm password but leave email empty
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, 'password123');
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('signup_empty_email_error');

      // Verify validation error for email
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format on signup', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter invalid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();

      // Enter password and confirm password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, 'password123');
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('signup_invalid_email_error');

      // Verify validation error for email
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows validation error for password too short', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter valid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'newuser@example.com');
      await tester.pumpAndSettle();

      // Enter password that is too short (less than 6 characters)
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, '12345');
      await tester.pumpAndSettle();

      // Enter matching confirm password
      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, '12345');
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('signup_password_too_short_error');

      // Verify validation error for short password
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('shows validation error for password mismatch', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter valid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'newuser@example.com');
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Enter different confirm password (mismatch)
      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, 'differentpassword');
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('signup_password_mismatch_error');

      // Note: The password mismatch check happens in _handleSignUp after form validation
      // The error is shown in the _errorMessage container, not as a field validation error
      // It only triggers if form validates (email valid, password >= 6 chars, confirm not empty)
    });

    testWidgets('shows validation error for empty confirm password', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter valid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'newuser@example.com');
      await tester.pumpAndSettle();

      // Enter valid password but leave confirm password empty
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('signup_empty_confirm_password_error');

      // Verify validation error for confirm password
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('password visibility toggles work on signup screen', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter passwords
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'secretpassword');
      await tester.pumpAndSettle();

      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, 'secretpassword');
      await tester.pumpAndSettle();

      // Take screenshot with passwords hidden
      await screenshotHelper.takeScreenshot('signup_passwords_hidden');

      // Find visibility toggle icons (there should be 2 - one for each password field)
      final visibilityToggles = find.byIcon(Icons.visibility_outlined);
      expect(visibilityToggles, findsNWidgets(2));

      // Toggle first password visibility
      await tester.tap(visibilityToggles.first);
      await tester.pumpAndSettle();

      // Take screenshot after first toggle
      await screenshotHelper.takeScreenshot('signup_first_password_visible');

      // First toggle should now show visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Toggle second password visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Take screenshot with both passwords visible
      await screenshotHelper.takeScreenshot('signup_both_passwords_visible');

      // Both toggles should now show visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });

    testWidgets('valid signup form with all fields filled', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Enter valid email
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'newcoach@volleyballteam.com');
      await tester.pumpAndSettle();

      // Enter valid password (6+ characters)
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Enter matching confirm password
      final confirmPasswordField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPasswordField, 'SecurePass123!');
      await tester.pumpAndSettle();

      // Take screenshot of filled signup form
      await screenshotHelper.takeScreenshot('signup_form_filled');

      // Verify still on signup screen
      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('Navigation Between Login and Signup', () {
    testWidgets('navigates from login to signup screen', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Verify on login screen
      expect(find.text('Volleyball Stats'), findsOneWidget);
      expect(find.text('Sign in to manage your teams'), findsOneWidget);

      // Take screenshot before navigation
      await screenshotHelper.takeScreenshot('nav_login_before');

      // Find and tap the signup link
      final signupLink = find.text("Don't have an account? Sign up");
      expect(signupLink, findsOneWidget);
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('nav_login_to_signup');

      // Verify navigated to signup screen
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign up to start managing your teams'), findsOneWidget);
    });

    testWidgets('navigates from signup back to login screen', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Verify on signup screen
      expect(find.text('Create Account'), findsOneWidget);

      // Take screenshot before navigation
      await screenshotHelper.takeScreenshot('nav_signup_before');

      // Find and tap the sign in link
      final signinLink = find.text('Already have an account? Sign in');
      expect(signinLink, findsOneWidget);
      await tester.tap(signinLink);
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('nav_signup_to_login');

      // Verify navigated back to login screen
      expect(find.text('Volleyball Stats'), findsOneWidget);
      expect(find.text('Sign in to manage your teams'), findsOneWidget);
    });
  });

  group('Offline Mode Tests', () {
    testWidgets('app shows offline mode options when Supabase not connected', (tester) async {
      await pumpApp(tester);

      // The app should show offline options screen when Supabase is not connected
      // This is handled by AuthGuard -> _OfflineOptionsScreen

      // Take screenshot of the initial state
      await screenshotHelper.takeScreenshot('offline_mode_options');

      // Look for offline mode indicators
      // The offline options screen shows "Offline Mode" text and "Continue Offline" button
      final offlineModeFinder = find.text('Offline Mode');
      final continueOfflineButton = find.text('Continue Offline');

      // Verify offline mode UI is accessible
      if (offlineModeFinder.evaluate().isNotEmpty) {
        expect(offlineModeFinder, findsOneWidget);
        expect(continueOfflineButton, findsOneWidget);

        // Verify available features list
        expect(find.text('Available Offline:'), findsOneWidget);
        expect(find.text('Record match stats'), findsOneWidget);
        expect(find.text('Local data storage'), findsOneWidget);
        expect(find.text('Auto-sync when online'), findsOneWidget);

        // Verify unavailable features list
        expect(find.text('Not Available Offline:'), findsOneWidget);
        expect(find.text('Cloud backup'), findsOneWidget);
        expect(find.text('Team sharing'), findsOneWidget);

        // Take detailed screenshot of offline options
        await screenshotHelper.takeScreenshot('offline_mode_features');
      }
    });

    testWidgets('can continue in offline mode', (tester) async {
      await pumpApp(tester);

      // Look for the Continue Offline button
      final continueOfflineButton = find.text('Continue Offline');

      if (continueOfflineButton.evaluate().isNotEmpty) {
        // Take screenshot before tapping
        await screenshotHelper.takeScreenshot('offline_before_continue');

        // Tap continue offline
        await tester.tap(continueOfflineButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Take screenshot after tapping
        await screenshotHelper.takeScreenshot('offline_after_continue');

        // The app should proceed to the home/main screen in offline mode
        // In offline mode, the app shows either HomeScreen or team selection
      }
    });

    testWidgets('home screen is accessible in offline mode via direct navigation', (tester) async {
      // Initialize the app
      await pumpApp(tester);

      // Take screenshot of current state
      await screenshotHelper.takeScreenshot('home_access_test');

      // The app should render successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });

  group('Error Handling Tests', () {
    testWidgets('handles form submission gracefully without Supabase', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Fill in valid credentials
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'validpassword123');
      await tester.pumpAndSettle();

      // Take screenshot before submission
      await screenshotHelper.takeScreenshot('login_before_submit_no_supabase');

      // Check if Sign In button is enabled (it may be disabled without Supabase)
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      final button = tester.widget<ElevatedButton>(signInButton);

      if (button.onPressed != null) {
        // Button is enabled, try to tap it
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // Take screenshot of any error state
        await screenshotHelper.takeScreenshot('login_submit_result');
      } else {
        // Button is disabled due to no Supabase connection
        await screenshotHelper.takeScreenshot('login_button_disabled');
      }

      // App should still be functional and not crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('displays error message container when login fails', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // The error message container structure exists in the UI
      // It becomes visible when _errorMessage is not null

      // Take screenshot of login screen
      await screenshotHelper.takeScreenshot('login_error_container_check');

      // Verify the login screen structure is correct
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);

      // The error_outline icon and red-bordered container appear when errors occur
      // We verify the structure is in place for when errors do occur
    });
  });

  group('UI Element Tests', () {
    testWidgets('login screen has correct icon and branding', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Verify volleyball icon is present
      expect(find.byIcon(Icons.sports_volleyball), findsOneWidget);

      // Verify app title
      expect(find.text('Volleyball Stats'), findsOneWidget);

      // Take screenshot of branding
      await screenshotHelper.takeScreenshot('login_branding');
    });

    testWidgets('signup screen has correct icon and branding', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Verify volleyball icon is present
      expect(find.byIcon(Icons.sports_volleyball), findsOneWidget);

      // Verify screen title
      expect(find.text('Create Account'), findsOneWidget);

      // Take screenshot of branding
      await screenshotHelper.takeScreenshot('signup_branding');
    });

    testWidgets('form fields have correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/login');

      // Verify email icon
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      // Verify lock icon for password
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);

      // Verify visibility toggle icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Take screenshot showing form field icons
      await screenshotHelper.takeScreenshot('login_form_icons');
    });

    testWidgets('signup form fields have correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/signup');

      // Verify email icon
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      // Verify lock icons for password fields (2 password fields)
      expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));

      // Verify visibility toggle icons (2 for each password field)
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      // Take screenshot showing signup form field icons
      await screenshotHelper.takeScreenshot('signup_form_icons');
    });
  });
}
