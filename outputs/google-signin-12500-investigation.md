# Google Sign-In Error 12500 Investigation

**Date:** 2025-01-22  
**App:** NEET Mitos (`com.neetmitosis.app`)  
**Flutter google_sign_in:** ^6.2.1  
**Supabase:** ^2.12.4  
**Device:** Samsung Galaxy A56 5G (RZCY926J1FK)

---

## 1. Symptom

- Tapping **Continue with Google** shows: `Google sign-in failed. Please try again.`
- Detailed logs show error code `12500` (`sign_in_failed`) from `GoogleSignIn.signIn()`.
- Failure happens **before Supabase is contacted**, so this is a native Google Sign-In configuration issue, not a Supabase issue.

---

## 2. Evidence From Codebase

| File | Relevant Detail |
|---|---|
| `lib/core/services/google_auth_service.dart` | Uses `google_sign_in` directly; passes `serverClientId: AppConfig.googleServerClientId` |
| `lib/core/config/app_config.dart` | Reads `GOOGLE_SERVER_CLIENT_ID` from `.env` |
| `.env` | `GOOGLE_SERVER_CLIENT_ID=632848421620-s2ibacvf2if5bo3673p5m6msp0r8g5mj.apps.googleusercontent.com` |
| `android/app/google-services.json` | Exists but `oauth_client: []` is empty |
| `android/app/build.gradle.kts` | No `com.google.gms.google-services` plugin applied |
| Debug keystore | SHA-1 = `49162e9ff8e0a2f61a7fd4b1ea1d37ca2c00e53` |
| Conversation history | User created Google Cloud Console OAuth client with package `com.neetmitosis.app` and SHA-1 above; mentioned Client ID `632848421620-ppjjin0jo00et6clsjos2tded00vv13b.apps.googleusercontent.com` |

### Critical Mismatch Found

The Client ID stored in `.env` does **not** match the Client ID the user reported creating in Google Cloud Console:

- `.env` value: `632848421620-**s2ibacvf2if5bo3673p5m6msp0r8g5mj**`
- Reported GCloud client: `632848421620-**ppjjin0jo00et6clsjos2tded00vv13b**`

This is a **different OAuth client** (different suffix = different client type or project). Using the wrong client ID in `serverClientId` will cause the Google Sign-In SDK to reject the request with 12500.

---

## 3. Root Cause Analysis

Error 12500 in `google_sign_in` on Android is almost always one of:

1. **SHA-1 / package name mismatch** in Google Cloud Console OAuth client.
2. **Wrong `serverClientId`** — the `google_sign_in` package requires a **Web application client ID** for Android when fetching an ID token, not the Android client ID.
3. **Google Play Services outdated** on the test device.
4. **Empty/missing OAuth client registration** — the `google-services.json` has `oauth_client: []`, which means no OAuth client is registered in the Firebase/Google Cloud project metadata.

In our case, the strongest evidence is **#2 + #4**:

- The `google-services.json` has empty `oauth_client: []`, so even if Firebase were wired, no client would be registered.
- The `serverClientId` in `.env` appears to be an Android client ID, but `google_sign_in` on Android expects the **Web client ID** when requesting an ID token for server-side verification (Supabase in this case).
- There is also a direct mismatch between the `.env` client ID and the client ID the user created.

---

## 4. Recommended Fix

### Step 1 — Verify Google Cloud Console OAuth Clients
In **Google Cloud Console > APIs & Services > Credentials**, ensure you have **two** OAuth clients:

1. **Android client**
   - Type: Android
   - Package name: `com.neetmitosis.app`
   - SHA-1: `49162e9ff8e0a2f61a7fd4b1ea1d37ca2c00e53`
2. **Web client**
   - Type: Web application
   - Name: something like `NEET Mitos Web Client`
   - Authorized redirect URIs: can be left blank for native sign-in

### Step 2 — Update `.env` with the Web Client ID
Replace the current `GOOGLE_SERVER_CLIENT_ID` with the **Web application client ID** from Google Cloud Console.

Example (replace with your actual web client ID):
```env
GOOGLE_SERVER_CLIENT_ID=632848421620-ppjjin0jo00et6clsjos2tded00vv13b.apps.googleusercontent.com
```

### Step 3 — Update Supabase Dashboard Google Provider
In **Supabase Dashboard > Authentication > Providers > Google**:
- Set **Client ID** to the same **Web application client ID**.
- Ensure the provider toggle is **Enabled**.

### Step 4 — Rebuild and Test
```bash
cd C:/Users/ankar/neet_mitos
flutter clean
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Step 5 — Optional: Remove Empty `google-services.json`
Since the app does **not** use Firebase Auth or the Google Services Gradle plugin, you can delete `android/app/google-services.json` to avoid confusion. The `google_sign_in` package uses the Google Play Services SDK directly and does not require this file.

---

## 5. Why This Fix Works

- `google_sign_in` on Android needs `serverClientId` to be a **Web client ID** so it can request an ID token for a server-side audience. Supplying an Android client ID here causes the native SDK to return 12500.
- Supabase then verifies that ID token against the same Web client ID configured in the Supabase Dashboard.
- The Android client ID is still needed implicitly for the Google Sign-In app verification, but it does **not** belong in the `serverClientId` field.

---

## 6. Status

| Check | Result |
|---|---|
| `.env` client ID matches GCloud web client | **MISMATCH** |
| SHA-1 registered for debug keystore | **Likely yes** (user-added) |
| `google-services.json` contains OAuth clients | **NO** (`oauth_client: []`) |
| `google_sign_in` `serverClientId` set | **Yes** |
| Supabase Google provider enabled | **Unverified** |
| Google Play Services on device | **Unverified** |

**Next action:** Update `.env` with the Web client ID from Google Cloud Console and rebuild.
