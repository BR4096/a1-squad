---
description: Run the development checklist interactively — pre-work checks, writing code gates, bug-fix verification, and pre-commit must-pass items
---

# Dev Checklist

Interactive development checklist. Run phases in order. Stop at any FAIL before proceeding.

## Usage

```
/dev-checklist          # full checklist (all phases)
/dev-checklist pre      # pre-work phase only
/dev-checklist commit   # pre-commit gates only
```

---

## Phase 1: Pre-Work (run before writing any code)

Run these 5 checks. All must pass before starting.

```bash
echo "=== Phase 1: Pre-Work Checks ==="

# 1. Git state — no unexpected uncommitted files
echo "[1/5] Git status:"
git status --short

# 2. CLAUDE.md breaking changes
echo ""
echo "[2/5] CLAUDE.md breaking changes:"
grep -A 15 -i "breaking\|BREAKING" CLAUDE.md 2>/dev/null | head -18 || echo "  (no breaking changes section found)"

# 3. DEVLOG.md open items
echo ""
echo "[3/5] DEVLOG.md open items:"
grep -n "^- \[ \]" DEVLOG.md 2>/dev/null | head -8 || echo "  (no open items)"

# 4. Dev server running?
echo ""
echo "[4/5] Dev server check:"
PORT=${DEV_PORT:-5173}
lsof -ti:$PORT > /dev/null 2>&1 && echo "  Port $PORT: server running" || echo "  Port $PORT: not running — start with: npm run dev"

# 5. Tests currently passing?
echo ""
echo "[5/5] Quick test check:"
npm test -- --run 2>&1 | tail -5
```

**Gate:** If tests were already failing before you started, fix them first or explicitly note the failure count to track against later.

---

## Phase 2: During Development

Check these as you write code. No commands to run — these are judgment checks.

- [ ] No `any` types introduced (React/TS) — use `unknown` or specific types
- [ ] No `!` non-null assertions — use `?.` or `?? fallback`
- [ ] No `console.*` calls — use `devLogger` or remove before commit
- [ ] Error handling uses `catch (error: unknown)` with `instanceof` narrowing
- [ ] Imports use `@/` absolute paths (not `../../../`)
- [ ] Every new DB query goes through the service layer — no raw Supabase calls in components
- [ ] No secrets hardcoded — all API keys reference `import.meta.env.VITE_*` or `process.env.*`

---

## Phase 3: After Fixing a Bug

```bash
echo "=== Phase 3: Post-Fix Verification ==="

# Find the test file for the changed module
echo "[1/3] Relevant test files:"
git diff --name-only | sed 's|src/||; s|\.tsx\?$||; s|\.ts$||' | while read mod; do
  find . -name "*.test.*" -path "*$mod*" 2>/dev/null | head -2
done

# Run the specific test for the fix
echo ""
echo "[2/3] Run the specific test (replace with your test path):"
echo "  npm test -- --run --reporter=verbose src/path/to/relevant.test.ts"

# Confirm no regressions
echo ""
echo "[3/3] Full test suite (confirm no regressions):"
npm test -- --run 2>&1 | tail -8
```

---

## Phase 4: Pre-Commit Gates (must all pass)

These are hard stops. Do not commit until all pass.

```bash
echo "=== Phase 4: Pre-Commit Gates ==="
FAIL=0

# Gate 1: Lint
echo "[1/4] Lint:"
npm run lint 2>&1 | tail -5
npm run lint > /dev/null 2>&1 || { echo "  FAIL: fix lint errors before committing"; FAIL=1; }

# Gate 2: Type check
echo ""
echo "[2/4] TypeScript:"
npm run typecheck 2>&1 | tail -5
npm run typecheck > /dev/null 2>&1 || { echo "  FAIL: fix type errors before committing"; FAIL=1; }

# Gate 3: Tests
echo ""
echo "[3/4] Tests:"
npm test -- --run 2>&1 | tail -8

# Gate 4: No secrets staged
echo ""
echo "[4/4] Secrets scan on staged files:"
SECRETS=$(git diff --staged | grep -iE "api_key\s*[:=]\s*['\"][A-Za-z0-9]{20,}|sk_live|pk_live|SUPABASE_SERVICE_ROLE" | grep -v "example\|placeholder\|test" | head -5)
if [ -n "$SECRETS" ]; then
  echo "  FAIL: potential secrets in staged diff:"
  echo "$SECRETS"
  FAIL=1
else
  echo "  OK: no obvious secrets in staged diff"
fi

echo ""
if [ $FAIL -eq 0 ]; then
  echo "All gates passed. Commit with:"
  echo "  cat > /tmp/commit-msg.txt << 'CMEOF'"
  echo "  feat: describe your change"
  echo "  CMEOF"
  echo "  git commit -F /tmp/commit-msg.txt"
else
  echo "BLOCKED: fix failures above before committing."
fi
```

---

## Related

- Full checklist reference: `checklists/development.md`
- Pre-deployment gates: `/deploy-check`
- Security scan: `/security-audit`
- Commit pattern: `/batch-commit`
