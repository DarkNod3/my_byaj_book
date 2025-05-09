# Setting Up Firebase Phone Authentication with In-App reCAPTCHA Verification

This guide will explain how to set up Firebase Phone Authentication in your Flutter app to ensure reCAPTCHA verification happens within your app UI instead of redirecting to an external browser.

## Prerequisites

- Firebase project set up in Firebase Console
- Flutter app with Firebase authentication configured
- SHA-1 and SHA-256 certificate fingerprints added to your Firebase project

## 1. Enable Android DeviceCheck API in Google Cloud Console

Firebase SafetyNet-based reCAPTCHA verification requires the Android DeviceCheck API to be enabled for your project:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "API & Services" > "Library"
4. Search for "Android Device Verification API"
5. Click on it and then click "Enable"

## 2. Add SHA Certificate Fingerprints to Your Firebase Project

Firebase needs your app's SHA fingerprints to verify the app identity:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings
4. Under the "Your apps" section, find your Android app
5. Add both SHA-1 and SHA-256 certificate fingerprints
   - For debug builds, you can get these by running: `./gradlew signingReport`
   - For release builds, use the keys from your release keystore

## 3. Ensure Proper Dependencies

Make sure you have the required dependencies in your Flutter project:

```yaml
dependencies:
  firebase_core: ^x.x.x
  firebase_auth: ^x.x.x
```

In your Android app's `build.gradle` (app-level), add the following dependency:

```gradle
dependencies {
  // ... other dependencies
  implementation "androidx.browser:browser:1.4.0"
}
```

## 4. Implement Phone Authentication

When implementing the Firebase phone authentication flow:

1. Simply use the standard `verifyPhoneNumber` method without providing any custom reCAPTCHA verifier
2. Firebase will automatically use SafetyNet for verification on compatible Android devices
3. The verification will happen within your app, without launching an external browser

Basic implementation:

```dart
FirebaseAuth auth = FirebaseAuth.instance;

auth.verifyPhoneNumber(
  phoneNumber: '+1234567890',
  verificationCompleted: (PhoneAuthCredential credential) async {
    // Auto-verification or verification complete
    await auth.signInWithCredential(credential);
  },
  verificationFailed: (FirebaseAuthException e) {
    // Handle verification failure
  },
  codeSent: (String verificationId, int? resendToken) {
    // Handle code sent - store verificationId for later use
  },
  codeAutoRetrievalTimeout: (String verificationId) {
    // Handle timeout
  },
);
```

## Troubleshooting

If you still see browser-based reCAPTCHA verification:

1. **Check SafetyNet Availability**: Ensure the device has Google Play Services installed
2. **Verify API Enablement**: Make sure you've enabled the Android Device Verification API in Google Cloud Console
3. **Confirm SHA Fingerprints**: Verify that the correct SHA fingerprints are added to your Firebase project
4. **Network Issues**: Ensure the device has a stable internet connection
5. **Test on Physical Device**: Emulators may not fully support SafetyNet services

If the issue persists, you can implement a fallback UI-based verification mechanism as shown in the app. 