---
name: kalcirite-project-rules
description: "Portable engineering discipline for multi-project agent work: cost-tiered model routing and self-contained session handoff, a single shared dependency cache (no per-project installs), a canonical UI source with token-only styling, a shared plugin/tool catalogue before any new build, a fixed clean project layout with one build-output root, build-before-verify ordering, archive-on-change hygiene, and evidence-gated claims. Load before working in any repository that follows these boundaries."
whenToUse: "Working in or delegating work inside a repository that shares a machine-level dependency cache, a canonical UI source, or a shared tool catalogue; installing/building dependencies; resetting or extending a UI; deciding where a reusable plugin or tool belongs; reorganizing project structure and build output; or delegating to cheaper models. Also when adopting this skill on a new machine — that requires the first-run interview (§0.2) before any work."
metadata:
  version: "3.1"
  kind: "portable-rules"
  scope: "per-machine"
  config: "PROJECT-BOUNDARY.md — project root, then this skill's directory, then the agent config root (§0.1)"
  localProfile: "block between the kalcirite:local-profile markers below; empty means run the first-run interview (§0.2) first"
  reference: "reference/ — interview, delegation, dependency-cache, ui-and-tools; read on demand"
---

# Kalcirite project rules (portable)

An agent-agnostic working discipline for **multi-project machines**: several repositories on one disk sharing one dependency cache, one UI foundation, one tool catalogue, and one predictable layout. Nothing here is tied to a vendor, an IDE, or one agent product.

Every machine-specific value — cache path, UI source, tool home, provider, ports — lives in **the boundary file**, `PROJECT-BOUNDARY.md`, resolved per §0.1. Without it the rules still hold; only the concrete paths must be resolved first, which is what §0.2 is for.

<!-- kalcirite:local-profile:begin -->
## Local profile

> **Empty — UNRESOLVED.** No machine values are recorded in this file yet.
> Run the §0.2 first-run interview (`reference/interview.md`), write the answers
> into this machine's config document, then export and install the boundary file
> before doing any work.
<!-- kalcirite:local-profile:end -->

---

## 0. How to use this document

### 0.1 Resolution order for any path or value

The **boundary file** is `PROJECT-BOUNDARY.md`. Use the first hit, in this order:

