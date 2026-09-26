# Host binding — ZCode on Windows

What ZCode reads, what (does not) enforce the boundary, and the host facts the
interview must record. Enforcement on this host is **prompt-level only** — no
adapter row exists — so the skill's §0.2 gate and the values the model resolves
from the skill root are the whole guard. The measured host layout ships with
the rule text as
[`reference/hosts/zcode.md`](../../skill/kalcirite-project-rules/reference/hosts/zcode.md).

Install shape (two skills, one skill root):

```
<userprofile>\.zcode\
└─ skills\
   ├─ kalcirite-project-rules\               <- clean install (empty local profile)
   └─ kalcirite-project-boundary\
      ├─ SKILL.md
      └─ PROJECT-BOUNDARY.md                 <- §0.1 step 2
```

The skill frontmatter is read the same way as on DSH (`name` / `description` /
`metadata`). The desktop agent's providers and model lists live in
`<userprofile>\.zcode\v2\provider_config.json` (`providerConfigRules` +
`modelConfigRules`); the CLI keeps its own config and marketplace plugin
registry under `<userprofile>\.zcode\cli\`.

The six host facts, answered for ZCode:

| Fact | ZCode |
|---|---|
| delegation tools | none observed in the measured install → `DELEGATION_TOOLS = none` (re-probe on upgrade) |
| can a delegation pick a model | n/a — `ROUTE_SELECTION_SUPPORTED = none`; work inline or accept the inherited route, never fabricate `provider` / `model` fields |
| route discovery | `<userprofile>\.zcode\v2\provider_config.json` — `personalModelIds` / `modelOrder` per provider |
| enabling route selection | the model choice is the provider config (model order), not a delegation setting → `ROUTE_ENABLE_SETTING = v2\provider_config.json (modelOrder)` |
| when it takes effect | unverified — assume new session / restart and confirm before claiming |
| concurrency or budget ceiling | none observed → `CONCURRENCY_LIMIT = none` |

A ZCode boundary carries the same key set as a DSH boundary; the rows that
differ are `HOST_AGENT = ZCode`, `DELEGATION_TOOLS = none`,
`ROUTE_SELECTION_SUPPORTED = none`, and the ROUTE rows above. See
[`../MACHINE-CONFIG.template.md`](../MACHINE-CONFIG.template.md) for the full
template and [`../QUESTIONS.md`](../QUESTIONS.md) for why the facts are
recorded at all.
