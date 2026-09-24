# Host binding — DSH (DeepSeek Harness) on Windows

What DSH reads, what enforces the boundary, and how to prove enforcement is live.
Implements [`CONTRACT.md`](CONTRACT.md); the reference adapter lives in the shared
tool catalogue as `agent-adapters/dsh-kalcirite-boundary`.

Install shape produced by `scripts/install-skill.ps1`:

```
<DSH_HOME>\
├─ settings.yaml
└─ skills\
   └─ kalcirite-project-rules\
      ├─ SKILL.md                            <- carries the filled local-profile block
      ├─ PROJECT-BOUNDARY.md                 <- resolves per skill §0.1, 2nd place
      └─ reference\                          <- procedures, read on demand
```

The installer copies the rule text, copies the exported boundary file **verbatim**,
and fills the local-profile block. It never generates boundary values.

## The adapter

`dsh-kalcirite-boundary` is a host plugin row that contributes two things and a gate:

| Capability | How | Observable as |
|---|---|---|
| Injection | a prompt-context section appended right after the sub-agent delegation section | a `<kalcirite-boundary>` block in the session context |
| Interception | a tool guard on write / edit / shell tools | a refusal naming the rule and the key it consulted |
| Gate | `requireConfigured` (default on) | any write or install command refused until the boundary resolves |

Resolution follows the skill's §0.1 order and reads the `kalcirite:answers` JSON
block first, falling back to the markdown rows (and skipping `_(`-style blank
cells). The resolved file is cached for seconds, keyed on the working directory, so
an edit to the boundary takes effect without a session restart.

Modes, from the adapter's `cordis.patch.yml`:

| Mode | Writes | Commands |
|---|---|---|
| `off` | injection only | injection only |
| `warn` (default) | first offending write denied once per path; retry proceeds | same, per command |
| `enforce` | hard deny | hard deny for blocking rules; still deny-once for warnings |

Command rules are text heuristics, not a sandbox — they match one command string
and can be worked around by writing differently. Writes are the authoritative half.

**Proving it is live:** trigger one refusal and read the message. Injection working
says nothing about interception: they are separate capabilities installed by the
same plugin row, and a plugin that fails to load produces neither. Host plugin code
is not hot-reloaded — after editing the adapter, restart the DSH process before
believing a change took effect.

## settings.yaml — enabling cost-tiered delegation routing

DSH exposes `provider` / `model` / `reasoning_effort` on the delegation tools only when the
session was composed with this preference. It is read at **session creation** and inherited by
children; editing it does not change a running or restored session — open a new session.

```yaml
subagent-model-selection:
  enabled: true
  allowedModels:
    - { provider: csu, model: GLM }
    - { provider: csu, model: DeepSeek }
    - { provider: csu, model: Qwen }
```

Validation is strict: routes must be non-empty and unique, and `enabled: true` with an empty
`allowedModels` list is an error. `list_subagent_models` appears only once this is active.
`subagent_fork` still keeps the parent's route (KV-cache reuse) — it never takes a model.

The provider's model list lives in the same settings file under the adapter section, for example:

```yaml
llm-pi-ai:
  providers:
    csu:
      displayName: csu
      api: openai-completions
      baseURL: https://<gateway>/v1
      apiKeyEnv: CSU_API_KEY
      models:
        - id: GLM          # <- routing field uses this id
          name: csu/GLM-5.3-Flash   # <- display name, NOT the routing value
```

## Boundary values

| Key | Example |
|---|---|
| `DEP_CACHE` | `E:\dependency-cache` |
| `UI_SOURCE` | `E:\Projects\<ui-project>\ui-source` |
| `TOOL_HOME` | `E:\<tools-repo>` |
| `BUILD_ROOT` / `TMP` / `EVIDENCE` | `cxbuild/` / `temp/` / `verify-evidence/` |
| `ROUTE_PROVIDER` | `csu` |
| `ROUTE_TOOL` | `list_subagent_models` |
| `HOST_AGENT` | `DeepSeek Harness (DSH)` |
| `DELEGATION_TOOLS` | `subagent, subagent_fork` |
| `ROUTE_SELECTION_SUPPORTED` | `yes` (with the section above) |
| `ROUTE_ENABLE_SETTING` | `settings.yaml -> subagent-model-selection` |
| `ROUTE_TAKES_EFFECT` | `new session` |

See [`../MACHINE-CONFIG.template.md`](../MACHINE-CONFIG.template.md) for the hand-edited
source document these values come from, [`../QUESTIONS.md`](../QUESTIONS.md) for why they
must be recorded at all, and [`../DELEGATION.md`](../DELEGATION.md) for the sub-agent /
model-selection details that must be recorded on every host.
