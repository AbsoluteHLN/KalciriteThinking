# Host detail — ZCode

Read this when `HOST_AGENT` says ZCode. Measured on a Windows install
(2026-09-26); items the measurement could not reach are marked **unverified**.

## Layout

- Home: `~/.zcode/` (user profile directory).
- **Skill root:** `~/.zcode\skills\` — one directory per skill with a `SKILL.md`
  (same frontmatter shape as DSH: `name` / `description` / `metadata`;
  `whenToUse` optional).
- **Two-skill shape works here:** `kalcirite-project-rules` (clean install) with
  `kalcirite-project-boundary` beside it; its boundary file is the §0.1
  **step 2** candidate. A plain directory copy installs it, like on DSH.
- App state: `~/.zcode\v2\` — the desktop agent's `config.json`, `setting.json`
  (workspace, UI, bot behaviour), `provider_config.json` (models), credentials.
- CLI: `~/.zcode\cli\` — its own `config.json` and a plugin registry
  (`plugins\installed_plugins.json`, marketplace-sourced rows).
- Agent config root (step 4 fallback): `~/.zcode\PROJECT-BOUNDARY.md` —
  **unverified** as a location the host actually reads (there is no adapter;
  see enforcement).

## Model routing (delegation)

- Providers and model lists: `~/.zcode\v2\provider_config.json` —
  `providerConfigRules` (per provider: api type, `baseUrl`,
  `personalModelIds` / `modelOrder`) plus `modelConfigRules` (per model:
  context window, image support, `reasoningLevel` values).
- Compare this machine's ZCode provider and model ids (`personalModelIds`)
  against the boundary's `ROUTE_PROVIDER` / `CHEAP_MODELS`: when they match, the
  routing values transfer to ZCode unchanged; when they do not, re-interview
  the routing keys for this host.
- Delegation tools with a per-call model choice: **not observed** in this
  install. Record `DELEGATION_TOOLS = none`, `ROUTE_SELECTION_SUPPORTED = none`,
  and degrade per §2 — work inline or accept the inherited route; never
  fabricate `provider` / `model` fields.
- Bot integrations (`~/.zcode\v2\bot-config.json`) can pin a model per bot via
  their `model` command.
- Effect timing of a provider-config edit: **unverified** — assume
  new-session/restart and confirm before claiming it.

## Enforcement

- **No boundary adapter exists for ZCode.** The CLI plugin registry carries
  marketplace rows only (no kalcirite row), so there is no tool-layer guard and
  no refusal message to trigger. Enforcement is **prompt-level only**: the
  §0.2 gate plus the boundary values the model resolves from the skill root.
- "Proving it is live" here means: the boundary file resolves (step 2) and the
  model quotes its values (store path, build root) before acting — not
  triggering a refusal.
- ZCode's own permission prompts for sensitive commands are a separate
  mechanism and do not know this layout.

## Boundary keys for this host

The host interview's answer sheet ships with the rules repository as
`boundary/hosts/zcode.md` (install shape, the six host facts, key rows).
