# Boundary example — DSH (DeepSeek Harness) on Windows

Install shape produced by `scripts/install-skill.ps1`:

```
<DSH_HOME>\
├─ settings.yaml
└─ skills\
   └─ kalcirite-project-rules\
      ├─ SKILL.md                            <- carries the filled local-profile block
      └─ PROJECT-BOUNDARY.md                 <- this file: resolves per §0.1, 2nd place
```

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

See [`../boundary/PROJECT-BOUNDARY.template.md`](../boundary/PROJECT-BOUNDARY.template.md) for the
blank template and [`../boundary/DELEGATION.md`](../boundary/DELEGATION.md) for the sub-agent /
model-selection details that must be recorded on every host.
