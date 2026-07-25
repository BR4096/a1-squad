---
description: Scan the past 24 hours of Claude Code session logs for Bash commands that caused permission friction, propose safe allow-list additions, apply them to .claude/settings.local.json, and explain how to reload
---

# Allow Now Command

Scans session logs for the past 24 hours, finds Bash commands that required user approval (not in current allow list), categorizes them by safety, applies safe additions to `.claude/settings.local.json`, and explains the reload path.

## Usage

```
/allow-now              # review + propose (dry-run)
/allow-now --apply      # review + apply AUTO-SAFE additions
/allow-now --apply --all  # apply AUTO-SAFE + REVIEW tier (manual vetting required)
```

---

## Step 1: Locate Session Logs

```bash
echo "=== Permissions Sync ==="
echo ""

APPLY=false
ALL_TIERS=false
for arg in "$@"; do
  [ "$arg" = "--apply" ] && APPLY=true
  [ "$arg" = "--all"   ] && ALL_TIERS=true
done

# Derive the Claude project log directory from CWD
# Claude Code slugifies the path: /Users/foo/bar -> -Users-foo-bar
CWD=$(pwd)
SLUG=$(echo "$CWD" | sed 's|/|-|g')
LOG_BASE="$HOME/.claude/projects"
LOG_DIR="$LOG_BASE/$SLUG"

echo "Project:  $CWD"
echo "Log dir:  $LOG_DIR"

if [ ! -d "$LOG_DIR" ]; then
  echo ""
  echo "⚠️  No Claude log directory found for this project."
  echo "   Expected: $LOG_DIR"
  echo "   Run at least one Claude Code session in this project first."
  exit 1
fi

# Find JSONL files modified in last 24 hours
RECENT_LOGS=$(find "$LOG_DIR" -name "*.jsonl" -mtime -1 2>/dev/null)
LOG_COUNT=$(echo "$RECENT_LOGS" | grep -c ".jsonl" 2>/dev/null || echo 0)

echo "JSONL files (24h): $LOG_COUNT"
[ "$LOG_COUNT" -eq 0 ] && echo "No recent logs found — nothing to analyze." && exit 0
echo ""
```

---

## Step 2: Extract Bash Commands from Logs

```bash
echo "=== Extracting Bash Commands ==="

# Python script: parse JSONL, extract all Bash tool_use commands
COMMANDS_RAW=$(python3 << 'PYEOF'
import json, os, sys, time

log_dir = os.environ.get("LOG_DIR", "")
cutoff  = time.time() - 86400  # 24 hours

if not log_dir or not os.path.isdir(log_dir):
    sys.exit(0)

seen_commands = []
seen_raw = set()

for fname in sorted(os.listdir(log_dir)):
    if not fname.endswith(".jsonl"):
        continue
    fpath = os.path.join(log_dir, fname)
    if os.path.getmtime(fpath) < cutoff:
        continue
    try:
        with open(fpath, "r", errors="ignore") as fh:
            for line in fh:
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                msg = d.get("message", {})
                if not isinstance(msg, dict):
                    continue
                for item in msg.get("content", []):
                    if not isinstance(item, dict):
                        continue
                    if item.get("type") == "tool_use" and item.get("name") == "Bash":
                        cmd = (item.get("input") or {}).get("command", "").strip()
                        if cmd and cmd not in seen_raw:
                            seen_raw.add(cmd)
                            seen_commands.append(cmd)
    except Exception:
        continue

for cmd in seen_commands:
    # Print first 200 chars, one per line
    print(cmd[:200])
PYEOF
)

LOG_DIR="$LOG_DIR"
export LOG_DIR

COMMANDS_RAW=$(python3 - << 'PYEOF'
import json, os, sys, time

log_dir = os.environ.get("LOG_DIR", "")
cutoff  = time.time() - 86400

if not log_dir or not os.path.isdir(log_dir):
    sys.exit(0)

seen_commands = []
seen_raw = set()

for fname in sorted(os.listdir(log_dir)):
    if not fname.endswith(".jsonl"):
        continue
    fpath = os.path.join(log_dir, fname)
    if os.path.getmtime(fpath) < cutoff:
        continue
    try:
        with open(fpath, "r", errors="ignore") as fh:
            for line in fh:
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                msg = d.get("message", {})
                if not isinstance(msg, dict):
                    continue
                for item in msg.get("content", []):
                    if not isinstance(item, dict):
                        continue
                    if item.get("type") == "tool_use" and item.get("name") == "Bash":
                        cmd = (item.get("input") or {}).get("command", "").strip()
                        if cmd and cmd not in seen_raw:
                            seen_raw.add(cmd)
                            seen_commands.append(cmd)
    except Exception:
        continue

for cmd in seen_commands:
    print(cmd[:200])
PYEOF
)

TOTAL_CMDS=$(echo "$COMMANDS_RAW" | grep -c . 2>/dev/null || echo 0)
echo "Unique Bash commands found: $TOTAL_CMDS"
echo ""
```

