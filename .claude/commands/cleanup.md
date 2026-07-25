---
description: Intelligent monthly repo maintenance — removes build caches, archives old files to YYYY-MM-archive/, logs all actions; generates a Proposed Cleanup Plan before any changes
---

# Cleanup Command

Monthly (or on-demand) intelligent repo maintenance. Always generates a **Proposed Cleanup Plan** before executing changes. Loads `.cleanup-config.json` if present.

Protocol: `protocols/prompt-cleanup-repo.md`

## Usage

```
/cleanup                         # preview-only: show plan, no changes (default)
/cleanup preview-only            # explicit alias for default
/cleanup --confirm               # execute: apply Tier 1 removal + archive old files
/cleanup --confirm --all         # execute all tiers (+ merged branches, old logs, backups)
/cleanup skip-archive            # preview tidy/removal only, no archive proposal
/cleanup skip-archive --confirm  # execute removal without YYYY-MM-archive/ step
```

---

## Step 0: Config + Initialization

```bash
# ── Parse flags ──────────────────────────────────────────────────────────────
CONFIRM=false
ALL_TIERS=false
SKIP_ARCHIVE=false
PREVIEW_ONLY=true

for arg in "$@"; do
  case "$arg" in
    --confirm)       CONFIRM=true;  PREVIEW_ONLY=false ;;
    --all)           ALL_TIERS=true ;;
    skip-archive)    SKIP_ARCHIVE=true ;;
    preview-only)    PREVIEW_ONLY=true; CONFIRM=false ;;
  esac
done

# ── Timestamps ───────────────────────────────────────────────────────────────
NOW=$(date +"%Y-%m-%d %H:%M:%S")
TODAY=$(date +%Y-%m-%d)
ARCHIVE_MONTH=$(date +%Y-%m)
ARCHIVE_DIR="${ARCHIVE_MONTH}-archive"
LOG_DIR="cleanup-logs"
LOG_FILE="$LOG_DIR/$TODAY.log"

mkdir -p "$LOG_DIR"
log() { echo "[$NOW] $*" >> "$LOG_FILE"; echo "$*"; }

log "MODE: $( $CONFIRM && echo 'execute' || echo 'preview-only' )"

# ── Load config ──────────────────────────────────────────────────────────────
AGE_THRESHOLD=30
PRESERVE_DIRS="docs/ README.md CHANGELOG.md BACKLOG.md DEVLOG.md CLAUDE.md"

if [ -f ".cleanup-config.json" ]; then
  AGE_THRESHOLD=$(python3 -c "import json,sys; d=json.load(open('.cleanup-config.json')); print(d.get('fileAgeThresholdDays',30))" 2>/dev/null || echo 30)
  log "CONFIG: .cleanup-config.json loaded (age threshold: ${AGE_THRESHOLD}d)"
else
  log "CONFIG: none found — using defaults (${AGE_THRESHOLD}d threshold)"
fi

CUTOFF=$(date -v-${AGE_THRESHOLD}d +%Y%m%d 2>/dev/null || date --date="${AGE_THRESHOLD} days ago" +%Y%m%d 2>/dev/null || echo "00000000")

# ── Stack detection ───────────────────────────────────────────────────────────
if   [ -f "wp-config.php" ] || [ -d "wp-content" ]; then    STACK="wordpress"
elif [ -d "convex" ] && [ -f "convex.json" ]; then           STACK="react-convex"
elif [ -d "supabase" ] && [ -f "package.json" ]; then        STACK="react-supabase"
elif [ -f "package.json" ]; then                              STACK="node"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then STACK="python"
else                                                          STACK="generic"
fi

log "STACK: $STACK"
echo ""
```

---

## Step 1: Safety Gate

```bash
echo "=== Safety Gate ==="

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "  Branch:       $BRANCH"
echo "  Uncommitted:  $UNCOMMITTED file(s)"

if [ "$UNCOMMITTED" -gt 0 ]; then
  echo "  ⚠️  Uncommitted changes exist — cleanup proceeds but verify WIP is not affected"
  git status --short | head -5 | sed 's/^/     /'
  log "WARN: $UNCOMMITTED uncommitted file(s)"
else
  echo "  ✓  Working tree clean"
fi
echo ""
```

---

## Step 2: Build the Proposed Cleanup Plan

