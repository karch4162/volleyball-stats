# Manual User Verification Guide

## For Local Development

### Option 1: Via Supabase Studio (Easiest)
1. Open Supabase Studio: http://localhost:54323
2. Go to **Authentication** → **Users**
3. Find your user
4. Click on the user
5. Click **"Confirm Email"** button or manually set `email_confirmed_at` to current timestamp

### Option 2: Via SQL
Run this SQL in Supabase Studio SQL Editor:

```sql
-- Verify a specific user by email
UPDATE auth.users
SET email_confirmed_at = now()
WHERE email = 'your-email@example.com';

-- Or verify all unverified users
UPDATE auth.users
SET email_confirmed_at = now()
WHERE email_confirmed_at IS NULL;
```

### Option 3: Check Inbucket (Email Testing Server)
If emails are being sent, you can view them at:
- http://localhost:54324

This is the local email testing server where all emails are captured.

### Option 4: Disable Email Confirmation (Already Done)
The config already has `enable_confirmations = false` in `supabase/config.toml`.
If it's still requiring confirmation, restart Supabase:
```bash
supabase stop
supabase start
```