---

## Step 3: Check Against Allow Lists + Categorize

```bash
echo "=== Checking Against Allow Lists ==="

# Known-safe command prefixes (AUTO-SAFE tier) — safe for autonomous workflows
# Anything NOT here and NOT already allowed goes to REVIEW tier
SAFE_PREFIXES=(
  # Standard unix read/text ops
  "ls" "cat" "head" "tail" "grep" "find" "wc" "diff" "tree" "stat" "du" "df"
  "echo" "printf" "tee" "cut" "sort" "uniq" "tr" "awk" "sed" "jq" "xargs"
  "date" "pwd" "which" "whoami" "hostname" "uname" "uptime" "ps" "pgrep"
  # File ops
  "mkdir" "touch" "cp" "mv" "chmod" "ln"
  # Dev tools
  "git" "gh" "npm" "npx" "node" "bun" "pnpm" "yarn"
  "python3" "pip3" "tsc" "vite" "vitest" "eslint" "prettier"
  "supabase" "psql" "docker" "docker-compose"
  # macOS tools
  "open" "pbcopy" "pbpaste" "osascript" "sw_vers" "defaults" "plutil" "tmux"
  "brew" "stat" "ditto" "launchctl" "security" "lsof" "netstat"
  # Archives / network
  "tar" "zip" "unzip" "gzip" "curl" "wget" "ssh" "scp"
  # Build/test/CI
  "bc" "xxd" "nc" "nmap" "dig" "nslookup" "ping"
)

# Patterns that are NEVER safe to auto-add
NEVER_SAFE=(
  "rm -rf /" "rm -rf ~" "rm -rf ." "sudo" "su " "eval " "exec "
  "shutdown" "reboot" "mkfs" "dd " "chmod 777" "curl | bash" "wget | bash"
  "base64 -d" "python -c" "python3 -c" "perl -e" "ruby -e"
)

python3 << 'PYEOF'
import json, os, sys, re, subprocess

log_dir   = os.environ.get("LOG_DIR", "")
apply     = os.environ.get("APPLY", "false") == "true"
all_tiers = os.environ.get("ALL_TIERS", "false") == "true"
cwd       = os.environ.get("CWD", ".")

# ── Load allow lists ─────────────────────────────────────────────────────────
def load_allow(path):
    try:
        with open(path) as f:
            d = json.load(f)
        return d.get("permissions", {}).get("allow", [])
    except Exception:
        return []

global_settings  = os.path.expanduser("~/.claude/settings.json")
project_settings = os.path.join(cwd, ".claude", "settings.local.json")
global_allow     = load_allow(global_settings)
project_allow    = load_allow(project_settings)
all_allow        = global_allow + project_allow

def extract_prefix(pattern):
    """Extract prefix from 'Bash(cmd:*)' pattern."""
    m = re.match(r'^Bash\((.+?)(?::?\*\)?)?$', pattern)
    return m.group(1).strip() if m else None

allow_prefixes = []
for p in all_allow:
    prefix = extract_prefix(p)
    if prefix:
        allow_prefixes.append(prefix)

def already_allowed(cmd):
    cmd = cmd.strip()
    for prefix in allow_prefixes:
        if cmd.startswith(prefix):
            return True
    return False

def is_never_safe(cmd):
    never = [
        "rm -rf /", "rm -rf ~", "rm -rf .", "sudo ", "su ",
        "eval ", "exec ", "shutdown", "reboot", "mkfs", "dd ",
        "chmod 777", "curl | bash", "wget | bash", "base64 -d",
        "python -c", "python3 -c", "perl -e", "ruby -e",
        "printenv", "history -c"
    ]
    for n in never:
        if n in cmd:
            return True
    return False

safe_prefixes = [
    "ls", "cat", "head", "tail", "grep", "find", "wc", "diff", "tree",
    "stat", "du", "df", "echo", "printf", "tee", "cut", "sort", "uniq",
    "tr", "awk", "sed", "jq", "xargs", "date", "pwd", "which", "whoami",
    "hostname", "uname", "uptime", "ps", "pgrep", "mkdir", "touch", "cp",
    "mv", "chmod", "ln", "git", "gh", "npm", "npx", "node", "bun", "pnpm",
    "yarn", "python3", "pip3", "tsc", "vite", "vitest", "eslint", "prettier",
    "supabase", "psql", "docker", "docker-compose", "open", "pbcopy", "pbpaste",
    "osascript", "sw_vers", "defaults", "plutil", "tmux", "brew", "ditto",
    "launchctl", "lsof", "netstat", "tar", "zip", "unzip", "gzip", "curl",
    "wget", "ssh", "scp", "bc", "xxd", "dig", "nslookup", "pkill", "kill",
    "source", "bash", "sh", "env", "export", "nvm"
]

def is_auto_safe(cmd):
    first = cmd.split()[0].split("/")[-1] if cmd.strip() else ""
    return first in safe_prefixes

# ── Read commands from stdin (env-passed via subshell) ─────────────────────
cmds_raw = os.environ.get("COMMANDS_RAW", "")
commands  = [c.strip() for c in cmds_raw.splitlines() if c.strip()]

# ── Categorize ───────────────────────────────────────────────────────────────
auto_safe  = []  # safe to add, will apply if --apply
review     = []  # user should vet before adding
skipped    = []  # already covered

for cmd in commands:
    if already_allowed(cmd):
        skipped.append(cmd)
        continue
    if is_never_safe(cmd):
        # Never show in proposals — silently skip
        continue
    first_token = cmd.split()[0]
    # Build the allow pattern: "Bash(first_token:*)"
    pattern = f"Bash({first_token}:*)"
    if is_auto_safe(cmd):
        auto_safe.append((cmd, pattern))
    else:
        review.append((cmd, pattern))

# ── Deduplicate patterns (keep first example per pattern) ────────────────────
def dedup(items):
    seen = set()
    result = []
    for cmd, pattern in items:
        if pattern not in seen:
            seen.add(pattern)
            result.append((cmd, pattern))
    return result

auto_safe = dedup(auto_safe)
review    = dedup(review)

# ── Output ───────────────────────────────────────────────────────────────────
print(f"\nAlready covered by allow list:  {len(skipped)} command(s)")
print(f"Proposed AUTO-SAFE additions:   {len(auto_safe)}")
print(f"Proposed REVIEW additions:      {len(review)}\n")

if auto_safe:
    print("### AUTO-SAFE — will be added with --apply\n")
    print("| Pattern | Example Command |")
    print("|---------|-----------------|")
    for cmd, pattern in auto_safe:
        print(f"| `{pattern}` | `{cmd[:80]}` |")
    print()

if review:
    print("### REVIEW — add manually after vetting (use --apply --all to include)\n")
    print("| Pattern | Example Command | Why review? |")
    print("|---------|-----------------|-------------|")
    for cmd, pattern in review:
        reason = "network/destructive" if any(x in cmd for x in ["curl", "wget", "rm", "docker", "ssh"]) else "non-standard or env-prefixed"
        print(f"| `{pattern}` | `{cmd[:70]}` | {reason} |")
    print()

if not auto_safe and not review:
    print("✓  All commands from the past 24h are already covered by the allow list.")
    print("   No changes needed.\n")
    sys.exit(0)

# ── Apply ─────────────────────────────────────────────────────────────────────
to_add = list(auto_safe)
if all_tiers:
    to_add += list(review)

if not apply:
    print(f"> Dry-run — no changes made.")
    print(f"> Run `/allow-now --apply` to add {len(auto_safe)} AUTO-SAFE pattern(s).")
    if review:
        print(f"> Run `/allow-now --apply --all` to also include {len(review)} REVIEW pattern(s).")
    sys.exit(0)

if not to_add:
    print("Nothing to add.")
    sys.exit(0)

# Load current project settings (create if missing)
try:
    with open(project_settings) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

if "permissions" not in settings:
    settings["permissions"] = {}
if "allow" not in settings["permissions"]:
    settings["permissions"]["allow"] = []

existing = set(settings["permissions"]["allow"])
added = []
for _cmd, pattern in to_add:
    if pattern not in existing:
        settings["permissions"]["allow"].append(pattern)
        existing.add(pattern)
        added.append(pattern)

if added:
    os.makedirs(os.path.dirname(project_settings), exist_ok=True)
    with open(project_settings, "w") as f:
        json.dump(settings, f, indent=2)
    print(f"\n✅  Applied {len(added)} new pattern(s) to .claude/settings.local.json:\n")
    for p in added:
        print(f"   + {p}")
    print()
else:
    print("\n  All proposed patterns were already present.\n")
PYEOF
```

