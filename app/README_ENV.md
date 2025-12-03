# Environment Variables Setup

This app supports loading Supabase credentials from a `.env` file in the `app/` directory.

## Setup

1. Create a `.env` file in the `app/` directory (same level as `pubspec.yaml`)

2. Add your Supabase credentials:
```env
SUPABASE_API_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

3. Get your credentials from:
   - Supabase Dashboard → Settings → API
   - **Important**: Use the HTTP API URL (starts with `https://`), NOT the PostgreSQL connection string

## Alternative: Using Dart Defines

You can also pass credentials via `--dart-define` flags when running:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_API_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

## Priority

The app checks for credentials in this order:
1. `--dart-define` flags (highest priority)
2. `.env` file
3. Falls back to in-memory repository if neither is provided

## Local Development

For local Supabase development:
```env
SUPABASE_API_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
```

Get your local anon key by running `supabase status` after starting local Supabase.

