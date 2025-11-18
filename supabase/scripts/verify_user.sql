-- Manually verify a user's email in local development
-- Replace 'user@example.com' with the actual email address

UPDATE auth.users
SET email_confirmed_at = now()
WHERE email = 'user@example.com';

-- Or verify all unverified users:
-- UPDATE auth.users
-- SET email_confirmed_at = now()
-- WHERE email_confirmed_at IS NULL;