```bash
echo "## Proposed Cleanup Plan — $TODAY"
echo ""
echo "| Action | Target | Size | Reason |"
echo "|--------|--------|------|--------|"

PLAN_ITEMS=()   # array of "ACTION|target|size|reason"
PLAN_BYTES=0

add_to_plan() {
  local action="$1" target="$2" reason="$3"
  [ ! -e "$target" ] && return
  local raw_size
  raw_size=$(du -sk "$target" 2>/dev/null | cut -f1 || echo 0)
  local bytes=$((raw_size * 1024))
  local human
  if [ "$bytes" -gt 1048576 ]; then human="$(echo "$bytes / 1048576" | bc) MB"
  elif [ "$bytes" -gt 1024 ]; then human="${raw_size} KB"
  else human="${bytes} B"; fi
  PLAN_BYTES=$((PLAN_BYTES + bytes))
  echo "| $action | \`$target\` | $human | $reason |"
  log "PLAN-$action: $target ($human) — $reason"
  PLAN_ITEMS+=("$action|$target|$human|$reason")
}

add_to_plan_path() {
  local action="$1" target="$2" reason="$3"
  while IFS= read -r -d '' f; do
    add_to_plan "$action" "$f" "$reason"
  done < <(find . -path "$target" -print0 2>/dev/null)
}

# ── Tier 1: Safe artifacts ────────────────────────────────────────────────────

# macOS metadata
while IFS= read -r -d '' f; do add_to_plan "REMOVE" "$f" "macOS metadata"; done \
  < <(find . \( -name ".DS_Store" -o -name "._*" \) -not -path "./.git/*" -print0 2>/dev/null)

# Editor swap files
while IFS= read -r -d '' f; do add_to_plan "REMOVE" "$f" "Editor swap file"; done \
  < <(find . \( -name "*.swp" -o -name "*.swo" -o -name "*~" \) -not -path "./.git/*" -print0 2>/dev/null)

# Build caches
for cache in "node_modules/.cache" ".vite" ".parcel-cache" ".eslintcache" ".vitest" ".next/cache" "dist/.vite"; do
  [ -e "$cache" ] && add_to_plan "REMOVE" "$cache" "Build cache — safe to rebuild"
done

# Stack-specific
case "$STACK" in
  python)
    while IFS= read -r -d '' f; do add_to_plan "REMOVE" "$f" "Python bytecode"; done \
      < <(find . \( -name "*.pyc" -o -name "*.pyo" \) -not -path "./.git/*" -print0 2>/dev/null)
    for d in "__pycache__" ".pytest_cache"; do
      while IFS= read -r -d '' f; do add_to_plan "REMOVE" "$f" "Python cache"; done \
        < <(find . -name "$d" -type d -not -path "./.git/*" -print0 2>/dev/null)
    done ;;
  react-convex)
    [ -d ".convex" ] && add_to_plan "REMOVE" ".convex" "Convex local cache" ;;
  react-supabase)
    [ -d ".supabase" ] && add_to_plan "REMOVE" ".supabase" "Supabase local dev data" ;;
  wordpress)
    [ -d "wp-content/cache" ]   && add_to_plan "REMOVE" "wp-content/cache" "WordPress cache"
    [ -d "wp-content/upgrade" ] && add_to_plan "REMOVE" "wp-content/upgrade" "WordPress upgrade artifacts" ;;
  node)
    for log in npm-debug.log* yarn-error.log; do
      while IFS= read -r -d '' f; do add_to_plan "REMOVE" "$f" "Node error log"; done \
        < <(find . -name "$log" -maxdepth 2 -print0 2>/dev/null)
    done ;;
esac

# Orphaned /tmp project files
for tmp in /tmp/commit-msg.txt /tmp/fsf-beta-deploy-* /tmp/docx-env /tmp/save-image.py; do
  ls $tmp 2>/dev/null | while read -r f; do add_to_plan "REMOVE" "$f" "Stale temp file"; done
done

# ── Session notes archival ────────────────────────────────────────────────────
if [ -d "docs/session-notes" ] && [ "$SKIP_ARCHIVE" = false ]; then
  for note in docs/session-notes/*.md; do
    [ ! -f "$note" ] && continue
    NOTE_DATE=$(basename "$note" | grep -oE '^[0-9]{8}' || echo "99999999")
    if [ "$NOTE_DATE" -lt "$CUTOFF" ] 2>/dev/null; then
      add_to_plan "ARCHIVE→notes" "$note" "Session note >$AGE_THRESHOLD days"
    fi
  done
fi

# ── General file archival (files older than threshold, not in preserve list) ──
if [ "$SKIP_ARCHIVE" = false ]; then
  while IFS= read -r -d '' f; do
    # Skip if in a preserve path or already handled above
    SKIP=false
    for p in $PRESERVE_DIRS docs/session-notes .git node_modules dist src convex supabase/migrations "$ARCHIVE_DIR" cleanup-logs; do
      [[ "$f" == ./$p* ]] && SKIP=true && break
    done
    $SKIP && continue
    # Check age (macOS: stat -f %Sm with format)
    FILE_DATE=$(stat -f "%Sm" -t "%Y%m%d" "$f" 2>/dev/null || echo "99999999")
    if [ "$FILE_DATE" -lt "$CUTOFF" ] 2>/dev/null; then
      add_to_plan "ARCHIVE" "$f" "File >$AGE_THRESHOLD days, not in preserve list"
    fi
  done < <(find . -type f \
    \( -name "*.png" -o -name "*.jpg" -o -name "*.dmg" -o -name "*.pkg" \
       -o -name "*.log" -o -name "*.bak" -o -name "*.backup" \) \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    -print0 2>/dev/null)
fi

# ── Tier 2: Review items (--all only) ─────────────────────────────────────────
if [ "$ALL_TIERS" = true ]; then
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  git branch --merged 2>/dev/null | grep -vE "^\*|main|master|$CURRENT_BRANCH" | tr -d ' ' | \
  while read -r b; do
    echo "| REVIEW | branch: \`$b\` | — | Merged, safe to delete |"
    log "PLAN-REVIEW: branch $b (merged)"
  done

  while IFS= read -r -d '' f; do
    SIZE=$(stat -f%z "$f" 2>/dev/null || echo 0)
    [ "$SIZE" -gt 1048576 ] && add_to_plan "REVIEW" "$f" "Log file >1MB"
  done < <(find . -name "*.log" -maxdepth 3 -not -path "./.git/*" -print0 2>/dev/null)

  while IFS= read -r -d '' f; do
    add_to_plan "REVIEW" "$f" "Backup file"
  done < <(find . \( -name "*.bak" -o -name "*.backup" -o -name "*.orig" \) \
    -not -path "./.git/*" -not -path "./archive/*" -not -path "./${ARCHIVE_DIR}/*" -print0 2>/dev/null)
fi

# ── Plan summary ──────────────────────────────────────────────────────────────
echo ""
HUMAN_PLAN_TOTAL=""
if [ "$PLAN_BYTES" -gt 1048576 ]; then HUMAN_PLAN_TOTAL="$(echo "$PLAN_BYTES / 1048576" | bc) MB"
elif [ "$PLAN_BYTES" -gt 1024 ]; then HUMAN_PLAN_TOTAL="$(echo "$PLAN_BYTES / 1024" | bc) KB"
else HUMAN_PLAN_TOTAL="${PLAN_BYTES} B"; fi

echo "**Detected Stack:** $STACK"
echo "**Would free:** $HUMAN_PLAN_TOTAL across ${#PLAN_ITEMS[@]} item(s)"
echo ""

if [ "$CONFIRM" = false ]; then
  echo "> Preview only — no changes made."
  echo "> Run \`/cleanup --confirm\` to apply, or \`/cleanup --confirm --all\` for full cleanup."
  if [ ! -f ".cleanup-config.json" ]; then
    echo ""
    echo "> **Tip:** No \`.cleanup-config.json\` found. Create one to customize age thresholds,"
    echo "> preserve lists, and ignore patterns. See \`protocols/prompt-cleanup-repo.md\`."
  fi
  log "PLAN-COMPLETE: ${#PLAN_ITEMS[@]} items, $HUMAN_PLAN_TOTAL (preview only — exiting)"
  echo ""; exit 0
fi
echo ""
```

