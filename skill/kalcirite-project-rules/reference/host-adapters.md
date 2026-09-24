# Boundary adapter contract

Read this when: writing an adapter for a host, reviewing what an adapter is allowed
to assume, or deciding whether a host needs one at all.

The rule text (`SKILL.md`, one level up) is the **portable half**:
judgement, ordering, and the discipline. It is read once and then decays, because
nothing reacts to a misplaced file. An **adapter** is the host-specific half that
makes the discipline mechanical.

An adapter is **optional**. A host without one still gets the full rules; it just
gets no enforcement. Never make the rule text depend on an adapter existing.

## The three obligations

| # | Obligation | Why | Optional? |
|---|---|---|---|
| 1 | **Inject** the resolved boundary into every session's context, with the layout contract and the protected roots spelled out | the model should not have to remember to look up `PROJECT-BOUNDARY.md` | no — this is the minimum useful adapter |
| 2 | **Intercept** a write, edit, or command that would break a rule, and refuse it with the rule name, the key used, and what to do instead | a rule nobody can violate is the only rule that survives context loss | no |
| 3 | **Gate** until the boundary is answered (`requireConfigured`) | an unanswered boundary means every path is a guess | recommended |

Optional extras: deny-once forgiveness in a warning mode, a strict enforcement
mode, per-rule disable switches, a configuration of the accepted top-level set.

## 1. Resolution (must match the rule text)

Resolve `PROJECT-BOUNDARY.md` in the rule text's §0.1 order and stop at the first
hit:

1. project root — `<cwd>/PROJECT-BOUNDARY.md`, or a `PROJECT-BOUNDARY` section in
   the project's `AGENTS.md` / `.kalcirite/boundary.md`;
2. the skill's own directory — `PROJECT-BOUNDARY.md` beside `SKILL.md`;
3. agent config root — `$DSH_HOME/PROJECT-BOUNDARY.md`, `~/.claude/PROJECT-BOUNDARY.md`, …;
4. the `kalcirite:local-profile` block inside the loaded `SKILL.md`;
5. domain defaults.

Read the `kalcirite:answers` JSON block when it is present; it is authoritative.
Fall back to the markdown rows only when the block is absent, unparseable, or
yields nothing — a hand-edited file is a supported case. Either way **drop empty
values**: blank means "no assumption", and it must never become the value.

Cache the result briefly (seconds, not minutes) and key the cache on the working
directory, or a boundary edited mid-session will not take effect. Do not cache
across a working-directory change.

## 2. Injection

Inject, as one self-contained block:

- a marker naming the adapter, so both the user and the model can see enforcement
  is active;
- the absolute boundary path and the project root actually in use;
- the layout contract — build root, scratch root, evidence root, docs roots;
- the dependency cache path, and the explicit statement that a dependency payload
  is never created inside a project;
- the shared tool catalogue and canonical UI source, when configured;
- the accepted top-level set, **or** a pointer to where it is enforced;
- the protected roots (the cache, the catalogue, the UI source, anything the
  boundary declares `NEVER_DELETE`);
- one line telling the model where the full rule text is and to read it.

Keep it short. It is injected into every session; a long block is paid for on
every request, and the parts a model cannot act on are noise.

## 3. Interception

Intercept at the tool layer, before the write lands. Cover **all three** surfaces:
file writes/edits, shell commands, and any tool that creates files as a side
effect.

A refusal must name:

| Element | Example |
|---|---|
| the rule | `Kalcirite layout` |
| the offending path and why | `` `node_modules/` would create a dependency payload inside this project`` |
| the value it consulted | `use the shared cache at <DEP_CACHE>` |
| the acceptable alternative | `place it under cxbuild/ instead` |
| how to proceed deliberately | `add \`newdir\` to the boundary's EXTRA_TOP_LEVEL row` |

A refusal that only says "denied" is a bug report, not an instruction.

### Recommended rule set

| Rule | Trigger | Severity |
|---|---|---|
| dependency payload in project | creating `node_modules` / `.venv` / `vendor` / toolchain dirs inside the project | block |
| build output outside the build root | creating `dist` / `build` / `out` / `target` / `release` outside `<BUILD_ROOT>` | block |
| new top-level entry | creating a top-level name outside the accepted set | block (warn-once is acceptable) |
| protected root touched | a delete command whose text matches a protected root | block |
| install into the project | a package-manager install command whose text names the project | warn |
| boundary unanswered | any write/edit/install before the boundary resolves | hard gate, no retry |

Command rules are **text heuristics** and must be documented as such: they raise
confidence, they are not a sandbox.

### Modes

| Mode | Writes | Commands | Use |
|---|---|---|---|
| `off` | injection only | injection only | adoption, or a shared machine other people use |
| `warn` | first offending write denied once per path, retry proceeds | same, per command | default while trust is being established |
| `enforce` | hard deny | hard deny for blocking rules; still deny-once for warnings | once the layout is stable |

"Deny once" must be keyed on something stable — per agent and relative path for
writes, per agent, rule, and command text for commands — or the retry produces a
different verdict every time.

## 4. Reporting status

An adapter that cannot be observed working will be assumed broken. Make the
following cheap to check, and report it truthfully:

- the resolved boundary path and project root;
- the mode in effect;
- whether the boundary is configured or the gate is holding;
- the count of refusals, or at least that refusals are reaching the user.

Do not claim enforcement is live without observing a refusal. Injection and
interception are two different capabilities; shipping the first does not prove
the second.

## 5. Non-negotiables for adapter authors

- The adapter **never writes** to the boundary file, the machine-config document,
  or the skill directory. Installs are the installer's job.
- The adapter **never invents** a value. A blank key stays blank; a missing key
  stays missing.
- The adapter **never blocks on a value the rules say is optional**. Only the
  dependency payload, build-output, and new-top-level rules are hard.
- The adapter must be **disableable from one config line**, and disabling it must
  leave every other capability intact.
- Host-specific wording, key names, and configuration live in the adapter, never
  in `SKILL.md`.

## 6. Shipped bindings

A **binding** document is written per host and lives in the rules repository — never
inside the installed skill, and never in `SKILL.md`. The repository's location is
recorded in §0 of the machine-config document. The binding shipped today is the DSH
reference implementation; the adapter code itself lives in the shared tool catalogue
as `agent-adapters/dsh-kalcirite-boundary`.

A binding document should state: where the boundary is read from, how injection
is installed, which tools are intercepted, how the mode is set, and how to prove
enforcement is live.
