---
description: Copy the right stack baseline settings to .claude/settings.local.json. Detects stack, shows diff if file exists, dry-runs by default. Use --apply to write.
---

# /sync-settings

Copy the correct stack-baseline `settings.local.json` from Best-Practices into this project's `.claude/` directory.

## Usage

```
/sync-settings           # Dry run: show what would be written
/sync-settings --apply   # Write the file (creates or overwrites after diff review)
```

## Steps

### Step 1 — Detect the stack

Check these files to determine which baseline to use:

```bash
# Check for stack markers
if [ -f "convex.json" ] || [ -d "convex/" ]; then
  STACK="react-convex"
elif [ -f "package.json" ] && grep -q '"vitest"' package.json && grep -q '"supabase"' package.json 2>/dev/null; then
  STACK="fsf"
elif [ -f "package.json" ] && grep -q '"supabase"' package.json 2>/dev/null; then
  STACK="react-supabase"
elif [ -f "composer.json" ] || [ -f "wp-config.php" ] || [ -d "wp-content/" ]; then
  STACK="wordpress"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  STACK="python"
else
  STACK="generic"
fi
echo "Detected stack: $STACK"
```

The FSF stack (`fsf`) matches projects with both `vitest` and `supabase` in package.json — i.e., Vite + TypeScript + React + shadcn-ui + Tailwind + Supabase + React Query + Vitest + Resend.

### Step 2 — Locate the source file

```bash
BP_PATH="/Users/billringle/webdev/github/Best-Practices"

case "$STACK" in
  fsf)          SRC="$BP_PATH/settings/examples/fsf-stack-settings.local.json" ;;
  react-supabase) SRC="$BP_PATH/settings/examples/react-supabase-settings.local.json" ;;
  react-convex) SRC="$BP_PATH/settings/examples/react-convex-settings.local.json" ;;
  wordpress)    SRC="$BP_PATH/settings/examples/wordpress-settings.local.json" ;;
  python)       SRC="$BP_PATH/settings/examples/python-settings.local.json" ;;
  *)            SRC="$BP_PATH/settings/examples/react-supabase-settings.local.json" ;;
esac

echo "Source: $SRC"
ls -la "$SRC" 2>/dev/null || echo "ERROR: source file not found"
```

### Step 3 — Check if a settings file already exists

```bash
DEST=".claude/settings.local.json"

if [ -f "$DEST" ]; then
  echo "Existing settings.local.json found. Diff:"
  diff "$DEST" "$SRC" || true
  echo ""
  echo "NOTE: Run /sync-settings --apply to overwrite, or stop here to keep current."
else
  echo "No existing settings.local.json. Will create fresh."
fi
```

If a settings file already exists, show the diff and stop unless `--apply` was passed. Do not silently overwrite a file that may contain project-specific customizations.

### Step 4 — Apply (only if --apply flag was given)

```bash
# Only proceed if the user explicitly passed --apply
mkdir -p .claude
cp "$SRC" "$DEST"
echo "Written: $DEST"
wc -l "$DEST"
```

### Step 5 — Post-sync report

After writing (or after reviewing the dry run), report:

```
Stack detected:     [stack name]
Source baseline:    settings/examples/[file]
Destination:        .claude/settings.local.json
Lines:              [N]
Status:             [Dry run (no changes) | Written | Skipped (file exists, use --apply)]

Next steps:
- Review the file and add any project-specific entries
- Add stack-specific WebFetch domains if needed
- Add project scripts: "Bash(./scripts/your-script.sh:*)"
- See guides/settings-slim-guide.md for consolidation rules (target: ≤100 lines)
```

## Notes

- **Dry run by default** — this command never writes without `--apply`
- **No project-specific entries in baselines** — after sync, add your own project scripts manually
- **Existing customizations are preserved** on dry run; with `--apply`, the baseline replaces the file — add custom entries afterward
- **Target**: ≤ 100 lines. If the resulting file grows past 100 lines, review `guides/settings-slim-guide.md`
