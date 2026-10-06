# docs/superpowers

Specs and plans for this repo live here, in one numbered layout. The number is the stage.

| Dir | Holds | Moves in when |
|---|---|---|
| `01-specs/` | Design docs being built, or about to be | brainstorming writes a spec |
| `02-plans/` | Active implementation plans, which `/build` reads | `/plan` or writing-plans creates one |
| `03-done/` | Shipped work, spec beside its plan | `/build` succeeds, or shipped evidence is cited and BR approves |
| `04-archive/` | Inactive, legacy, superseded or abandoned work, under `specs/` and `plans/` | BR retires it |

## How new content is added

New files go only in `01-specs/` or `02-plans/`, named `YYYY-MM-DD-topic.md`. A spec or plan belongs in the repo whose code it changes, not in the brain2 vault. Moves between stages are `git mv`, with references to the old path fixed in the same change. `03-done/` is a claim that the work shipped, so it needs evidence from `git log`; `04-archive/` needs only approval.

## Staleness rules

- Anything in `01-specs/` or `02-plans/` with no commit for 60 days is an archive candidate. Run `/tidyup --superpowers --report-only` to classify it.
- Anything in `04-archive/` with no commit for 180 days is a deletion candidate. Deletion needs BR's approval; git history keeps the file recoverable.
- `03-done/` is a record and is never a staleness candidate.

## State on 2026-10-06 (scaffold pass)

Added by a cross-repo `/tidyup` pass on 2026-10-06. Directories created: `01-specs/`, `02-plans/`, `03-done/`, `04-archive/`. No existing spec or plan was moved.

Tracked specs and plans: 0.

### Archive candidates (active or legacy tier, over 60 days): 0

None.

### Deletion candidates (archive tier, over 180 days): 0

None.
