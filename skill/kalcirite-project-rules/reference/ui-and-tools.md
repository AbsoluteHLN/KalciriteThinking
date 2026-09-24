# One UI source, one tool catalogue

Read this when: a UI is to be built, reset, upgraded, or restyled; or a reusable
plugin / tool / adapter is to be written.

Both domains follow the same ladder: **the capability probably already exists —
search before you build, and build in the shared place when it does not.**

## Part 1 — UI

### Principle

When a UI reset / upgrade / adjustment is requested, the default is to **integrate
the canonical UI source** (`<UI_SOURCE>`) and follow its own documentation.
Generating fresh UI files inside a project is reserved for the case where a project
is published independently and genuinely needs a self-contained subset.

### Procedure

1. Read `<UI_SOURCE>`'s top-level README (version architecture) and the **selected
   version's** `README` + `contract` before writing any markup or style.
2. Pick the version deliberately — newest stable unless the request needs the
   character of an older one. State the choice and why.
3. Run the source's own build/verify/test scripts rather than inventing a pipeline.
4. **Styling split**: the project's own stylesheet carries **layout and pass-through
   only**. Colour, elevation, control appearance, state, motion come from the UI
   system's tokens / variants / theme attributes. No hand-written colour constants,
   no parallel design language.
5. Motion comes from the UI system's documented motion variants, not from newly
   invented animation constants.
6. If a snapshot must live in the project, ship **built artifacts only**, and record
   the source path and version. The engine stays canonical upstream; do not maintain
   a fork inside the project.

### Failure signals

- A new colour literal in project CSS.
- A control styled from scratch while the system already exposes that variant.
- A UI file tree generated inside the project without an independent-publish
  justification.
- A version chosen without reading its contract.

### When `<UI_SOURCE>` is blank

Record `none`, build one UI source per project, and still keep the styling split:
tokens and variants live in the project's own token file, and component CSS carries
layout only. The discipline survives; only the upstream path is missing.

## Part 2 — Shared plugin / tool catalogue

### Reuse ladder

1. **Search the catalogue** (`<TOOL_HOME>`: index, registry, interface contracts,
   guides) for an existing capability.
2. **Existing capability covers it** → reuse or compose it. Two implementations of
   one capability is a defect.
3. **Not found** → build it **inside the catalogue**, following its existing
   boundaries: same directory family, same contracts, same validation entry point,
   same permission model.
4. **Unify the interface** — naming, input/output shape, error model, and authority
   of the new entry must match the catalogue's conventions.
5. Never ship a half-tool inside a consuming project, and never bypass the
   catalogue's permission/authority declarations.

A tool written inside a project is invisible to the next project, so the same
capability gets rebuilt — that is the cost this ladder exists to prevent.

### Catalogue boundaries to honour

- **Canonical vs derived**: exactly one source of truth per connector/component;
  consumers link or import, they do not copy.
- **Executable vs metadata-only**: read-only catalogues stay non-executable.
- **Authority gates**: entries that execute or construct sandboxes may be gated
  behind a runtime supervisor; respect the declared authority rather than importing
  the code directly.
- **Validation entry point**: after any catalogue change, run its registry validator.

### When `<TOOL_HOME>` is blank

Search the project's own `tools/` first and reuse what is there. Do not create a
machine-level catalogue without being asked — propose it instead, and say what it
would unify.

## Part 3 — Host adapters

Rules in a document decay: they are read once, and nothing reacts to a misplaced
file. Where a host can inject prompt context and intercept a write before it lands,
that host gets an **adapter** — the host-specific half of the same discipline.

- Adapters live in the shared catalogue, never inside a consuming project.
- An adapter injects the *resolved* boundary values, so the rule text stays
  environment-neutral.
- An adapter may refuse a write that would break the layout, and must say which
  rule and which key it used.
- The adapter contract (what any host must implement, and what stays optional) is
  `boundary/hosts/CONTRACT.md`; shipped host bindings are under `boundary/hosts/`.
- Building one is catalogue work: search first, follow the catalogue's conventions,
  register it, and verify it with its own test entry point.