---

## Step 3: Execution

```bash
echo "=== Executing Cleanup ==="

REMOVED_COUNT=0
REMOVED_BYTES=0
ARCHIVED_COUNT=0

for item in "${PLAN_ITEMS[@]}"; do
  IFS='|' read -r ACTION TARGET SIZE REASON <<< "$item"
  case "$ACTION" in
    REMOVE)
      if [ -e "$TARGET" ]; then
        BYTES=$(du -sk "$TARGET" 2>/dev/null | cut -f1 || echo 0)
        rm -rf "$TARGET"
        echo "  REMOVED   $TARGET ($SIZE)"
        log "REMOVED: $TARGET ($SIZE)"
        ((REMOVED_COUNT++))
        REMOVED_BYTES=$((REMOVED_BYTES + BYTES * 1024))
      fi ;;

    ARCHIVE→notes)
      mkdir -p "docs/session-notes/archive"
      mv "$TARGET" "docs/session-notes/archive/" 2>/dev/null
      echo "  ARCHIVED  $(basename $TARGET) → docs/session-notes/archive/"
      log "ARCHIVED-NOTE: $TARGET"
      ((ARCHIVED_COUNT++)) ;;

    ARCHIVE)
      # Mirror directory structure in YYYY-MM-archive/
      REL="${TARGET#./}"
      DEST_DIR="$ARCHIVE_DIR/$(dirname "$REL")"
      mkdir -p "$DEST_DIR"
      mv "$TARGET" "$DEST_DIR/" 2>/dev/null
      echo "  ARCHIVED  $TARGET → $ARCHIVE_DIR/$(dirname $REL)/"
      log "ARCHIVED: $TARGET → $ARCHIVE_DIR/$(dirname $REL)/"
      ((ARCHIVED_COUNT++)) ;;

    REVIEW)
      echo "  SKIPPED   $TARGET (REVIEW item — use --all --confirm to include)"
      log "SKIPPED-REVIEW: $TARGET" ;;
  esac
done

echo ""
```

