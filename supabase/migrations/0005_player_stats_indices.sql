-- Migration: Add indices for player stats queries
-- Purpose: Optimize dashboard queries for set, match, and season-level player statistics
-- Created: 2025-12-10

-- Index for efficient player stat queries by set
-- Used by: fetchSetPlayerStats() when loading set dashboard
CREATE INDEX IF NOT EXISTS idx_actions_set_player 
ON actions (player_id, action_type, action_subtype, outcome)
WHERE player_id IS NOT NULL;

-- Index for efficient rally lookups within a set
-- Used by: All dashboard queries that need to aggregate by set
CREATE INDEX IF NOT EXISTS idx_rallies_set_lookup 
ON rallies (set_id, result, transition_type);

-- Index for efficient set lookups within a match
-- Used by: Match-level aggregations
CREATE INDEX IF NOT EXISTS idx_sets_match_lookup 
ON sets (match_id, set_number, result);

-- Index for season-level queries with date filtering
-- Used by: fetchSeasonStats() and fetchMatchSummaries()
CREATE INDEX IF NOT EXISTS idx_matches_season_date 
ON matches (team_id, season_label, match_date DESC);

-- Composite index for action aggregation queries
-- Used by: All player stat calculations (kills, errors, attempts, etc.)
CREATE INDEX IF NOT EXISTS idx_actions_rally_player_type
ON actions (rally_id, player_id, action_type);

-- Index for efficient player lookups by team
-- Used by: Roster queries when building PlayerPerformance objects
CREATE INDEX IF NOT EXISTS idx_players_team_active 
ON players (team_id, active, jersey_number);

-- Comments explaining index usage
COMMENT ON INDEX idx_actions_set_player IS 'Optimizes player stat queries by set for dashboard views';
COMMENT ON INDEX idx_rallies_set_lookup IS 'Speeds up rally aggregation within sets';
COMMENT ON INDEX idx_sets_match_lookup IS 'Optimizes set-level queries within matches';
COMMENT ON INDEX idx_matches_season_date IS 'Enables fast season-level filtering and sorting';
COMMENT ON INDEX idx_actions_rally_player_type IS 'Speeds up action type counting for stats';
COMMENT ON INDEX idx_players_team_active IS 'Optimizes roster queries by team';
