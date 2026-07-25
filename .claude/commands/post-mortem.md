---
description: Instantiate the incident post-mortem template. Creates docs/post-mortems/YYYY-MM-DD-[slug].md with timestamp, populates fields, and appends a one-line entry to DEVLOG.md.
---

# /post-mortem

Create a post-mortem document for a production incident. Populates the standard template and links it to DEVLOG.md.

## Usage

```
/post-mortem [slug] [severity]

Examples:
  /post-mortem auth-loop SEV-2
  /post-mortem payment-timeout SEV-1
  /post-mortem slow-dashboard SEV-3
```

- **slug**: short kebab-case name (e.g., `auth-loop`, `payment-timeout`)
- **severity**: SEV-1 through SEV-4 (defaults to SEV-2 if not provided)

## Steps

### Step 1 — Collect metadata

```bash
TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M %Z')
SLUG="${1:-incident}"
SEVERITY="${2:-SEV-2}"
FILENAME="docs/post-mortems/${TODAY}-${SLUG}.md"

echo "Creating: $FILENAME"
echo "Severity: $SEVERITY"
echo "Timestamp: $NOW"
```

### Step 2 — Create the post-mortems directory

```bash
mkdir -p docs/post-mortems
```

### Step 3 — Check for related session notes

```bash
# Look for session notes from today or recent days
if [ -d "docs/session-notes/" ]; then
  RECENT_NOTES=$(ls docs/session-notes/ | grep "$(date '+%Y%m%d')" 2>/dev/null)
  if [ -n "$RECENT_NOTES" ]; then
    echo "Recent session notes found (consider linking):"
    echo "$RECENT_NOTES"
  fi
fi
```

### Step 4 — Write the post-mortem file

Create `$FILENAME` with this content (substituting actual values):

```markdown
# Post-Mortem: [SLUG in Title Case]

**Date:** [TODAY]
**Author:** [from CLAUDE.md or "Unknown"]
**Severity:** [SEVERITY]
**Status:** Draft

---

## Summary

_2–3 sentence description of what happened, what was impacted, and how long it lasted._

---

## Timeline

All times in [local timezone].

| Time | Event |
|------|-------|
| [HH:MM] | First sign of issue detected |
| [HH:MM] | Alert triggered / issue confirmed |
| [HH:MM] | Investigation began |
| [HH:MM] | Root cause identified |
| [HH:MM] | Fix deployed |
| [HH:MM] | Incident resolved / monitoring period began |
| [HH:MM] | Incident closed |

---

## Impact

- **Duration:** [X hours Y minutes]
- **Users affected:** [Number, percentage, or description]
- **Revenue impact:** [Amount or "N/A"]
- **Data impact:** [Description or "No data loss"]

---

## Root Cause

_Detailed explanation of the technical root cause. Focus on systems and processes, not individuals._

---

## Contributing Factors

1. [Factor 1 — what made this possible]
2. [Factor 2 — what allowed it to go undetected]
3. [Factor 3 — what slowed the response]

---

## What Went Well

- [Detection / alerting worked correctly]
- [Team communication was clear]
- [Rollback was fast]

---

## What Went Poorly

- [Alert was too slow / noisy]
- [Root cause took too long to identify]
- [Missing runbook for this scenario]

---

## Action Items

| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| [Preventive measure 1] | — | High | [DATE] |
| [Preventive measure 2] | — | Medium | [DATE] |
| [Add runbook for this scenario] | — | Medium | [DATE] |

---

## Lessons Learned

_Key takeaways that should change how we build, monitor, or respond._

---

## References

- Session notes: [link if exists]
- Related DEVLOG entry: [date and title]
- Incident response protocol: protocols/tier-3/incident-response.md
```

### Step 5 — Append entry to DEVLOG.md

```bash
if [ -f "DEVLOG.md" ]; then
  DEVLOG_ENTRY="
---

## ${TODAY}: Post-Mortem — ${SLUG} (${SEVERITY})

**Status**: Draft | **File**: ${FILENAME}

Post-mortem created for ${SLUG} incident. See file for full timeline and action items.
"
  echo "$DEVLOG_ENTRY" >> DEVLOG.md
  echo "Appended entry to DEVLOG.md"
else
  echo "WARN: No DEVLOG.md found. Create one to track decisions."
fi
```

### Step 6 — Report

```
Post-mortem created: docs/post-mortems/[YYYY-MM-DD-slug].md
DEVLOG.md:          Entry appended
Severity:           [SEV-N]

Fill in the template sections:
  [ ] Summary (2-3 sentences)
  [ ] Timeline (fill in actual times)
  [ ] Root cause (technical explanation)
  [ ] Action items (at least 2 with owners)

When complete, change Status from Draft to Final.
```

## Notes

- **Blameless**: Post-mortems focus on systems and processes. "The deployment process allowed X" not "Alice deployed bad code."
- **Actionable**: Every post-mortem should produce at least 2 action items that change the system.
- **Draft until signed off**: Set Status to Final only after action items have been reviewed.
- **Severity reference**: SEV-1 = service down / security breach. SEV-2 = major feature broken. SEV-3 = minor feature broken. SEV-4 = cosmetic.