---

## Step 4: Reload Instructions

```bash
echo ""
echo "=== How to Reload Permissions ==="
echo ""
echo "Claude Code loads settings.local.json at session start."
echo "Changes made above take effect when you start a new session."
echo ""
echo "To reload:"
echo "  1. Exit this session:        Ctrl+C  or  /exit"
echo "  2. Start a new session:      claude"
echo "  3. Verify new permissions:   /security-audit"
echo ""

# Check if launchd monitor is running for this project
PLIST="$HOME/Library/LaunchAgents/com.claude-settings-monitor.plist"
if [ -f "$PLIST" ]; then
  MONITOR_DIR=$(grep -A1 "WorkingDirectory" "$PLIST" 2>/dev/null | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>/\1/')
  if [ "$MONITOR_DIR" = "$CWD" ]; then
    echo "⚡  launchd settings monitor is active for this project."
    echo "   Settings change was detected automatically."
    echo "   Still requires a new Claude session for the new allow patterns to apply."
  else
    echo "ℹ️   launchd monitor is configured for: $MONITOR_DIR"
    echo "   (not this project — update WorkingDirectory if needed)"
  fi
else
  echo "ℹ️   No launchd settings monitor configured."
  echo "   See CLAUDE.md: 'Session Startup Check: launchd WorkingDirectory'"
fi

echo ""
echo "════════════════════════════════════════"
echo "  /security-audit  — full settings hygiene review"
echo "  /health          — project state snapshot"
echo "════════════════════════════════════════"
```

---

## Safety Contract

**AUTO-SAFE patterns are added automatically** — standard Unix tools, git, npm, node, python3, docker, supabase, macOS-native tools. These match the global `settings.json` baseline and are safe for autonomous development workflows.

**REVIEW patterns require manual vetting** — network calls, env-prefixed commands, non-standard tools. Use `--apply --all` only after reviewing the table.

**Never added under any flag:**
- `rm -rf /`, `rm -rf ~`, `rm -rf .`
- `sudo`, `su`, `eval`, `exec`, `shutdown`, `reboot`
- `chmod 777`, `curl | bash`, `wget | bash`
- `base64 -d`, inline `python3 -c`, `perl -e`, `ruby -e`
- `printenv`, `history -c` (credential exposure)
