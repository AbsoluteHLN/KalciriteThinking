# Changelog

The rule text carries its own version in `SKILL.md` frontmatter (`metadata.version`).
`sync-skill.ps1` prints it before and after an update; the entries below say what
changed, so a version bump is never the only signal.

Versioning is on the **portable rule text**, not on the repository: a layout change
or a README rewrite does not move it, a change to the discipline does.

## 3.7

**The store is the only place dependencies are installed and used from.** 3.6
kept the store as the single converged location; 3.7 states the constraint in
its exclusive form: installing and using dependencies happen *only* in the
shared store — every install is pinned so its payload lands there, every
consumer resolves through a link into it, and use or install anywhere else
(project-local payload, per-software location, the package manager's own
default location) is a violation even when it works.

- **`SKILL.md`** §3 is retitled "One dependency store — installed and used only
  there; one big folder per ecosystem, closed top level"; the opening paragraph
  now states the exclusivity up front; rule 1 is rewritten to "only the store —
  query it first, and everything lands there" (the authorised-fetch exception of
  rule 6 still lands in the store); the §0.4 non-negotiable and the §9 red line
  are rephrased from "no payloads outside" to "use and install only in the
  store"; the frontmatter description carries the same wording.
- **`reference/dependency-cache.md`**: title and opening state the exclusivity;
  consequence 2 extends "consumers link" with "and installs land in the store,
  nowhere else"; hard rule 1 extends to "query the store first, and install only
  into it".
- **`reference/host-adapters.md`**: the injection bullet and the recommended
  rule set's dependency-payload trigger now carry the use/install-only-in-the
  store statement.

## 3.6

**The store is one big folder, closed at the top.** 3.3 forbade per-project,
per-build, and per-variant payloads; 3.6 closes the same rule one level up:
all of a machine's dependencies live in one big folder per ecosystem, and a
sibling entry that is "the dependencies of software X" at the top of the store
is forbidden too.

- **`SKILL.md` §3** is retitled "One dependency store — one big folder, never
  per-build, never per-software" and gains rule 4: *the store's top level is
  closed and documented* — a top-level entry is an ecosystem store/cache or
  declared infrastructure, the store keeps a guide at its root listing every
  entry and what may write there, and a new top-level payload named after a
  software or a project is a failure signal.
