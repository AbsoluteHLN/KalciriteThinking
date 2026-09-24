# Changelog

The rule text carries its own version in `SKILL.md` frontmatter (`metadata.version`).
`sync-skill.ps1` prints it before and after an update; the entries below say what
changed, so a version bump is never the only signal.

Versioning is on the **portable rule text**, not on the repository: a layout change
or a README rewrite does not move it, a change to the discipline does.

## 3.1

**Rule text: 16 KB, procedures on demand.** `SKILL.md` had grown into a reference
document that every session pays for. It now carries the discipline — resolution
order, the gate, the non-negotiables, the layout contract, the red lines — and
points at `reference/` for the procedures.

- **Split.** `reference/interview.md`, `reference/delegation.md`,
  `reference/dependency-cache.md`, `reference/ui-and-tools.md`. `SKILL.md` drops
  from ~26 KB to ~15 KB and keeps every rule, not a summary of a rule.
- **One generator for the boundary file.** `scripts/export-boundary.ps1` is now
  generic: it preserves the source document's own `##` headings, captures
  `| \`KEY\` | value |` rows, drops the third (commentary) cell, and emits the
  `kalcirite:answers` JSON block. The installer no longer renders a boundary at
  all — it copies the exported file verbatim — so the two can no longer drift.
  The installer drops from ~30 KB to ~12 KB; the interview leaves the script.
- **`boundary/MACHINE-CONFIG.template.md`** is the new hand-edited source document
  template, with `EXTRA_TOP_LEVEL` and the per-project pointer list. The old
  `boundary/PROJECT-BOUNDARY.template.md` was superseded by it and by the
  generated-file shape in `boundary/hosts/dsh.md`.
- **`boundary/hosts/CONTRACT.md`** states what any host adapter must implement
  (resolution, injection, interception, the recommended rule set, the modes, the
  status it must report) and what stays optional. `boundary/hosts/dsh.md` becomes
  a binding document against that contract rather than an example.
- **Slim layout.** `skills/` → `skill/`, `examples/` → `boundary/examples/` and
  `boundary/hosts/`. `boundary/QUESTIONS.md` becomes an index over
  `reference/interview.md` instead of a second copy of the question table.
- **`CHANGELOG.md`**, and `sync-skill.ps1` now prints the version delta and
  verifies afterwards that the copy landed and the profile block survived.
- The installer refuses a boundary whose values are still `<...>` placeholders: an
  unedited template exports cleanly, so the table shape alone proves nothing.

## 3.0

**Machine facts move into one document.** `MACHINE-CONFIG.md` (or a per-machine
variant) becomes the only hand-edited home for a machine's values;
`PROJECT-BOUNDARY.md` becomes a derivative that tools read.

- Boundary resolution order written down (project root → skill directory → agent
  config root → local profile → defaults), and the first-run interview turned into
  a hard gate: no edit, build, install, or delete before the answers are on disk.
- Sub-agent and model-selection facts become interview subjects in their own
  right, because whether a delegation may name its own route is a host fact.
- `boundary/DELEGATION.md` records the DSH specifics; `boundary/QUESTIONS.md`
  records what must be asked.

## 2.0

**Split into portable layer and machine layer.** The rule text loses every
machine-specific path; `PROJECT-BOUNDARY.md` gains the values and a
`kalcirite:local-profile` block inside `SKILL.md` as the last-resort fallback.
`scripts/install-skill.ps1` and `scripts/sync-skill.ps1` appear.

## 1.0

Single skill document: dependency cache rule, clean project layout, build-before-
verify ordering, archive-on-change hygiene. Not in this repository's history —
versioning starts at 2.0 with the portable split.
