# Host detail — DeepSeek Harness (DSH)

Read this when `HOST_AGENT` says DSH (DeepSeek Harness), or when installing or
adapting the skill for a DSH session. Machine-specific values below are
placeholders; the resolved ones live in the boundary file.

## Layout

- Home: `<DSH_HOME>` (env var `DSH_HOME`).
- **Skill root:** `<DSH_HOME>\skills\` — one directory per skill, `SKILL.md` at its root.
- **Two-skill shape (recommended):** `kalcirite-project-rules` (clean install,
  local profile left empty) with `kalcirite-project-boundary` beside it; its
  boundary file is the §0.1 **step 2** candidate. The skill catalog lists both;
  the boundary skill's description says it carries values, not rules.
- **Single-skill shape (legacy):** the boundary file sits next to `SKILL.md` in
  the rules skill directory (step 3) and the local-profile block is filled.
- Agent config root (step 4 fallback): `<DSH_HOME>\PROJECT-BOUNDARY.md`.

## How the host reads it

- The skill catalog is built from the `name` / `description` / `whenToUse`
  frontmatter; DSH surfaces the catalog in the session prompt and can bring a
  skill's content into context on demand.
- The adapter resolves the boundary file per §0.1 and caches it for seconds,
  keyed on the working directory — a value edit takes effect without a session
  restart. Host **plugin code** is not hot-reloaded: after editing the adapter
  itself, restart the DSH process.

## Enforcement — the host adapter

DSH is the reference host for the adapter contract (`../host-adapters.md`). The
adapter ships in the shared tool catalogue (the boundary's `TOOL_HOME`) as
`agent-adapters/dsh-kalcirite-boundary`
and installs as a host plugin row contributing two capabilities and a gate:

| Capability | How | Observable as |
|---|---|---|
| Injection | a prompt-context section | a `<kalcirite-boundary>` block in the session context |
| Interception | a tool guard on write / edit / shell | a refusal naming the rule and the key it consulted |
| Gate | `requireConfigured` (default on) | any write or install refused until the boundary resolves |

- Modes: `off` (injection only), `warn` (default — first offending write denied
  once per path/command, the identical retry proceeds), `enforce` (hard deny).
- Command rules are text heuristics, not a sandbox.
- **Proving it is live:** trigger one refusal and read the message. Injection
  working says nothing about interception — they are separate capabilities from
  the same plugin row.

## Model routing (delegation)

- Setting: `<DSH_HOME>\settings.yaml` →
  `subagent-model-selection { enabled, allowedModels: [{provider, model}] }`.
- Read at **session creation**, recorded as the session's model-selection
  policy, inherited by children. Editing it afterwards does **not** change a
  running or restored session — open a new session.
- When enabled, `subagent` / `subagent_fork` expose `provider` / `model` /
  `reasoning_effort` and `list_subagent_models` appears. When off, those fields
  do not exist — **never fabricate them**; work inline or accept the inherited
  route.
- `subagent_fork` deliberately takes the parent route (KV-cache reuse) — do not
  expect it to switch models.
- The routing field takes the configured model **id**, not the display name.
- Providers and model lists live in the same settings file
  (`llm-pi-ai.providers.<id>.models`).

## Boundary keys for this host

The host interview's answer sheet ships with the rules repository as
`boundary/hosts/dsh.md` (install shape, the six host facts, key rows).
