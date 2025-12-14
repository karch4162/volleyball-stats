-- Add match status and completion tracking
-- Part of Phase 1.3: Match Completion Flow

-- Add status column to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'in_progress' 
CHECK (status IN ('in_progress', 'completed', 'cancelled'));

-- Add completed_at timestamp
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- Add final score columns for quick access
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS final_score_team integer,
ADD COLUMN IF NOT EXISTS final_score_opponent integer;

-- Create index for filtering completed matches
CREATE INDEX IF NOT EXISTS matches_status_idx ON matches(status);
CREATE INDEX IF NOT EXISTS matches_completed_at_idx ON matches(completed_at);

-- Add comment for documentation
COMMENT ON COLUMN matches.status IS 'Match status: in_progress, completed, or cancelled';
COMMENT ON COLUMN matches.completed_at IS 'Timestamp when match was marked as completed';
COMMENT ON COLUMN matches.final_score_team IS 'Final sets won by team (quick access)';
COMMENT ON COLUMN matches.final_score_opponent IS 'Final sets won by opponent (quick access)';
