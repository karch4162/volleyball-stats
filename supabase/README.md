# Supabase Setup

1. Install the Supabase CLI (`brew install supabase/tap/supabase` or download release).
2. Copy `.env.example` to `.env` and update credentials.
3. Run `supabase start` from the repo root to bring up local Postgres/Auth/Storage.
4. Apply migrations with `supabase db reset`.
5. Generate types for Flutter/Node clients using `supabase gen types typescript --local > server/src/types/supabase.ts` (add Flutter flavor once schema exists).
