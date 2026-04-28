# FixMyCity Mobile App Release Runbook

## 1) Go/No-Go Critical Gates

All items below must be complete before submitting a build.

1. Supabase Auth settings
- Email provider enabled.
- Anonymous sign-in disabled (manual dashboard step).
- If email confirmation is enabled, user onboarding copy is clear in app.
- Authentication URL Configuration:
   - Supabase Dashboard -> Authentication -> URL Configuration -> Site URL must not be localhost in production.
   - Add both redirect URLs to Redirect URLs:
     - `https://fixmycityadmindashboard.vercel.app/email-confirmed`
     - `fixmycityapp://login-callback/`

2. Database policies
- RLS enabled on `public.issues` and `public.admins`.
- Citizens can insert and read only their own issues.
- Only admins can update issue status.

3. App behavior
- Unauthenticated users are redirected to login.
- Report submission requires signed-in user.
- No mock issue fallback path used for submission.

## 2) Local Validation Commands

Run from project root.

```bash
flutter analyze
flutter test test/widget_test.dart
```

Optional build checks:

```bash
flutter build apk --release
flutter build appbundle --release
```

## 3) Permissions Verification

Android manifest must include:
- `android.permission.INTERNET`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.CAMERA`

iOS Info.plist must include:
- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 4) Icon and Splash Workflow

Configured in `pubspec.yaml` under:
- `flutter_launcher_icons`
- `flutter_native_splash`

Regenerate after image changes:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 5) End-to-End Smoke Test (Real Device)

Test with at least one Android device and one iOS device.

1. Create account.
2. Sign in with email/password.
3. Start report flow.
4. Capture or upload photo.
5. Use current location and confirm address.
6. Submit report.
7. Confirm report appears in My Reports.
8. Confirm app handles offline or API failure with clear message.

## 6) Known Manual Step (Not in Repo)

Disable anonymous auth in Supabase Dashboard:
- Supabase Dashboard -> Authentication -> Providers -> Anonymous -> Disable.

If users see "localhost can't be reached" after email confirmation:
- Supabase Dashboard -> Authentication -> URL Configuration.
- Replace localhost Site URL with a real HTTPS URL used by your project.
- Ensure Redirect URLs includes `https://fixmycityadmindashboard.vercel.app/email-confirmed` and `fixmycityapp://login-callback/`.

## 7) Failed to Fetch Triage

If users report "Failed to fetch" or connectivity issues:

1. Verify network connection on device.
2. Verify Supabase project URL and anon key in app build.
3. Confirm Supabase REST endpoint responds:
   - `GET /rest/v1/issues?select=id&limit=1`
4. Check Supabase status and project health.
5. Check browser/device proxy, VPN, firewall, or captive portal.

## 8) Release Artifact Checklist

1. Increment `version` in `pubspec.yaml`.
2. Build signed release artifact.
3. Upload to store console.
4. Attach release notes with known limitations.
5. Record git commit SHA used for the build.

## 9) Misleading Claims Policy Checklist (Play Store)

Complete all items before submitting to Google Play.

1. In-app disclaimer is visible on Home and Help screens.
2. In-app links to official sources are visible and functional.
3. Store listing includes at least one official government source URL.
4. Store listing includes non-government disclaimer text.

Recommended Play Console text:

- **Disclaimer (add near top of description):**
   "FixMyCity is an independent civic reporting app and does not represent any government entity. For official information and services, use your municipality's official channels."

- **Official Sources (replace with your city links if needed):**
   - https://www.kitchener.ca/en/living-in-kitchener/report-a-problem.aspx
   - https://www.ontario.ca/page/municipalities
