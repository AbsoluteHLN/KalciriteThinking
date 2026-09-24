---
name: kalcirite-project-rules
description: "Portable engineering discipline for multi-project agent work: cost-tiered model routing and self-contained session handoff, a single shared dependency cache (no per-project installs), a canonical UI source with token-only styling, a shared plugin/tool catalogue before any new build, a fixed clean project layout with one build-output root, build-before-verify ordering, archive-on-change hygiene, and evidence-gated claims. Load before working in any repository that follows these boundaries."
whenToUse: "Working in or delegating work inside a repository that shares a machine-level dependency cache, a canonical UI source, or a shared tool catalogue; installing/building dependencies; resetting or extending a UI; deciding where a reusable plugin or tool belongs; reorganizing project structure and build output; or delegating to cheaper models. Also when adopting this skill on a new machine — that requires the §0.2 first-run interview before any work."
metadata:
  version: "3.0"
  kind: "portable-rules"
  scope: "per-machine"
  config: "PROJECT-BOUNDARY.md — project root, then this skill's directory, then the agent config root (§0.1)"
  localProfile: "block between the kalcirite:local-profile markers below; empty means run the §0.2 interview first"
---

# Kalcirite project rules (portable)

A compact, agent-agnostic working discipline for **multi-project machines**: several repositories on one disk that must share one dependency cache, one UI foundation, one tool catalogue, and one predictable layout.

Nothing here is tied to a vendor, an IDE, or a single agent product. Every machine-specific value — cache path, UI source path, tool home, project list — lives in **the boundary file**, `PROJECT-BOUNDARY.md`, resolved per §0.1. If that file is missing, the rules still hold; only the concrete paths must be resolved before use — and that is what the §0.2 interview is for.

<!-- kalcirite:local-profile:begin -->
## Local profile

> **Empty — UNRESOLVED.** No machine values are recorded in this file yet.
> Run the §0.2 interview (or `scripts/install-skill.ps1`, which asks the same questions) and write the answers back here before doing any work.
<!-- kalcirite:local-profile:end -->

---

## 0. How to use this document

### 0.1 Resolution order for any path or value

The **boundary file** is `PROJECT-BOUNDARY.md`. Look for it in this order and use the first hit:

