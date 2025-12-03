-- Ensure RLS is enabled anywhere match_drafts and roster_templates exist.
-- Supabase database lint flagged these tables because policies were present
-- without RLS being enabled (likely due to a partial migration). Running this
-- migration guarantees the tables stay protected even if they were created
-- earlier outside of migration 0003.

alter table if exists match_drafts
  enable row level security;

alter table if exists roster_templates
  enable row level security;

