# Google Sign-In Fixes for Student Manager App

## Issues Fixed

### 1. **Missing Google Sign-In Scopes**
   - **Problem**: Google Sign-In was only requesting 'email' scope
   - **Fix**: Added 'profile' scope to get full user information
   - **File**: `lib/services/auth_service.dart`

### 2. **Incomplete Error Handling**
   - **Problem**: No null checks for access token and ID token
   - **Fix**: Added explicit null checks with user-friendly error messages
   - **File**: `lib/services/auth_service.dart`

### 3. **Missing Platform-Specific Configuration**
   - **Problem**: Google Sign-In didn't specify correct client IDs for each platform
   - **Fix**: Created platform-aware initialization method
   - **File**: `lib/services/auth_service.dart`

### 4. **Missing Android Google Sign-In Activity**
   - **Problem**: AndroidManifest.xml was missing required SignInHubActivity
   - **Fix**: Added Google Sign-in activity declaration
   - **File**: `android/app/src/main/AndroidManifest.xml`

### 5. **Missing iOS Google Sign-In Configuration**
   - **Problem**: Info.plist was missing URL scheme and client ID for iOS
   - **Fix**: Added CFBundleURLTypes and GIDClientID configuration
   - **File**: `ios/Runner/Info.plist`

### 6. **Insufficient Debugging**
   - **Problem**: Hard to diagnose Google Sign-In failures
   - **Fix**: Added comprehensive debug logging throughout the flow
   - **File**: `lib/services/auth_service.dart`

## Changes Summary

### lib/services/auth_service.dart
- Added `import 'package:flutter/material.dart'` 
- Created `_initializeGoogleSignIn()` method with platform-specific setup
- Enhanced `signInWithGoogle()` with detailed error handling and logging
- Added error handling in `signOut()` method
- Improved error messages for token validation

### android/app/src/main/AndroidManifest.xml
- Added Google Sign-In activity declaration:
```xml
<activity
    android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
    android:exported="false" />
```

### ios/Runner/Info.plist
- Added CFBundleURLTypes configuration for Google Sign-In callback
- Added GIDClientID configuration pointing to iOS OAuth client

## Platform-Specific Client IDs

- **Android**: `1024315521379-g7d007m96htafspc6td4fs7e2ht8k9e1.apps.googleusercontent.com`
- **iOS**: `1024315521379-htg5572e49n4v9jflpki5nv857eeevod.apps.googleusercontent.com`

## Testing the Fix

1. **Clean the project**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Test on Android**:
   ```bash
   flutter run -d <android-device-id>
   ```

3. **Test on iOS**:
   ```bash
   flutter run -d <ios-device-id>
   ```

4. **Check Debug Logs**:
   - Look for messages starting with "Google Sign-In" or "Auth signInWithGoogle"
   - Helpful logging shows:
     - Platform detection
     - Google user email
     - Token retrieval status
     - Firebase credential creation
     - Final sign-in success/failure

## Common Issues and Solutions

### Issue: "Bạn đã hủy đăng nhập Google"
- **Cause**: User closed the Google Sign-In dialog
- **Solution**: This is expected behavior when user cancels

### Issue: "Không thể lấy access token từ Google"
- **Cause**: Authentication tokens failed to generate
- **Solution**: Ensure google-services.json and Info.plist are properly configured

### Issue: "operation-not-allowed"
- **Cause**: Google Sign-In not enabled in Firebase Console
- **Solution**: Go to Firebase Console > Authentication > Sign-in Method > Enable Google

### Issue: Token validation failures on Android
- **Cause**: Wrong Android OAuth client ID in google-services.json
- **Solution**: Regenerate google-services.json from Firebase Console with correct package name

### Issue: Token validation failures on iOS
- **Cause**: URL scheme mismatch or wrong client ID
- **Solution**: Verify CFBundleURLTypes matches your iOS bundle ID in Firebase Console

## Architecture Improvements

The `_initializeGoogleSignIn()` method now:
1. Detects the current platform (iOS, Android, Web, Desktop)
2. Uses appropriate client IDs for each platform
3. Requests proper scopes (email, profile)
4. Enables better error handling and logging

This ensures Google Sign-In works correctly across all supported platforms.

## Additional Notes

- The app uses Firebase Authentication with Google as a federated provider
- Client IDs are extracted from `google-services.json` (Android) and Firebase Console (iOS)
- All error messages are in Vietnamese as per app requirement
- Debug logging can be viewed in the Flutter console during development