1. **Project root** — `<project>/PROJECT-BOUNDARY.md` (or a `PROJECT-BOUNDARY` section in the project's `AGENTS.md` / `.kalcirite/boundary.md`). Highest priority: a project may override any machine value.
2. **This skill's own directory** — `PROJECT-BOUNDARY.md` next to this `SKILL.md`. The installer writes it here, so it travels with the skill.
3. **Agent config root** — `$DSH_HOME/PROJECT-BOUNDARY.md`, `~/.claude/PROJECT-BOUNDARY.md`, `~/.config/<agent>/PROJECT-BOUNDARY.md`, …
4. **The local profile block above**, if it has been filled in.
5. **Domain defaults** — the fallbacks written in this document as `<PLACEHOLDER>`.

Never invent a path, port, version, or tool name. **Verify before asserting**: existence first, then use.

### 0.2 First-run interview — required before any work

**Gate.** If the boundary file is missing, still contains `<PLACEHOLDER>` or `<…>` tokens, or the local profile above says UNRESOLVED — **stop and interview the user first**. Do not edit, build, install, reorganise, or delete anything until the answers are written back. This document alone is not enough to work safely: it knows the rules, not the machine.

Ask **in one batch**, in the user's language, each question carrying a **probed default** labelled *detected* (you read it) or *guess* (you did not).

| # | Ask | Keys | How to probe | If the user leaves it blank |
|---|---|---|---|---|
| 1 | Which single directory do all dependencies install into? | `DEP_CACHE` (+ derived sub-keys) | workspace drive + `\dependency-cache`; `pnpm store path`; `npm config get cache` | **blocking** — no dependency work at all |
| 2 | Keep the conventional sub-layout under it (`pnpm-store`, `npm-cache`, `pip-cache`, `cargo`, `electron\Cache`, `electron-builder\Cache`)? | derived | which sub-directories already exist | name each one individually |
| 3 | Is there a canonical UI source (design system / component engine), and where? | `UI_SOURCE`, `UI_VERSION`, `UI_PREVIEW` | sibling `*ui*` / `ui-source` directories | record `none`; §4 degrades to "one UI source per project, and styling must still be tokenised" |
| 4 | Is there a shared tool/plugin catalogue, and where? | `TOOL_HOME`, `TOOL_INDEX`, `TOOL_REGISTRY`, `TOOL_VALIDATOR` | sibling catalogue repo; `INDEX.md`, `registry.json`, `**/validate-*` | record `none`; §5 degrades to "search the project's own `tools/` first" |
| 5 | Build output root, scratch root, evidence root, docs roots? | `BUILD_ROOT`, `TMP`, `EVIDENCE`, `DOCS`, `DEV_DOCS` | defaults `cxbuild/`, `temp/`, `verify-evidence/`, `docs/`, `dev-docs/` | use the defaults |
| 6 | Which model provider is authorised, and what are its cheap model **ids** (not display names)? Plus the delegation facts: which sub-agent tools exist, can a delegation pick its own route, which setting enables that, when does it take effect, any concurrency limit? | `ROUTE_PROVIDER`, `CHEAP_MODELS`, `ROUTE_TOOL`, `HOST_AGENT`, `DELEGATION_TOOLS`, `ROUTE_SELECTION_SUPPORTED`, `ROUTE_ENABLE_SETTING`, `ROUTE_TAKES_EFFECT`, `CONCURRENCY_LIMIT` (see §2.5) | the agent's model settings / config file; the host's tool list | record `none` for each; delegation stays on the parent route and model selection is reported as unavailable (§2.3) |
| 7 | What shell/OS constraints change command syntax? | `SHELL_NOTE` | `$PSVersionTable`, `Get-Command pwsh`, `bash` availability | assume nothing; re-ask when a command fails |
| 8 | Proxy, fixed ports, and paths or data that must never be deleted? | `PROXY`, `PORTS`, `NEVER_DELETE` | project docs, config files, registry | record what is confirmed; mark the rest `(unverified)` |

Interview rules:

1. **Write the answers back before proceeding.** Prefer the **project root** (1) when the values are project-scoped, otherwise this skill's directory (2), then the config root (3). Also fill the local profile block above whenever this file is writable. An answer that lives only in the conversation is lost.
2. **Verify every path as you record it**, with an existence check. A path that does not exist is written with `(unverified)`, never silently.
3. **Blank is a legitimate answer.** Blank or `none` makes the rules *stop and report* for that domain; it never authorises guessing.
4. **Re-ask when the environment changes** — a moved cache, a new UI source, a new provider, a new shell. Update the boundary file, not this rule text.
5. If the user declines to answer, state which domains are now unrouted, and keep working only in domains that need no boundary value.
6. **Do not interview twice.** If a filled boundary file already exists, read it and proceed; ask only about values that are new, stale, or contradictory.

### 0.3 Placeholders

| Placeholder | Meaning | Default fallback |
|---|---|---|
| `<DEP_CACHE>` | The one dependency cache root on this machine | §3 |
| `<UI_SOURCE>` | Canonical UI engine/source of truth | §4 |
| `<TOOL_HOME>` | Shared plugin/tool catalogue repo | §5 |
| `<BUILD_ROOT>` | Per-project build output directory name | `cxbuild/` |
| `<TMP>` | Per-project scratch directory | `temp/` |
| `<EVIDENCE>` | Per-project verification evidence directory | `verify-evidence/` |

### 0.4 Non-negotiables

- **Build first, verify once.** Do not loop build→verify→build.
- **No per-project dependency installs.** One cache, linked in.
- **Reuse before rebuild.** UI and tools are found, not re-invented.
- **No claim without evidence.** Unobserved capability is unverified capability.
- **No work before the machine is known.** Interview first (§0.2), then act.

---

## 1. Execution order (the short version)

1. **Locate** — project root, boundary file, target module. Verify every path you are about to depend on.
2. **Recon reuse surface** — does `<DEP_CACHE>` already satisfy the closure? Does `<TOOL_HOME>` already have the capability? Does `<UI_SOURCE>` already have the component?
3. **Build first** — make the change complete, then build, and confirm the artifact landed in `<BUILD_ROOT>`.
4. **Verify once, centrally** — run the project's own check scripts; write command, timestamp, result, and raw failure text into `<EVIDENCE>`.
5. **Delegate the cheap parts** — bulk reading, per-file sweeps, doc drafting go to low-cost models (§2); the main session keeps design, judgement, and final adjudication.
6. **Archive on change** — outdated files go to `archive/` under their own subtree, or are safely deleted (§7).
7. **Report** — changed files with paths, evidence paths, unverified items, residual risk, next step.

---

## 2. Cost-tiered model routing and session handoff

### 2.1 Principle

Spend the expensive model on judgement, not on reading. Route work by **required reasoning depth**, not by task size or by novelty.

| Work | Tier |
|---|---|
| Design, architecture, trade-offs, security, final adjudication | Strong / parent route |
| Bulk file reading, mechanical refactors, log triage, structured extraction, doc drafting, per-file audits | Cheapest capable route |

### 2.2 Routing procedure

1. **Discover, never guess.** Call the catalog/discovery tool for subagent models (in DSH: `list_subagent_models`; elsewhere: the equivalent route-listing tool or config file) before naming a model.
2. **Preferred cheap family** — the boundary file lists this machine's preferred provider and its exact model ids. Names shown in a UI are often *display names*; the routing field usually needs the **configured id**. Read the config, do not transcribe the label.
3. **Fuzzy-match when the exact name is absent** — match on family keywords (e.g. `GLM`, `DeepSeek`, `Qwen`, `Flash`, `mini`, `small`) case-insensitively and pick the nearest cheap sibling.
4. **Never leave the authorised provider.** The boundary file names it (e.g. a campus/self-hosted gateway). Cross-provider guessing is a failure, not initiative.
5. **Record the substitution** — if you used a different model than intended, say so in the report.
6. **Do not burn budget finding a name** — no settings edits, no probing loops, no network exploration to resolve a model id.

### 2.3 Preconditions are real (check, do not assume)

Whether you can choose a model at all, where the switch lives, and when it takes effect are **host facts, not rule facts** — they belong in the boundary file (§2.5). Treat "the session exposes `provider` / `model`" as a hypothesis to verify, not a default.

- **Verify before delegating with a route.** If the delegation tool does not offer the field, the capability does not exist for this session.
- **If the fields are not available: do not fabricate them.** Delegate on the inherited route, or do the work inline, and state that model selection was unavailable.
- **Enablement usually applies at session creation.** Many hosts read the routing policy once and inherit it into children, so editing settings mid-session changes nothing for the running session. Open a new session instead of pretending.
- **Worked example (DSH).** `subagent` / `subagent_fork` expose `provider` / `model` / `reasoning_effort` plus `list_subagent_models` only when the session was composed with `subagent-model-selection: {enabled: true, allowedModels: [...]}`; that policy is recorded at session creation and inherited by children, and restored sessions keep the policy they recorded. `subagent_fork` deliberately stays on the parent route (KV-cache reuse) even when the fields are available.

### 2.4 Session handoff protocol

A child agent does not see the parent conversation. Every delegation must be self-contained:

| Section | Content |
|---|---|
| Context | Why this exists; what is already true; relevant file paths |
| Task | One concrete, bounded deliverable |
| Boundary | Exactly what may be read and written; what must not be touched |
| Deliverable | Expected artifact and its absolute target path |
| Acceptance | How the result will be judged |
| Forbidden | Known traps: network installs, deleting caches, touching user data |

Rules:
- **Absolute paths only.** Materialise attachments to disk first, then hand over the path — never a description of where something "should" be.
- **Name the route** (`provider` + `model`) and the read/write scope in the prompt.
- **Return format**: execution summary, changed-file list, evidence paths, open questions, what the child could not verify.
- **Human handoff** (new session or another person): current state, files changed, evidence paths, next step. Not a narrative of the process.
- Run independent delegations in parallel; wait in the foreground only when the next action depends on the result.

### 2.5 Delegation and model selection are host-specific — interview them

**Sub-agent creation and route selection are not universal.** The tools differ between hosts, and whether a delegation may name its own model is a property of *that* host, not of this rule text. So these are interview subjects (§0.2) and boundary values, exactly like cache paths:

| Boundary key | Ask | Why it changes behaviour |
|---|---|---|
| `HOST_AGENT` | Which agent / harness is this, and which version? | decides which equivalent wording applies |
| `DELEGATION_TOOLS` | Which delegation tools exist, and how do they differ? | a fresh-context child and a fork of the parent conversation receive and return different things |
| `ROUTE_SELECTION_SUPPORTED` | Can a delegation name its own provider / model? | if not, either do the work inline or accept the inherited route — do not pretend |
| `ROUTE_TOOL` | How are the available routes discovered? | discover, never guess |
| `ROUTE_ENABLE_SETTING` | Which setting enables route selection? | tells the user the exact place to change |
| `ROUTE_TAKES_EFFECT` | When does that change take effect — new session, restart, immediately? | decides whether to open a new session or just retry |
| `CONCURRENCY_LIMIT` | Any concurrency or budget ceiling? | parallel fan-out must respect it |

**Absence of a record means "not supported."** Fall back to the inherited route, say so in the report, and never invent `provider` / `model` fields. A generic walkthrough and the DSH specifics are in `boundary/DELEGATION.md` in the source repository.

---

## 3. One dependency cache, linked — never vendored

### 3.1 Hard rules

1. **Query the cache first** for every install, resolve, or download (package managers, language toolchains, app bundlers). Cache hit → use it. No online reinstall.
2. **No dependency payload inside a project.** `node_modules`, `.venv`, vendored dependency trees, toolchain caches exist **only** in `<DEP_CACHE>`; the project holds a junction / symlink / configured pointer at most.
3. **Never clean, delete, reorganise, or overwrite the cache.** Archive/quarantine areas inside it are read-only.
4. **Confirm closure before building.** If the closure cannot be satisfied from the cache: **stop and report the missing list**. "Reinstall dependencies" is not a repair step.
5. **Fetching is an exception with a gate.** If a package is genuinely absent, report the list, get explicit human authorisation, then bring the new payload **into the cache** and update the cache index.
6. **No shadow runtimes.** Interpreters and virtual environments must come from the cache, not from a system Conda, a user-level cache, or a project-local `.venv`.
7. **Never delete a linked dependency directory** — deleting a junction recursively punches through into the shared cache. Never run a toolchain's "clean" command on a cache-backed build.

### 3.2 Pointer mechanisms (pick per ecosystem)

| Ecosystem | Mechanism | Note |
|---|---|---|
| Node (pnpm) | workspace config `storeDir` + `virtualStoreDir`; `node_modules` junction into the cache | pnpm may ignore `.npmrc`'s store dir; pin it in the workspace file |
| Node (npm) | `npm_config_cache`; junction for the installed tree | |
| Rust/Cargo | `CARGO_HOME` (+ optional per-project `.cargo/config.toml`) | offline builds; the embedded registry path is expected and accepted |
| Python | `PIP_CACHE_DIR`; interpreter and site-packages owned by the cache | disable user site-packages |
| Electron / build tools | tool-specific cache env vars | avoids re-downloading binaries |

### 3.3 Executable checks

```powershell
pnpm config get store-dir        # expect the cache store path
npm  config get cache            # expect the cache path
$env:CARGO_HOME                  # expect the cache cargo path
$env:PIP_CACHE_DIR               # expect the cache pip path
(Get-Item '<project>\node_modules' -Force).LinkType   # expect Junction / SymbolicLink
```

```bash
readlink -f node_modules          # expect a path inside the cache
test -e "$DEP_CACHE" && echo present
```

Bypass the package-manager script wrapper when it tries to re-verify and prune modules (a common way junctions get destroyed): call the tool binary directly (e.g. `node_modules/.bin/<tool> build`).

### 3.4 Failure protocol

1. Cache hit → link → build.
2. Cache miss → **stop** → report the exact missing packages and why they are needed.
3. Reported and authorised → fetch once → land the payload in the cache → link → record it in the cache index.
4. Never: install into the project, create a second store, or vendor a copy.

---

## 4. One canonical UI source, token-only styling

### 4.1 Principle

When a UI reset / upgrade / adjustment is requested, the default is to **integrate the canonical UI source** (`<UI_SOURCE>`) and follow its own documentation. Generating fresh UI files inside a project is reserved for the case where a project is published independently and genuinely needs a self-contained subset.

### 4.2 Procedure

1. Read `<UI_SOURCE>`'s top-level README (version architecture) and the **selected version's** `README` + `contract` before writing any markup or style.
2. Pick the version deliberately — newest stable unless the request needs the character of an older one. State the choice and why.
3. Run the source's own build/verify/test scripts rather than inventing a pipeline.
4. **Styling split**: the project's own stylesheet carries **layout and pass-through only**. Colour, elevation, control appearance, state, motion come from the UI system's tokens / variants / theme attributes. No hand-written colour constants, no parallel design language.
5. Motion comes from the UI system's documented motion variants, not from newly invented animation constants.
6. If a snapshot must live in the project, ship **built artifacts only**, and record the source path and version. The engine stays canonical upstream; do not maintain a fork inside the project.

### 4.3 Failure signals

- A new colour literal in project CSS.
- A control styled from scratch while the system already exposes that variant.
- A UI file tree generated inside the project without an independent-publish justification.
- A version chosen without reading its contract.

---

## 5. Shared plugin / tool catalogue before new code

### 5.1 Reuse ladder

1. **Search the catalogue** (`<TOOL_HOME>`: index, registry, interface contracts, guides) for an existing capability.
2. **Existing capability covers it** → reuse or compose it. Two implementations of one capability is a defect.
3. **Not found** → build it **inside the catalogue**, following its existing boundaries: same directory family, same contracts, same validation entry point, same permission model.
4. **Unify the interface** — naming, input/output shape, error model, and authority of the new entry must match the catalogue's conventions.
5. Never ship a half-tool inside a consuming project, and never bypass the catalogue's permission/authority declarations.

### 5.2 Catalogue boundaries to honour

- **Canonical vs derived**: exactly one source of truth per connector/component; consumers link or import, they do not copy.
- **Executable vs metadata-only**: read-only catalogues stay non-executable.
- **Authority gates**: entries that execute or construct sandboxes may be gated behind a runtime supervisor; respect the declared authority rather than importing the code directly.
- **Validation entry point**: after any catalogue change, run its registry validator.

---

## 6. Clean project structure

```
<project>/
├─ src/                # core code used by build/runtime
├─ docs/               # reader-facing documentation
├─ dev-docs/           # developer documentation: design, decisions, interfaces, migration notes
├─ verify-evidence/    # verification evidence: build/test output, reports, screenshots, path checks
├─ cxbuild/            # ALL build output: desktop/web/app, installers, unpacked bundles, launcher scripts
└─ temp/               # every scratch file; safe to empty at any time
```

Rules:

1. **One build-output root** (`<BUILD_ROOT>`, default `cxbuild/`): desktop, web, app, packaging, installers, unpacked directories. "One-click open" conveniences (e.g. a launcher `.bat`) belong here too.
2. **One dependency pointer** (§3). No secondary caches, no vendor trees, no nested installs.
3. **Scratch only in `<TMP>`** (`temp/`). Intermediates in the project root or in `src/` are a defect.
4. **Documentation split**: audience-facing → `docs/`; developer/maintenance → `dev-docs/`. Do not mix.
5. **No half-migrations**: when moving an output path, update every script reference in the same change.
6. **Legacy compatibility is explicit**: if an existing release pipeline must keep an old path, record the exception in `dev-docs/` instead of silently keeping two layouts.
7. **Make it a mechanism, not a memory.** A layout rule that lives only in this document decays: it is read once, and nothing reacts to a misplaced file. If your host can inject prompt context and intercept a write before it lands, install a boundary adapter that injects the resolved values and rejects the offending write — keep this text portable and let the adapter be the host-specific half. A DSH adapter ships in the shared catalogue at `<TOOL_HOME>/agent-adapters/dsh-kalcirite-boundary`.

---

## 7. Archive on change, delete with evidence

1. After every substantial change, dispose of what it superseded: move it to `archive/` under its own subtree (`src/archive/`, `docs/archive/`, `dev-docs/archive/`), or delete it when recovery has no value.
2. An archive entry records: original path, date, and successor. Keep it in `archive/README.md` or the change log.
3. **Pre-deletion checklist**: not inside the dependency cache, not a key source snapshot, not user data, already committed or otherwise backed up, and no remaining references (`grep` before delete).
4. **Never delete incidentally**: `.git`, lockfiles, existing evidence, junction targets, user data.
5. Update the affected `docs/` and `dev-docs/` in the same change, so the main path shows only the current truth.

---

## 8. Evidence-gated reporting

- Claims of success require an observable artifact: build log, test output, path check, screenshot — written into `<EVIDENCE>`.
- Verification is **one central pass after the build is complete**, not a running commentary of partial checks.
- Distinguish clearly: **verified**, **attempted**, **not attempted**. Never present the third as the first.
- If a capability could not be observed (route unavailable, service down, no session), say so explicitly and name what would confirm it.

---

## 9. Fact baseline discipline

- Paths, ports, toolchain versions, data directories: **verify, then state** — never assert from memory.
- A path that "should" exist is a hypothesis; `Test-Path` / `test -e` is the fact.
- When a documented path no longer exists, replace the reference with the current source of truth and record the change — do not keep following the stale document.
- Keep machine-specific facts (paths, proxy addresses, accounts, ports) in the boundary file, **not** in reusable rule text. Reusable text stays portable.

---

## 10. Red lines

- **Starting any edit, build, install, or deletion while the boundary is unresolved** — `<PLACEHOLDER>` tokens still present, no boundary file, or an empty local profile block. Interview first (§0.2).
- Installing dependencies inside a project, or fetching from the network when the cache could satisfy the closure.
- Deleting a linked dependency directory, or running a "clean" command against cache-backed artifacts.
- Copying or creating dependency payloads inside any project.
- Sending judgement work to a cheap model to save money (architecture, trade-offs, security).
- Faking model routing with fields the session does not expose.
- Hand-writing colour constants or starting a parallel design language.
- Asserting paths/ports/versions from memory instead of checking.
- Claiming "verified" with nothing in `verify-evidence/`.

---

*KalciriteThinking — portable edition. Machine-specific values belong in `PROJECT-BOUNDARY.md`. Keep this file environment-neutral when editing it.*
