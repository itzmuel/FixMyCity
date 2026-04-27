# FixMyCity Mobile App

FixMyCity is a Flutter mobile app that lets residents report city issues such as potholes, damaged sidewalks, graffiti, and illegal dumping.

Users can:
- Create an account and sign in with email/password (Supabase Auth)
- Submit reports with description, location, and photo
- View and track their own reports
- Browse community reports and status trends

## Tech Stack

- Flutter (Dart)
- Supabase (Auth, Postgres, Storage)
- go_router for app navigation
- geolocator and geocoding for location capture and address resolution
- image_picker for photo attachments

## Prerequisites

- Flutter SDK compatible with Dart 3.7.x
- Android Studio and/or Xcode for device builds
- A Supabase project with required tables, RLS policies, and storage bucket

## Local Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Confirm your Supabase project values in main.dart:
- Supabase URL
- Supabase anon key

3. Run the app:

```bash
flutter run
```

## Auth Email Confirmation Redirect (Important)

If email confirmation opens a localhost page in production, your Supabase URL configuration is incorrect.

Use these settings in Supabase Dashboard:
- Authentication -> URL Configuration -> Site URL must be a real HTTPS URL (not localhost)
- Authentication -> URL Configuration -> Site URL: `https://fixmycityadmindashboard.vercel.app`
- Authentication -> URL Configuration -> Redirect URLs must include both:

```text
https://fixmycityadmindashboard.vercel.app/email-confirmed
fixmycityapp://login-callback/
```

When the confirmation link is clicked:
- Users are sent to a dedicated confirmation page that displays "Email Confirmed".
- Users can then return to the app and sign in.

## Quality Checks

Run before committing:

```bash
flutter analyze
flutter test test/widget_test.dart
```

## Build Commands

```bash
flutter build apk --release
flutter build appbundle --release
```

## Project Structure

```text
lib/
	app/        # Router, theme, app-level state
	models/     # Domain models
	screens/    # UI screens and flows
	services/   # Supabase, auth, issue services
	shell/      # Bottom navigation shell
	widgets/    # Shared UI widgets
supabase/
	migrations/ # SQL migration files
```

## Release and Policy Notes

See RELEASE_RUNBOOK.md for:
- Go/no-go checks
- Auth and RLS verification
- Smoke test checklist
- Play Store policy and disclaimer checklist
