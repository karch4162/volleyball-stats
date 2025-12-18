# Email Verification in Native Flutter Apps

## How It Works

When a user signs up, Supabase sends an email with a verification link. In native apps, this link needs to open your app (not a browser) and pass the verification token to Supabase.

## Flow

1. **User signs up** → Supabase sends verification email
2. **User clicks link in email** → Opens app via deep link
3. **App receives deep link** → Extracts token from URL
4. **App calls Supabase** → Verifies email using token
5. **User is verified** → Can now sign in

## Configuration Steps

### 1. Configure Deep Links in Supabase Dashboard

1. Go to **Authentication** → **URL Configuration**
2. Add your app's deep link URL to **Redirect URLs**:
   - **Android**: `com.yourapp.volleyballstats://login-callback/`
   - **iOS**: `volleyballstats://login-callback/`
   - **Web** (if applicable): `https://yourapp.com/auth/callback`

### 2. Configure Deep Links in Flutter

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:exported="true">
    <!-- Existing intent filters -->
    
    <!-- Deep link for email verification -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="com.yourapp.volleyballstats"
            android:host="login-callback" />
    </intent-filter>
</activity>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>volleyballstats</string>
        </array>
    </dict>
</array>
```

### 3. Handle Deep Links in Flutter App

The Supabase Flutter SDK can automatically handle deep links. You need to:

1. **Listen for deep links** when app is opened from a link
2. **Pass the URL to Supabase** for verification

#### Option A: Using `uni_links` or `app_links` package

Add to `pubspec.yaml`:
```yaml
dependencies:
  app_links: ^6.3.1  # Recommended for modern deep linking
```

#### Option B: Manual handling (if using go_router or similar)

Handle the deep link route and extract the token, then call Supabase to verify.

### 4. Update Supabase Initialization

The initialization in `app/lib/core/supabase.dart` is already configured for deep linking support.

## Testing

### Local Development
- Use the SQL query in `supabase/scripts/verify_user_cloud.sql` to manually verify users
- Or disable email confirmation in local config

### Production
- Test the full flow:
  1. Sign up with a real email
  2. Check email for verification link
  3. Click link (should open app)
  4. App should automatically verify and sign in user

## Alternative: Magic Link Flow

Instead of email verification, you can use Supabase's magic link flow where users click a link to sign in directly (no password needed). This is simpler for mobile apps.

## Resources

- [Supabase Deep Linking Docs](https://supabase.com/docs/guides/auth/deep-linking)
- [Flutter Deep Linking Guide](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [App Links Package](https://pub.dev/packages/app_links)