1. **Project root** — `<project>/PROJECT-BOUNDARY.md` (or a `PROJECT-BOUNDARY` section in the project's `AGENTS.md` / `.kalcirite/boundary.md`). Highest priority: a project may override any machine value.
2. **This skill's own directory** — `PROJECT-BOUNDARY.md` next to this `SKILL.md`. The installer writes it here, so it travels with the skill.
3. **Agent config root** — `$DSH_HOME/PROJECT-BOUNDARY.md`, `~/.claude/PROJECT-BOUNDARY.md`, `~/.config/<agent>/PROJECT-BOUNDARY.md`, …
4. **The local profile block above**, if it has been filled in.
5. **Domain defaults** — the fallbacks written here as `<PLACEHOLDER>`.

A boundary file is the machine-config document's keyed rows plus a `kalcirite:answers` JSON block; the JSON is authoritative. Never invent a path, port, version, or tool name: **verify before asserting**, existence first.

### 0.2 First-run interview — required before any work

**Gate.** If no boundary file resolves, or it still contains `<PLACEHOLDER>` / `<…>` tokens, or the local profile above says UNRESOLVED — **stop and interview the user first**. Do not edit, build, install, reorganise, or delete anything until the answers are written back: this document knows the rules, not the machine.

Ask once, in one batch, in the user's language, each question carrying a **probed default** labelled *detected* or *guess*. The question table, probing methods, blank-handling rules, and the export/install flow are in **`reference/interview.md`**. Then:

1. record the answers in this machine's config document (hand-edited, human-facing);
2. `scripts/export-boundary.ps1` turns that document into the boundary file;
3. `scripts/install-skill.ps1` copies the rule text and boundary file into the target skill root.

Never edit the generated boundary file — the next export overwrites it. **Blank is a legitimate answer**: it makes the rules stop and report for that domain, and never authorises guessing.

### 0.3 Placeholders

`<DEP_CACHE>` — the one dependency cache root (blank ⇒ no dependency work at all).
`<UI_SOURCE>` — canonical UI engine/source of truth (blank ⇒ one source per project, still tokenised).
`<TOOL_HOME>` — shared plugin/tool catalogue (blank ⇒ search the project's own `tools/` first).
`<BUILD_ROOT>` / `<TMP>` / `<EVIDENCE>` — build output, scratch, evidence roots; defaults `cxbuild/`, `temp/`, `verify-evidence/`.

### 0.4 Non-negotiables

- **Build first, verify once.** Do not loop build→verify→build.
- **No per-project dependency installs.** One cache, linked in.
- **Reuse before rebuild.** UI and tools are found, not re-invented.
- **No claim without evidence.** Unobserved capability is unverified capability.
- **No work before the machine is known.** Interview first (§0.2), then act.

---

## 1. Execution order (the short version)

1. **Locate** — project root, boundary file, target module. Verify every path you are about to depend on.
2. **Recon reuse surface** — does `<DEP_CACHE>` satisfy the closure? Does `<TOOL_HOME>` have the capability? Does `<UI_SOURCE>` have the component?
3. **Build first** — make the change complete, then build, and confirm the artifact landed in `<BUILD_ROOT>`.
4. **Verify once, centrally** — run the project's own check scripts; write command, timestamp, result, and raw failure text into `<EVIDENCE>`.
5. **Delegate the cheap parts** — bulk reading, per-file sweeps, doc drafting (`reference/delegation.md`); the main session keeps design, judgement, and final adjudication.
6. **Archive on change** — outdated files go to `archive/` under their own subtree, or are safely deleted (§7).
7. **Report** — changed files with paths, evidence paths, unverified items, residual risk, next step.

---

## 2. Cost-tiered routing and session handoff

Route by **required reasoning depth**, not by task size. Design, architecture, trade-offs, security, and final adjudication stay on the strong/parent route; bulk reading, mechanical refactors, log triage, extraction, and doc drafting go to the cheapest capable route.

- **Discover the route, never guess it**, and never leave the provider named in the boundary file. Prefer the configured **model id** over a display name; fuzzy-match the nearest cheap sibling when the exact id is absent, and report the substitution.
- **Verify the capability before using it.** If the delegation tool does not expose `provider` / `model`, it does not exist for this session: delegate on the inherited route or work inline, and report model selection as unavailable. Never fabricate the fields, and do not edit settings mid-session hoping it applies.
- **Every delegation is self-contained** — context, one bounded deliverable, read/write boundary, absolute target path, acceptance test, forbidden traps. A child does not see this conversation.

Full procedure, the host-facts table, and a reusable prompt skeleton: **`reference/delegation.md`**; generic-vs-DSH walkthrough: `boundary/DELEGATION.md`.

---

## 3. One dependency cache, linked — never vendored

`<DEP_CACHE>` is the single dependency root on this machine; if it is blank, no dependency work happens at all.

1. **Query the cache first** for every install, resolve, or download. Cache hit → use it; no online reinstall.
2. **No dependency payload inside a project** — `node_modules`, `.venv`, `vendor/`, toolchain caches live only in `<DEP_CACHE>`; the project holds a junction / symlink / configured pointer at most.
3. **Never clean, delete, reorganise, or overwrite the cache**, and never delete a *linked* dependency directory — a recursive delete punches through the junction into the shared cache.
4. **Confirm closure before building.** Unsatisfiable closure → **stop and report the missing list**; "reinstall dependencies" is not a repair step. Fetching is an exception needing explicit human authorisation, and the payload still lands in the cache.

Pointer mechanisms per ecosystem, executable checks, and the hit/miss/fetch protocol: **`reference/dependency-cache.md`**.

---

## 4. One canonical UI source, token-only styling

On a UI reset, upgrade, or adjustment, the default is to **integrate `<UI_SOURCE>`** and follow its own documentation — read the selected version's `README` + `contract` **before** writing markup or style, and say which version you chose and why. Generating fresh UI files inside a project is reserved for independent publication that genuinely needs a self-contained subset.

- **Styling split**: project CSS carries **layout and pass-through only**; colour, elevation, control appearance, state, and motion come from the source's tokens / variants / theme attributes.
- **Failure signals**: a new colour literal in project CSS; a control restyled while the system already exposes that variant; a generated UI tree without a publish justification; a version chosen without reading its contract.

Procedure and the degraded (`UI_SOURCE` blank) mode: **`reference/ui-and-tools.md`**.

---

## 5. Shared plugin / tool catalogue before new code

**Search before you build, and build in the shared place.**

1. **Search `<TOOL_HOME>`** — index, registry, interface contracts, guides — for an existing capability.
2. **Found** → reuse or compose it. Two implementations of one capability is a defect.
3. **Not found** → build it **inside the catalogue**, following its existing directory family, contracts, validation entry point, and permission model — then run the catalogue's registry validator.

Never ship a half-tool inside a consuming project, and never bypass the catalogue's authority declarations. A tool written inside a project is invisible to the next project, so the capability gets rebuilt — the cost this ladder exists to prevent. Host adapters are catalogue entries too: **`reference/ui-and-tools.md`**, `boundary/hosts/CONTRACT.md`.

---

## 6. Clean project structure

```
<project>/
├─ src/                # core code used by build/runtime
├─ docs/               # reader-facing documentation
├─ dev-docs/           # design, decisions, interfaces, migration notes
├─ verify-evidence/    # build/test output, reports, screenshots, path checks
├─ cxbuild/            # ALL build output: desktop/web/app, installers, unpacked bundles, launchers
└─ temp/               # every scratch file; safe to empty at any time
```

1. **One build-output root** (`<BUILD_ROOT>`, default `cxbuild/`): desktop, web, app, packaging, installers, unpacked directories, and "one-click open" conveniences such as a launcher `.bat`.
2. **One dependency pointer** (§3). No secondary caches, no vendor trees, no nested installs.
3. **Scratch only in `<TMP>`** (`temp/`). Intermediates in the project root or in `src/` are a defect.
4. **Documentation split**: audience-facing → `docs/`; developer/maintenance → `dev-docs/`. Do not mix.
5. **No half-migrations**: when moving an output path, update every script reference in the same change.
6. **Legacy compatibility is explicit**: if a release pipeline must keep an old path, record the exception in `dev-docs/` instead of silently keeping two layouts.
7. **The top level stays closed.** A new top-level entry is a decision, not a side effect: put the file under an existing root, or add the name to the boundary's `EXTRA_TOP_LEVEL` row and record the reason. Already-existing entries are not retroactively violations.
8. **Make it a mechanism, not a memory.** A layout rule that lives only in a document decays: it is read once, and nothing reacts to a misplaced file. If your host can inject prompt context and intercept a write before it lands, install a boundary adapter that injects the resolved values and rejects the offending write — this text stays portable, the adapter is the host-specific half. Contract: `boundary/hosts/CONTRACT.md`; the DSH adapter ships at `<TOOL_HOME>/agent-adapters/dsh-kalcirite-boundary`.

---

## 7. Archive on change, delete with evidence

1. After every substantial change, dispose of what it superseded: move it to `archive/` under its own subtree (`src/archive/`, `docs/archive/`, `dev-docs/archive/`), or delete it when recovery has no value.
2. An archive entry records original path, date, and successor — in `archive/README.md` or the change log.
3. **Pre-deletion checklist**: not inside the dependency cache, not a key source snapshot, not user data, already committed or otherwise backed up, and no remaining references (`grep` before delete).
4. **Never delete incidentally**: `.git`, lockfiles, existing evidence, junction targets, user data. Never delete a path to make a check pass.
5. Update the affected `docs/` and `dev-docs/` in the same change, so the main path shows only the current truth.

---

## 8. Evidence-gated reporting, on a verified fact baseline

- Claims of success require an observable artifact — build log, test output, path check, screenshot — written into `<EVIDENCE>`. Verification is **one central pass after the build is complete**, not a running commentary of partial checks.
- Distinguish clearly: **verified**, **attempted**, **not attempted**. Never present the third as the first. If a capability could not be observed (route unavailable, service down, no session), say so and name what would confirm it.
- Paths, ports, toolchain versions, data directories: **verify, then state** — never assert from memory. A path that "should" exist is a hypothesis; `Test-Path` / `test -e` is the fact.
- When a documented path no longer exists, replace the reference with the current source of truth and record the change; do not keep following a stale document. Machine-specific facts (paths, proxy addresses, accounts, ports) belong in the boundary file, **not** in reusable rule text.

---

## 9. Red lines

- **Starting any edit, build, install, or deletion while the boundary is unresolved** — `<PLACEHOLDER>` tokens present, no boundary file, or an empty local profile block. Interview first (§0.2).
- Installing dependencies inside a project, or fetching from the network when the cache could satisfy the closure.
- Deleting a linked dependency directory, or running a "clean" command against cache-backed artifacts.
- Copying or creating dependency payloads inside any project.
- Sending judgement work to a cheap model to save money (architecture, trade-offs, security).
- Faking model routing with fields the session does not expose.
- Hand-writing colour constants or starting a parallel design language.
- Asserting paths/ports/versions from memory instead of checking.
- Claiming "verified" with nothing in `verify-evidence/`.

---

*Read on demand: `reference/interview.md` (unresolved boundary or changed machine), `reference/delegation.md` (delegating, routing, handoff), `reference/dependency-cache.md` (installs and repair), `reference/ui-and-tools.md` (UI, catalogue, adapters), `boundary/DELEGATION.md` (generic-vs-DSH delegation), `boundary/hosts/CONTRACT.md` (writing an adapter).*

*KalciriteThinking — portable edition. Machine-specific values belong in `PROJECT-BOUNDARY.md`; procedures belong in `reference/`. Keep this file environment-neutral when editing it.*
