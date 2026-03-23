# Google Sign-In on Android Emulator Guide

## ✅ What's Been Fixed

The `google-services.json` file has been successfully generated and is now at:
```
android/app/google-services.json
```

This file contains your Firebase credentials and is **required** for Google Sign-In to work on Android emulator.

## 📱 Testing on Android Emulator

### Prerequisites:
1. **Internet Connection**: Ensure the emulator has internet connectivity
   ```powershell
   adb shell ping 8.8.8.8
   ```
   If this fails, restart the emulator.

2. **Google Account**: Add a Google account to the emulator
   - Open Settings on emulator
   - Go to: Accounts > Add account > Google
   - Use a test Gmail account or your personal account
   - Complete the sign-in process

3. **Clean Build**: Run a clean rebuild
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

### Common Issues & Solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| "operation-not-allowed" error | Firebase Auth not enabled in console | Google Sign-In is properly configured in Firebase |
| "Sign-in cancelled by user" | User tapped cancel button | Normal behavior - try again |
| Authentication timeout | Emulator lost internet | Restart emulator and check connectivity |
| "Cannot get access token" | Account not properly added | Add Google account via Settings > Accounts |
| Black screen on Google login | Not a real issue if you added account | Just takes a few seconds to load |

### Debug Output:
The app logs detailed information when signing in. Check the Flutter console for:
```
Starting Google Sign-In on TargetPlatform.android
Google user signed in: your-email@gmail.com
Got authentication tokens from Google
Successfully signed in with Google
```

## 📱 Testing on iOS Simulator

1. **Add Test Account**: 
   - Settings > Accounts & Passwords > Add Account > Google
   - Enter test Gmail credentials

2. **Expected Behavior**: 
   - A web-based sign-in dialog will appear
   - Sign in and authorize the app
   - Returns to app automatically

## 🔧 Troubleshooting Steps

### Step 1: Verify Config Files
```powershell
# Should exist now:
ls -Path "android/app/google-services.json"

# Should also verify iOS config:
cat "ios/firebase_app_id_file.json"
```

### Step 2: Check Emulator Status
```powershell
# List running emulators
adb devices

# Force restart if needed
adb emu kill
# Then restart emulator
```

### Step 3: Verify Firestore Rules
Open [Firebase Console](https://console.firebase.google.com):
- Project: **studentmanager-7a3b5**
- Check: Firestore > Rules (should be set to test mode for development)
- Check: Authentication > Sign-in method (Google should be enabled)

### Step 4: Clear App Data
If issues persist, clear the app's stored authentication:
```powershell
adb shell pm clear com.example.student_manager
```

## ✨ Expected Behavior

### On First Login:
1. Tap "Đăng nhập bằng Google"
2. Google login popup appears
3. Select account or enter credentials
4. Permission request dialog appears
5. Redirects back to app and shows dashboard

### On Subsequent Logins:
1. Tap "Đăng nhập bằng Google"
2. Automatically signs in if account is already selected
3. Faster signin process (usually under 2 seconds)

## 📋 Build Configuration

Your project is configured with:
- **Android**: `com.example.student_manager`
- **iOS**: `com.example.studentManager`
- **Firebase Project**: `studentmanager-7a3b5`
- **Android Client ID**: `1024315521379-g7d007m96htafspc6td4fs7e2ht8k9e1.apps.googleusercontent.com`
- **iOS Client ID**: `1024315521379-htg5572e49n4v9jflpki5nv857eeevod.apps.googleusercontent.com`

## 🚀 Next Steps

1. Run: `flutter run` on Android emulator
2. Tap the Google Sign-In button
3. Complete the authentication flow
4. Verify you see your email address on the dashboard

If you still encounter issues, check:
- Flutter console for detailed error messages
- `logcat` output: `adb logcat | grep -i "google\|auth\|firebase"`
- Firebase Console for validation rules and errors