---

## Step 4: Settings Audit (non-destructive)

```bash
echo "=== Settings ==="

SETTINGS=".claude/settings.local.json"
if [ -f "$SETTINGS" ]; then
  LINES=$(wc -l < "$SETTINGS" | tr -d ' ')
  ONEOFFS=$(grep -c "PGPASSWORD\|SERVICE_KEY\|ANON_KEY\|eyJhbGci\|_NEW_LINE_\|\.tsx \|\.ts \|docs/dev/" "$SETTINGS" 2>/dev/null || echo 0)
  if [ "$ONEOFFS" -gt 0 ]; then
    echo "  ⚠️  settings.local.json: $LINES lines, ~$ONEOFFS possible one-off approval(s)"
    echo "     Run /security-audit for full settings hygiene"
    log "WARN: settings.local.json $LINES lines, $ONEOFFS one-off candidates"
  else
    echo "  ✓  settings.local.json: $LINES lines, no obvious one-off approvals"
  fi
else
  echo "  INFO  No .claude/settings.local.json"
fi
echo ""
```

---

## Step 5: Cleanup Summary Report

```bash
HUMAN_REMOVED=""
if [ "$REMOVED_BYTES" -gt 1048576 ]; then HUMAN_REMOVED="$(echo "$REMOVED_BYTES / 1048576" | bc) MB"
elif [ "$REMOVED_BYTES" -gt 1024 ]; then HUMAN_REMOVED="$(echo "$REMOVED_BYTES / 1024" | bc) KB"
else HUMAN_REMOVED="${REMOVED_BYTES} B"; fi

echo "## Cleanup Summary Report — $TODAY"
echo ""
echo "| Category | Count | Space |"
echo "|----------|-------|-------|"
echo "| Removed (caches / artifacts) | $REMOVED_COUNT | $HUMAN_REMOVED |"
echo "| Archived (session notes) | — | — |"
echo "| Archived (other) | $ARCHIVED_COUNT | — |"
echo ""
[ "$ARCHIVED_COUNT" -gt 0 ] && echo "Archive path: \`$ARCHIVE_DIR/\`"
echo "Log: \`$LOG_FILE\`"
echo ""

# Offer to generate .cleanup-config.json
if [ ! -f ".cleanup-config.json" ]; then
  echo "**Tip:** Generate \`.cleanup-config.json\` to customize future runs:"
  echo '```json'
  echo '{
  "fileAgeThresholdDays": 30,
  "preserve": ["docs/", "README.md", "CHANGELOG.md", "BACKLOG.md", "DEVLOG.md"],
  "ignorePatterns": ["node_modules/", "**/.git/**", ".env*"]
}'
  echo '```'
fi

echo ""
echo "════════════════════════════════════════"
echo "  /health          — project state snapshot"
echo "  /security-audit  — settings and credential hygiene"
echo "════════════════════════════════════════"

log "SUMMARY: removed=$REMOVED_COUNT ($HUMAN_REMOVED), archived=$ARCHIVED_COUNT"
log "DONE"
```

---

## Never Touched

`.env`, `.env.*` • `node_modules/` (root) • `dist/` `build/` `public/` • `supabase/migrations/` • `convex/` source • `src/` `app/` `pages/` • `.git/` • staged files • anything in `preserve` list
