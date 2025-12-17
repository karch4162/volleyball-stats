# VOLLEYBALL-STATS-PLAN

## 1. Objective & Success Metrics
- Deliver a Flutter app (Android/iOS/Web) that captures every stat shown on the coach’s StatSheet while optimizing the UX for fast mobile entry (transition, FBK, win/loss, serve rotations, subs/timeouts, individual attacks/blocks).
- Provide season-level history with set/match rollups, CSV/PDF exports, and offline-first reliability (zero data loss after reconnect).
- Measure success via: (a) <2s data entry per rally, (b) seamless offline/online sync, (c) automated stat summaries matching manual sheet totals.

## 2. Milestones (proposed sequence)
1. **Foundation (Week 1-2):** Repo setup, Supabase project, base Flutter shell, shared models, CI (lint/tests).
2. **Core Capture (Week 3-4):** Build rally input UI by stat block, local persistence, manual match creation, minimal analytics.
3. **Sync & Backend (Week 5-6):** Node service for derived stats, Supabase migrations/RLS, offline queue replay, initial exports.
4. **Insights & Polish (Week 7-8):** Dashboards (set→match→season), PDF/CSV parity, UX polish, error monitoring, beta release.

## 3. Workstreams & Key Tasks
### Flutter Client
- Scaffold feature modules: `match_setup`, `rally_capture`, `serve_tracker`, `player_stats`, `history`.
- Implement StatSheet-aligned widgets (grid taps for transition/FBK, serve rows 1-6 with rotations 1-10, player attack/block matrices).
- Add quick actions for substitutions/timeouts with undo.
- Integrate local store (Drift/Hive) for offline-first data capture.

### Sync & Offline Logic
- Define sync queue table storing optimistic rally actions with timestamps + device IDs.
- Implement background sync worker (Flutter `Workmanager`) that pushes to Supabase when online.
- Handle conflict resolution (server wins + merge rules for duplicate rallies).

### Supabase & Data Model
- Tables: `teams`, `players`, `matches`, `sets`, `rallies`, `actions`, `serve_rotations`, `substitutions`, `timeouts`, `season_totals`.
- Use Edge Functions/Triggers to roll up stats per set/match/season.
- Configure RLS for single-coach tenancy; prepare future multi-user roles.
- Version schema via SQL migration files stored in `supabase/migrations`.

### Node.js Service
- Build REST/GraphQL endpoints for match setup, stat ingestion, exports, and analytics queries.
- Implement aggregation workers (BullMQ/Cloud Tasks) to recompute season summaries and sanity-check totals.
- Provide PDF/CSV renderers that mimic StatSheet formatting.

### Analytics & Reporting
- Screens for live set totals, match recap, and season dashboards with charts (transition %, FBK %, serve efficiency, attack/block leaders).
- Export flows: share CSV/PDF via email or device storage; include filters (match, opponent, date range).

### DevOps & Quality
- CI pipeline: `flutter analyze`, `flutter test`, `npm test`, schema drift check, Supabase typegen.
- Release channels: internal testing via TestFlight/Play tracks & PWA hosting.
- Telemetry/error tracking (Sentry) plus feature flags for experimental views.

## 4. Open Questions & Dependencies
- Confirm exact PDF layout requirements (identical to StatSheet or optimized for mobile print?).
- Determine authentication UX (PIN vs email/password) for solo coaches.
- Decide on naming + jersey number conventions and roster import options.
- Select visualization library for charts (charts_flutter vs custom).

## 5. Immediate Next Steps
1. Lock repository scaffolding (Flutter, server, supabase folders, tooling config).
2. Draft initial Supabase ERD + migration scripts for matches/sets/rallies/actions.
3. Implement Flutter prototypes for rally grid and serve tracker using fake data to validate UX.
4. Stand up Node service with placeholder endpoints and integrate with Supabase local stack.
