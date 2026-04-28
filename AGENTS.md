# AGENTS.md

## Quick Reference

```bash
# Install + analyze + test
flutter pub get
flutter analyze
flutter test test/widget_test.dart

# Build
flutter build apk --release
flutter build appbundle --release

# Regenerate app icon / splash screen after asset changes
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Photo validation tuning CLI
dart run bin/tune_photo_validation.dart <photo.jpg> --category=pothole --description="Large pothole"
```

## Architecture

- **Flutter** (Dart 3.7.x) mobile app using `go_router` with auth-guarded navigation.
- **Supabase** backend: Auth, Postgres (`public.issues`, `public.admins`, `public.report_moderation_events`), Storage (`issue-photos` bucket), Edge Functions.
- **Entrypoint**: `lib/main.dart` — initializes Supabase, runs `FixMyCityApp` (MaterialApp.router).
- **Router** (`lib/app/router.dart`): Unauthenticated → `/auth`; authenticated → `AppShell` with bottom nav (`/home`, `/report`, `/my-reports`, `/community-reports`, `/help`).
- **Supabase config**: `supabase/config.toml` — local dev project_id is `fixmycity_app`.
- **Supabase migrations**: `supabase/migrations/` — apply with `supabase db push` or Supabase CLI.
- **Moderation server**: Separate Express app in `moderation-server/` deployed to Render (`render.yaml`). Uses OpenAI Vision (`gpt-4-vision-preview`).

## Photo Moderation Pipeline (Order Matters)

Report submission runs these checks in sequence:

1. **Local validation** (`lib/services/upload_validation.dart`): extension, MIME, file size (5MB), face detection (ML Kit), brightness/blur, civic relevance heuristic.
2. **Edge Function** (`supabase/functions/moderate-report-photo/index.ts`): server-side moderation via configurable external provider URL, or local `localHeuristicModeration` fallback. **Fail-open**: if the Edge Function errors or the provider is unreachable, the report is allowed through.
3. **Analytics** (`report_moderation_analytics_service.dart`): logs decisions to `public.report_moderation_events` table (silently skips if table is absent).

Tunable thresholds are documented in `PHOTO_VALIDATION_TUNING.md`.

## Supabase Local Dev

```bash
supabase start       # starts local Postgres, Auth, Storage, Edge Functions
supabase db push     # applies migrations to local DB
supabase db reset    # resets local DB and re-runs migrations + seeds
```

## Database Notes

- **RLS enforced** on `issues`, `admins`, `report_moderation_events`, and storage objects.
- Citizens can only read/write their own issues via RLS. Community stats/reports use `SECURITY DEFINER` RPC functions (`get_community_issue_stats`, `get_community_recent_reports`, `get_community_reports`) to bypass citizen-only RLS.
- The `issues` table may have either `photo_url` or `photo_path` column — `issue_service.dart` has fallback logic for `PGRST204` errors on column mismatch.
- Admin seed: user UUID `14ca06dd-6504-4e1d-81f3-54badb711025` is inserted as admin in migration `20260225_enable_rls_issues.sql`.
- **Issue deletion**: Soft-blocked — `deleteByIds` throws `UnsupportedError`. No DELETE RLS policy exists.

## Test Setup

Single widget test in `test/widget_test.dart`:
- Initializes `Supabase` with hardcoded project URL/anonKey (shared with `main.dart`).
- Mocks `SharedPreferences`.
- Tests that unauthenticated user is routed to login screen.

## Gotchas

- **Anonymous auth must be disabled in production** — manual step in Supabase Dashboard (Auth → Providers → Anonymous → Disable).
- **Supabase URL + anonKey** are hardcoded in both `lib/main.dart` and `test/widget_test.dart`. Keep them in sync.
- **Email confirmation** redirects to `https://fixmycityadmindashboard.vercel.app/email-confirmed` — Auth URL Configuration must be set in Supabase Dashboard.
- The `auth_service.dart` also uses the custom `fixmycityapp://login-callback/` deep-link scheme.
- **Edge Function is fail-open**: reports are never blocked by moderation server outages.
