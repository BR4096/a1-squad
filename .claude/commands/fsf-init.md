---
description: Verify a project is correctly configured for the FSF stack (Vite + TypeScript + React + shadcn-ui + Tailwind + Supabase + React Query + Vitest + Resend). Reports PASS/WARN/FAIL per check with fix commands.
---

# /fsf-init

Audit and initialize a project for the FSF stack. Runs 6 checks and reports status with specific fix commands for each failure.

**FSF stack**: Vite + TypeScript + React + shadcn-ui + Tailwind + Supabase + React Query + Vitest + Resend

## Usage

```
/fsf-init    # Run all checks and report
```

## Checks

### Check 1 — Node project

```bash
if [ -f "package.json" ]; then
  echo "PASS: package.json found"
else
  echo "FAIL: Not in a Node project"
  echo "  Fix: Run this command from the project root (where package.json lives)"
  exit 1
fi
```

### Check 2 — FSF stack dependencies

Check that the four required FSF packages are present in package.json:

```bash
MISSING_DEPS=()

grep -q '"vite"' package.json || MISSING_DEPS+=("vite")
grep -q '"@supabase/supabase-js"' package.json || MISSING_DEPS+=("@supabase/supabase-js")
grep -q '"@tanstack/react-query"' package.json || MISSING_DEPS+=("@tanstack/react-query")
grep -q '"vitest"' package.json || MISSING_DEPS+=("vitest")

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
  echo "PASS: Core FSF dependencies found"
else
  echo "WARN: Missing FSF dependencies: ${MISSING_DEPS[*]}"
  echo "  Fix: npm install ${MISSING_DEPS[*]}"
fi

# Check recommended packages
grep -q '"resend"' package.json || echo "WARN: resend not found — Fix: npm install resend"
grep -q '"@shadcn/ui"\|shadcn' package.json || echo "WARN: shadcn-ui not found — Fix: npx shadcn@latest init"
```

### Check 3 — Required config files

```bash
MISSING_CONFIGS=()

[ -f "tsconfig.json" ]      || MISSING_CONFIGS+=("tsconfig.json")
[ -f "vite.config.ts" ]     || MISSING_CONFIGS+=("vite.config.ts")
[ -f "tailwind.config.ts" ] || { [ -f "tailwind.config.js" ] || MISSING_CONFIGS+=("tailwind.config.ts"); }

if [ ${#MISSING_CONFIGS[@]} -eq 0 ]; then
  echo "PASS: Config files present (tsconfig.json, vite.config.ts, tailwind.config)"
else
  echo "FAIL: Missing config files: ${MISSING_CONFIGS[*]}"
  echo "  Fix (tsconfig): npx tsc --init"
  echo "  Fix (vite):     npx create vite@latest . --template react-ts"
  echo "  Fix (tailwind): npx tailwindcss init -p"
fi
```

### Check 4 — Environment files

```bash
# .env should NOT be committed
if git ls-files --error-unmatch .env 2>/dev/null; then
  echo "FAIL: .env is tracked by git — contains secrets"
  echo "  Fix: git rm --cached .env && echo '.env' >> .gitignore"
elif [ -f ".env" ]; then
  echo "PASS: .env exists and is not tracked by git"
else
  echo "WARN: No .env file found — create one if you need local overrides"
fi

# .env.example SHOULD be committed (shows required vars without values)
if [ -f ".env.example" ]; then
  echo "PASS: .env.example present"
else
  echo "WARN: No .env.example — developers won't know which env vars are required"
  echo "  Fix: Create .env.example with placeholder values (no real secrets)"
fi
```

### Check 5 — Supabase client setup

```bash
# Look for createClient call in src/
if grep -rn "createClient" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | head -3; then
  echo "PASS: Supabase createClient found in src/"
else
  echo "WARN: No createClient call found in src/"
  echo "  Expected pattern: const supabase = createClient(url, key)"
  echo "  Typical location: src/lib/supabase.ts or src/integrations/supabase/client.ts"
  echo "  Fix: Create src/lib/supabase.ts with:"
  echo "    import { createClient } from '@supabase/supabase-js'"
  echo "    export const supabase = createClient("
  echo "      import.meta.env.VITE_SUPABASE_URL,"
  echo "      import.meta.env.VITE_SUPABASE_ANON_KEY"
  echo "    )"
fi
```

### Check 6 — Security audit

Run the key credential checks from `/security-audit`:

```bash
ISSUES=0

# No credentials in settings file
if grep -qiE "eyJ[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,}|re_[a-zA-Z0-9]{10,}" \
    .claude/settings.local.json 2>/dev/null; then
  echo "FAIL: Possible credential found in settings.local.json"
  echo "  Fix: See guides/credential-audit-guide.md"
  ISSUES=$((ISSUES+1))
fi

# .env protection in deny list
if [ -f ".claude/settings.local.json" ]; then
  if grep -q '"deny"' .claude/settings.local.json; then
    grep -q "cat .env" .claude/settings.local.json && \
      echo "PASS: .env read-protection in deny list" || \
      echo "WARN: Add 'Bash(cat .env:*)' and 'Bash(cat .env.local:*)' to deny list"
  else
    echo "WARN: No deny list in settings.local.json — add .env protections"
    ISSUES=$((ISSUES+1))
  fi
else
  echo "WARN: No .claude/settings.local.json — run /sync-settings --apply"
fi

[ $ISSUES -eq 0 ] && echo "PASS: Security checks clean"
```

## Report Format

After all checks, print a summary:

```
=== FSF Init Check Results ===

Check 1 — Node project:          [PASS|FAIL]
Check 2 — FSF dependencies:      [PASS|WARN|FAIL]
Check 3 — Config files:          [PASS|FAIL]
Check 4 — Environment files:     [PASS|WARN|FAIL]
Check 5 — Supabase client:       [PASS|WARN]
Check 6 — Security:              [PASS|WARN|FAIL]

Overall: [READY / NEEDS ATTENTION / BLOCKED]

Fix commands above for any WARN or FAIL items.
Next: /sync-settings --apply  (if settings.local.json is missing)
```

**READY** = all PASS or WARN only, no FAIL
**NEEDS ATTENTION** = at least one WARN (project will work but is incomplete)
**BLOCKED** = at least one FAIL (project cannot function correctly until fixed)