- **`reference/dependency-cache.md`**: consequence 4 (closed top level — a
  per-software sibling forks the store), hard rule 3 (the store is guided; a
  new top-level entry is a decision recorded in the guide), convergence check
  4 (compare the store's top level against the guide), and "why a second
  payload tree is a defect" extended to the per-software case.
- **`reference/host-adapters.md`**: the recommended rule set's
  dependency-payload trigger now also covers a per-software store at the top
  level of the store; the injected text must say so.
- `SKILL.md` §0.4, §9, and the frontmatter description aligned.

## 3.5

**Two skills: rules + local boundary.** The machine's values get their own
skill, `kalcirite-project-boundary` (published in a private, per-machine
repository). The generic skill is installed clean — no machine data ships in
the public edition, and none is required in it.

- **`SKILL.md` §0.1** gains resolution step 2: *the boundary skill* —
  `PROJECT-BOUNDARY.md` inside the sibling skill `kalcirite-project-boundary`
  in the same skill root. Where both are present it wins over the legacy
  in-skill-directory location, which becomes step 3 and is kept for
  single-skill installs.
- **§0.2 gate** rephrased: proceed only when a boundary file resolves with no
  placeholders **or** the local profile is filled; an empty profile is no
  longer by itself a stop condition — that is the normal clean-install state.
- Frontmatter `config` / `localProfile` lines updated to match; the
  empty-profile block text explains the two-skill install.
- **`install-skill.ps1`**: a clean install (no boundary anywhere) is a
  first-class mode — rule text only, profile left empty — instead of
  throwing.
- **`reference/interview.md`**: the flow's install step and the shape
  contract (placement, install-equals-copy) describe the two-skill and
  single-skill shapes.
- **`reference/host-adapters.md` §1**: the resolution list is updated to
  match the rule text; a file-path-resolving adapter checks the boundary
  skill's directory before the rules skill's own directory, per skill root.

## 3.4

**The skill is now host-neutral on its face.** The goal: Codex, DeepSeek
Harness, Claude Code — any host that loads this skill can execute it precisely,
without DSH, PowerShell, or a Windows shell in the loop.

- **`reference/interview.md`** gains *The boundary file's shape* — the
  writer-side contract: the keyed-row format, the `kalcirite:answers` JSON
  block (authoritative when present, rows alone are a supported case, empty
  values dropped), `GENERATED` provenance, placement per §0.1, and
  install-equals-copy. The PowerShell scripts are declared to be one
  implementation of the contract on Windows, not the contract itself.
- **`SKILL.md` §0.1** names the agent config root per host (DSH `$DSH_HOME`,
  Claude Code `~/.claude`, Codex `~/.codex`); **§0.2** steps 2–3 now say the
  agent itself can export and install on any host.
- **`reference/dependency-cache.md`**: the convergence checks get a bash
  equivalent, so the executable checks work without PowerShell.
- **`reference/host-adapters.md`** resolution examples gain `~/.codex/`.
- The DSH-specific material that was already host-shaped (the worked example
  in `reference/delegation.md`) stays, but is only ever labelled as an
  example; nothing in the rule text requires a host that is not this one.
- READMEs gain a per-host install table (`.claude/skills/`, `.codex/skills/`,
  `<DSH_HOME>\skills\`) and state that a non-Windows host's agent can
  produce a valid boundary file by hand from the spec.

## 3.3

**Dependencies converge on one store.** §3 used to forbid per-project
payloads; the new boundary adds the other half of the same rule: the machine
keeps **one** store per ecosystem — one pnpm store, one cargo registry, one
npm cache, one shared `node_modules`-like tree — and every project, build
target, and variant resolves from it and links in. *One folder with its own
dependencies per build* is now named as the defect it is: N payload trees are
N versions of the truth, and they drift.

- **`SKILL.md` §3** is retitled "One dependency store — converged, shared,
  never per-build" and gains two rules: exactly one store per ecosystem (no
  second payload tree anywhere, **including under `<BUILD_ROOT>`**), and
  consumers link, they do not copy — shared bytes, not a nominal "it is cached
  elsewhere too".
- **`reference/dependency-cache.md`** gets a convergence section (the
  per-ecosystem store table, the per-build-folder prohibition, "build output
  is generated code, never dependencies") and a **Proving convergence** block:
  the project holds no real (non-linked) payload directory, any payload that
  is present is a junction into the store, and the store is the one
  machine-wide root.
- **§9** red line and **§6** rule 2 extend to the per-build / per-variant
  case; §0.3, §0.4 and the frontmatter wording follow.
- The host adapter's injected text and its dependency refusal message now
  carry the convergence wording. No new guard rule was needed: the write
  guard already denies a payload directory at any depth, including under the
  build root.

## 3.2

**The portable layer is self-contained.** An installed skill copy had five
repository-relative paths in it — `scripts/export-boundary.ps1`,
`scripts/install-skill.ps1`, `boundary/MACHINE-CONFIG.template.md`,
`boundary/DELEGATION.md`, `boundary/hosts/CONTRACT.md` — which dangle the moment
the skill is installed on its own. The rule text was violating its own §0.1:
never hard-code a path, resolve it from the machine's document instead.

- **`boundary/hosts/CONTRACT.md` → `reference/host-adapters.md`.** The adapter
  contract is host-agnostic and belongs with the portable text, so it now ships
  with the skill and is installed alongside the other reference pages. Host
  *bindings* stay in the repository under `boundary/hosts/`.
- **`boundary/DELEGATION.md` removed.** Its generic half (how to record routing
  on any host) is now in `reference/delegation.md`; its DSH half (validation, when
  the policy is read, what is exposed, the `subagent_fork` exception, id-vs-display
  -name, behaviour when off) is a table in `boundary/hosts/dsh.md`. What remained
  was a second copy of the question table.
- **Repository paths are named, not linked.** `SKILL.md`, `reference/interview.md`
  and `reference/ui-and-tools.md` now refer to the exporter, the installer and the
  config template by role, with the concrete location recorded in §0 of the
  machine-config document. A rule from `SKILL.md`: every path a portable file
  names must ship inside the skill directory.
- **`reference/` index.** `SKILL.md` frontmatter and the reading footer list all
  five reference pages.

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
