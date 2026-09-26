# Host detail — Codex (OpenAI Codex, desktop / CLI)

Read this when `HOST_AGENT` says Codex. Measured on a Windows install
(2026-09-26); items the measurement could not reach are marked **unverified**.

## Layout

- Home: `~/.codex/` (child processes see it as `CODEX_HOME`).
- **Skill root:** `~/.codex\skills\` — one directory per skill with a
  `SKILL.md` (same frontmatter shape; third-party skills use the same format,
  and some entries are directory junctions).
- **Two-skill shape works here:** `kalcirite-project-rules` (clean install) with
  `kalcirite-project-boundary` beside it — both install here with a plain
  directory copy; the boundary file is the §0.1 **step 2** candidate.
- **Global instructions:** `~/.codex\AGENTS.md` (per-project:
  `<project>\AGENTS.md`). With no adapter to inject the boundary, this file is
  the standing pointer: one line naming the skill and the boundary file.
- Main config: `~/.codex\config.toml` (key map below).

## Key map — `config.toml`

| Key / section | Role for this skill |
|---|---|
| `model_provider` / `openai_base_url` / `model_catalog_json` | the active provider route; on many machines a model-switching companion (e.g. cc-switch) owns this route and the catalog beside it, and re-generates them on catalog refresh |
| `developer_instructions` | extra standing instructions — a candidate boundary-injection point |
| `sandbox_mode` + `[windows] sandbox` | Codex's **own** execution sandbox — separate from this layout's guard; it does not know the store or the layout |
| `[agents]` `max_concurrent_threads_per_session`, `max_depth` | the concurrency / depth ceilings a multi-agent fan-out must respect (`CONCURRENCY_LIMIT`) |
| `[features.multi_agent_v2]` | enables spawn-agent delegation; `tool_namespace` names the tool group |
| `[mcp_servers.*]` | MCP servers configured for the machine (a node REPL, a project's own server) — a tool side channel with no boundary awareness |
| `[projects.'<path>'] trust_level` | per-project trust; new projects start untrusted |

## Model routing (delegation)

- Multi-agent v2: delegation spawns **agents defined in
  `~/.codex\agents\*.toml`** — each toml pins `name`, `model`,
  `model_provider`, `model_context_window` (plus nickname candidates).
- Routing on Codex is therefore **agent selection, not a per-call model
  field**: the child's model is fixed in its toml. Changing a route means
  editing the toml — when a model-switching companion (e.g. cc-switch)
  maintains the tomls, they are re-generated on catalog refresh and
  hand-edits may be overwritten.
- Record: `DELEGATION_TOOLS = spawn agent (multi_agent_v2)`,
  `ROUTE_SELECTION_SUPPORTED = none` (no per-call choice),
  `ROUTE_ENABLE_SETTING = agents/*.toml (via cc-switch)`,
  `ROUTE_TAKES_EFFECT = next spawn (unverified)`.
- Never fabricate DSH-style `provider` / `model` fields on the spawn tool.

## Enforcement

- **No boundary adapter exists for Codex** (plugin rows are
  openai-bundled / openai-primary-runtime; no kalcirite row). Enforcement is
  **prompt-level only**: the `AGENTS.md` pointer plus the §0.2 gate.
- Codex's sandbox is about command safety, not about this layout: it will
  happily create a project-local `node_modules` if the model asks. The
  instruction text is the only guard, so keep the `AGENTS.md` pointer short
  and unmissable.
- "Proving it is live" = a fresh session that names the boundary's values
  (store path, build root) before acting. There is no guard message to
  trigger.

## Boundary keys for this host

The host interview's answer sheet ships with the rules repository as
`boundary/hosts/codex.md` (install shape, the six host facts, key rows).
