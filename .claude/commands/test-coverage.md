---
description: Measure and report test coverage. Detects vitest or jest, runs with coverage, checks against thresholds (statements ≥80%, branches ≥70%, functions ≥80%), and lists highest-leverage files to test next.
---

# /test-coverage

Run the test suite with coverage and report results against threshold targets.

## Usage

```
/test-coverage    # Run coverage and report
```

## Steps

### Step 1 — Detect test runner

```bash
if [ ! -f "package.json" ]; then
  echo "ERROR: No package.json found. Run from project root."
  exit 1
fi

if grep -q '"vitest"' package.json; then
  RUNNER="vitest"
elif [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || grep -q '"jest"' package.json; then
  RUNNER="jest"
else
  echo "WARN: No recognized test runner found in package.json"
  echo "  Expected: vitest (FSF stack) or jest"
  echo "  Check: package.json devDependencies"
  RUNNER="unknown"
fi

echo "Test runner: $RUNNER"
```

### Step 2 — Run tests with coverage

```bash
case "$RUNNER" in
  vitest)
    echo "Running: npx vitest run --coverage"
    npx vitest run --coverage 2>&1 | tail -60
    ;;
  jest)
    echo "Running: npx jest --coverage --coverageReporters=text"
    npx jest --coverage --coverageReporters=text 2>&1 | tail -60
    ;;
  *)
    echo "Cannot run coverage — test runner not detected."
    echo "Manually run: npx vitest run --coverage"
    exit 1
    ;;
esac
```

Note: If coverage is not configured, vitest will prompt to install `@vitest/coverage-v8`. Run:
```bash
npm install -D @vitest/coverage-v8
```
Then add to `vite.config.ts`:
```typescript
test: {
  coverage: {
    provider: 'v8',
    reporter: ['text', 'lcov'],
    thresholds: { statements: 80, branches: 70, functions: 80, lines: 80 }
  }
}
```

### Step 3 — Parse results and check thresholds

After the coverage run, extract the summary percentages and compare against thresholds:

| Metric | Threshold | Status |
|---|---|---|
| Statements | ≥ 80% | [extract from output] |
| Branches | ≥ 70% | [extract from output] |
| Functions | ≥ 80% | [extract from output] |
| Lines | ≥ 80% | [extract from output] |

Report each metric as PASS, WARN (within 5% of threshold), or FAIL (below threshold).

```
Statements:  [X]%  [PASS|WARN|FAIL]  (threshold: 80%)
Branches:    [X]%  [PASS|WARN|FAIL]  (threshold: 70%)
Functions:   [X]%  [PASS|WARN|FAIL]  (threshold: 80%)
Lines:       [X]%  [PASS|WARN|FAIL]  (threshold: 80%)
```

### Step 4 — Count passing and failing tests

From the vitest output, extract:

```
Tests:    [X] passed, [Y] failed, [Z] skipped
Duration: [N]s
```

If any tests are failing, list the failed test names. Coverage numbers are unreliable when tests fail — fix failures first.

### Step 5 — List untested files

Files with < 50% statement coverage are the highest-leverage testing targets. List the bottom files:

```bash
# vitest outputs a per-file table — scan for low-coverage files
# Look for lines where the Stmts% column is below 50
# (parse from the coverage output above)
```

Report format:

```
Files below 50% statement coverage:
  src/lib/hooks/usePayment.ts       12.5%
  src/components/admin/UserTable.tsx  33.1%
  src/services/email.ts              0.0%
```

### Step 6 — Recommend next 3 test targets

Rank untested files by:
1. Files with 0% coverage and high import count (used in many places)
2. Files that contain business logic (services/, lib/hooks/) over UI components
3. Files recently modified (from `git log --oneline -20 -- src/`)

```
Top 3 highest-leverage test targets:
1. src/services/email.ts (0% coverage, used in 4 components, core business logic)
2. src/lib/hooks/usePayment.ts (12.5% coverage, 2 edge cases uncovered)
3. src/lib/utils/formatDate.ts (0% coverage, pure function — easy win)

Template: /Users/billringle/webdev/github/Best-Practices/templates/react-supabase/test.test.ts
```

## Summary Report

```
=== Test Coverage Report ===
Runner:     vitest
Tests:      [X] passed / [Y] failed / [Z] skipped

Coverage:
  Statements:  [X]%  [PASS|WARN|FAIL]
  Branches:    [X]%  [PASS|WARN|FAIL]
  Functions:   [X]%  [PASS|WARN|FAIL]
  Lines:       [X]%  [PASS|WARN|FAIL]

Files below 50%: [N] files
Top test targets: (see above)

[COVERAGE MEETS THRESHOLDS | ACTION REQUIRED: X metrics below threshold]
```
