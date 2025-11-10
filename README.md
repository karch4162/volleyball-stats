# Volleyball Stats App

Mobile-first stat tracking platform for volleyball coaches. This repository contains:

- `app/`: Flutter client (Android, iOS, Web) for rally capture and insights.
- `server/`: Node.js/TypeScript service for APIs, aggregations, and exports.
- `supabase/`: Database schema, migrations, RLS, and functions.
- `agent-docs/`: Plans, status reports, and contributor guides.
- `docs/`: UX mocks, references (e.g., StatSheet.png), and decision records.
- `ops/`: DevOps scripts, CI/CD definitions, environment templates.

Refer to `AGENTS.md`, `agent-docs/VOLLEYBALL-STATS-PLAN.md`, and `agent-docs/DEVELOPMENT-PLAN.md` before contributing.

## Development Environment Notes

- Phase 0 work began inside WSL for this Codex CLI session, but the existing Flutter SDK installed on Windows (`C:\Flutter`) uses CRLF scripts that fail under WSL.
- Until a Linux-native Flutter SDK is installed, run Flutter commands from Windows (e.g., via Cursor IDE or PowerShell) so `flutter pub get`, `flutter analyze`, and `flutter test` succeed.
- Node.js and Supabase tooling remain cross-platform; ensure `.env` files stay out of version control.
- Flutter client expects Supabase credentials at runtime. Provide them via Dart defines:  
  `flutter run -d chrome --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon_key>`  
  When defines are omitted, the app falls back to an in-memory repository (useful for widget tests).
