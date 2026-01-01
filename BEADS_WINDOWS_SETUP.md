# Beads Setup Guide for Windows

## The Problem

On Windows, the beads installation doesn't automatically create the `.beads` directory correctly, which can cause beads to fail or create a local `.beads` directory instead of using the proper git worktree structure.

## The Solution

**Important:** `.beads` should be a **regular directory**, not a symlink! This is the correct setup that matches how beads works on all platforms.

## Step-by-Step Fix

### 1. Initial State Check

First, check if you have an incorrectly configured beads setup:

```bash
cd /path/to/your/project

# Check if .beads exists and what type it is
ls -la | grep "\.beads"

# If it shows as a symlink (lrwxrwxrwx), you need to fix it
# If it's a directory (drwxr-xr-x), you're probably okay
```

### 2. Kill Any Running Beads Daemons

```bash
# Windows (Git Bash)
taskkill //F //IM bd.exe

# Or use Task Manager to kill bd.exe processes
```

### 3. Backup Existing .beads (If It Has Data)

```bash
# Only if .beads exists and has data you want to keep
mv .beads .beads.backup-$(date +%Y%m%d-%H%M%S)
```

### 4. Create Proper .beads Directory

```bash
# Remove any incorrect symlink or empty directory
rm -rf .beads

# Create .beads as a regular directory
mkdir .beads

# Copy any existing JSONL files from backup
cp .beads.backup-*/*.jsonl .beads/ 2>/dev/null || true
```

### 5. Check Worktree Structure

Verify your git worktree has the proper setup:

```bash
ls -la .git/beads-worktrees/beads-sync/.beads/

# Should show:
# - config.yaml
# - metadata.json
# - .gitignore
# - issues.jsonl (possibly empty)
# - interactions.jsonl (possibly empty)
```

If the `.beads` directory doesn't exist in the worktree, copy the files:

```bash
cp .git/beads-worktrees/beads-sync/.beads/config.yaml .beads/
cp .git/beads-worktrees/beads-sync/.beads/metadata.json .beads/
cp .git/beads-worktrees/beads-sync/.beads/.gitignore .beads/
```

### 6. Initialize Beads

```bash
# Initialize with your project prefix
bd init --prefix your-project-name

# Example:
# bd init --prefix volleyball-stats
```

### 7. Import Existing Issues (If Any)

If you have a backup JSONL file with issues:

```bash
bd sync --import-only
```

### 8. Verify Setup

```bash
# Check beads health
bd doctor

# List issues (should work without errors)
bd list

# Verify database exists and has content
ls -lh .beads/beads.db
```

### 9. Commit Changes

```bash
git add .beads/
git commit -m "fix(beads): initialize beads database properly"
git push
```

## Common Issues & Solutions

### Issue: "no beads database found"

**Solution:** Run `bd init --prefix your-project-name`

### Issue: "The system cannot find the path specified" when running bd init

**Solution:** This usually means there's a symlink issue. Delete `.beads` and recreate it as a regular directory (Step 4 above).

### Issue: "Access is denied" during auto-flush

**Solution:** This is a temporary file permission issue on Windows. The import/sync still works, but you may see warnings. This doesn't affect functionality.

### Issue: Daemon won't start

**Solution:** 
```bash
# Kill any stuck processes
taskkill //F //IM bd.exe

# Try starting fresh
bd daemon start
```

## Quick Reference: Correct Structure

```
your-project/
├── .beads/                          # Regular directory, NOT a symlink
│   ├── .gitignore
│   ├── config.yaml
│   ├── metadata.json
│   ├── beads.db                     # SQLite database
│   └── issues.jsonl                 # JSONL export
└── .git/
    └── beads-worktrees/
        └── beads-sync/              # Git worktree for beads branch
            └── .beads/              # Tracked on beads-sync branch
                ├── config.yaml
                ├── metadata.json
                └── issues.jsonl
```

## Fresh Project Setup (No Existing Beads)

If you're setting up beads for the first time on a project:

```bash
# 1. Ensure no .beads directory exists
rm -rf .beads

# 2. Create directory
mkdir .beads

# 3. Initialize beads
bd init --prefix your-project-name

# 4. Verify
bd doctor
bd list
```

## Migrating from Another Machine

If you cloned a project that already has beads set up:

```bash
# 1. Clone the repo
git clone <repo-url>
cd project

# 2. Create .beads directory
mkdir .beads

# 3. Check out the beads-sync branch files
# (bd init should do this automatically, but if not:)
git show beads-sync:.beads/config.yaml > .beads/config.yaml
git show beads-sync:.beads/metadata.json > .beads/metadata.json

# 4. Initialize database
bd init --prefix your-project-name

# 5. Import issues
bd sync --import-only
```

## Windows-Specific Notes

1. **No Admin Rights Needed:** Using regular directories means no admin rights are required for symlink creation.

2. **Git Bash vs PowerShell:** These instructions work best in Git Bash. If using PowerShell, adjust path separators (`/` to `\`).

3. **Junction vs Symlink:** Don't use Windows junctions (`mklink /J`) for `.beads`. Just use a regular directory.

4. **Line Endings:** Git may warn about CRLF/LF conversions in `.beads` files. This is normal and doesn't affect functionality.

## Verification Checklist

- [ ] `.beads` is a regular directory (not a symlink)
- [ ] `.beads/beads.db` exists and has size > 0
- [ ] `bd list` runs without errors
- [ ] `bd doctor` shows mostly green checkmarks
- [ ] Issues can be created: `bd create "Test issue"`
- [ ] Changes are committed to git
- [ ] `bd sync` works without errors

## Getting Help

If you're still having issues:

1. Run `bd doctor --verbose` for detailed diagnostics
2. Check `.beads/config.yaml` for correct settings
3. Verify git worktree: `git worktree list`
4. Check daemon status: `bd daemon status`

## References

- Beads Documentation: [GitHub - steveyegge/beads](https://github.com/steveyegge/beads)
- This guide based on fixing volleyball-stats and sports-management projects (January 2026)
