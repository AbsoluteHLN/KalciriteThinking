# Boundary example — DSH (DeepSeek Harness) on Windows

Install shape produced by `scripts/sync-skill.ps1`:

```
<DSH_HOME>\
├─ settings.yaml
└─ skills\
   ├─ PROJECT-BOUNDARY.md                    <- this file
   └─ kalcirite-project-rules\
      └─ SKILL.md                            <- resolves ./PROJECT-BOUNDARY.md, then the machine root
```

## settings.yaml — enabling cost-tiered delegation routing

DSH exposes `provider` / `model` / `reasoning_effort` on the delegation tool only when the
session was composed with this preference. It is read at **session creation** and inherited by
children; editing it does not change a running or restored session.

```yaml
subagent-model-selection:
  enabled: true
  allowedModels:
    - { provider: csu, model: GLM }
    - { provider: csu, model: DeepSeek }
    - { provider: csu, model: Qwen }
```

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
| Authorised provider | `csu` |
| Route discovery tool | `list_subagent_models` |

See [`../PROJECT-BOUNDARY.md`](../PROJECT-BOUNDARY.md) for the full template.