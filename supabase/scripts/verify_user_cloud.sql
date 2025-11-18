-- Manually verify a user's email in Supabase Cloud
-- Run this in Supabase Dashboard → SQL Editor

-- Verify a specific user by email
UPDATE auth.users
SET email_confirmed_at = now()
WHERE email = 'user@example.com';

-- Or verify all unverified users (use with caution!)
-- UPDATE auth.users
-- SET email_confirmed_at = now()
-- WHERE email_confirmed_at IS NULL;

