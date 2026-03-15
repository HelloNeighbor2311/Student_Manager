# student_manager

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup (Do Not Commit Secrets)

This project uses Firebase/Firestore, but Firebase config files are intentionally ignored by git.

1. Install CLIs:
   - `npm install -g firebase-tools`
   - `dart pub global activate flutterfire_cli`
2. Login:
   - `firebase login --reauth --no-localhost`
3. Generate local Firebase files (not committed):
   - `flutterfire configure --project=studentmanager-7a3b5 --platforms=android,ios,web`
4. Run app normally:
   - `flutter run -d chrome`

Ignored secret-bearing files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
