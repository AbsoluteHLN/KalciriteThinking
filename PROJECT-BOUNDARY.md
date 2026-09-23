# PROJECT-BOUNDARY — machine boundary file (template)

This file is the **only** place where machine-specific facts live. The rule text in `skills/kalcirite-project-rules/SKILL.md` stays portable and refers to it for concrete values.

Copy this file to one of:

- `<machine-config>/PROJECT-BOUNDARY.md` (agent-config root, shared by every project), or
- `<project>/PROJECT-BOUNDARY.md` (a project-local override, which wins over the machine file).

Delete every row that does not apply. **A wrong path here is worse than an empty one** — leave it blank and the rules will stop and report instead of guessing.

---

## 1. Single dependency cache

| Key | Value | Notes |
|---|---|---|
| `DEP_CACHE` | `E:\dependency-cache` | example; replace with your machine's cache root |
| `DEP_CACHE_INDEX` | `E:\dependency-cache\INDEX.md` | directory inventory + ownership record |
| `pnpm store` | `E:\dependency-cache\pnpm-store` | pin per workspace (`storeDir` / `virtualStoreDir`) |
| `npm cache` | `E:\dependency-cache\npm-cache` | env `npm_config_cache` |
| `pip cache` | `E:\dependency-cache\pip-cache` | env `PIP_CACHE_DIR` |
| `CARGO_HOME` | `E:\dependency-cache\cargo` | env var; offline cargo builds |
| `ELECTRON_CACHE` | `E:\dependency-cache\electron\Cache` | env var |
| `ELECTRON_BUILDER_CACHE` | `E:\dependency-cache\electron-builder\Cache` | env var |

Cache-internal areas that are **read-only**: `archive\`, `legacy-stores\`, `quarantine\`.

---

## 2. Canonical UI source

| Key | Value | Notes |
|---|---|---|
| `UI_SOURCE` | `E:\Projects\KalciriteUI\ui-source` | canonical engine + versioned releases |
| `UI_PREVIEW` | `E:\Projects\KalciriteUI\artist-Paralos-main` | live workbench, zero-pollution version switching |
| `UI_DEFAULT_VERSION` | `v2.5` | read that version's `README.md` + `contract.md` first |
| `UI_STYLING_RULE` | layout in project CSS; colour/state/motion from tokens & variants | no local colour constants |

---

## 3. Shared tool / plugin catalogue

| Key | Value | Notes |
|---|---|---|
| `TOOL_HOME` | `E:\KalciriteTools` | reuse first; build inside it if absent |
| `TOOL_INDEX` | `E:\KalciriteTools\INDEX.md` | navigation |
| `TOOL_REGISTRY` | `E:\KalciriteTools\registry.json` | module paths, authority, validation entries |
| `TOOL_VALIDATOR` | `E:\KalciriteTools\ops-tools\validate-kalcirite-registry.mjs` | run after any catalogue change |

---

## 4. Project layout

| Key | Value |
|---|---|
| `BUILD_ROOT` | `cxbuild/` — every build output, installer, unpacked bundle, launcher script |
| `TMP` | `temp/` — all scratch files |
| `EVIDENCE` | `verify-evidence/` — build/test output, reports, screenshots |
| `DOCS` | `docs/` — reader-facing |
| `DEV_DOCS` | `dev-docs/` — design, decisions, interfaces, migration notes |
| `SRC` | `src/` — core code |

---

## 5. Cost-tiered model routing

| Key | Value | Notes |
|---|---|---|
| Authorised provider | `csu` | never route outside this provider |
| Cheap model ids | `GLM`, `DeepSeek`, `Qwen` | **configured ids**, not UI display names |
| Route discovery | `list_subagent_models` | DSH; use the equivalent elsewhere |
| Enable delegation routing | settings section `subagent-model-selection` → `enabled: true`, `allowedModels: [{provider, model}, …]` | read at session creation; inherited by children |
| Strong route | parent/agent default | design, trade-offs, security, adjudication |

---

## 6. Project pointer inventory (fill per repository)

| Project path | Package manager | Pointer mechanism | Notes |
|---|---|---|---|
| `E:\Projects\<name>` | pnpm workspace | workspace `storeDir` + `virtualStoreDir`; `node_modules` junction | |
| `E:\Projects\<name>` | npm + Rust | `npm_config_cache` + `CARGO_HOME`; `src-tauri` snapshot in cache | |
| `E:\projectHLN\<name>` | pnpm workspace | `.pnpm-store` link; per-workspace link containers | |

---

## 7. Local environment facts (verify before use)

| Key | Value | Notes |
|---|---|---|
| System proxy | `127.0.0.1:7897` | fallback for hosts that reset TLS |
| Reliable hosts | `api.github.com` | direct works |
| Unreliable hosts | release-asset CDNs | use the proxy |
| Fixed ports | e.g. `14410` dev server, `14411` local REST | project-specific; never guess |
| Toolchain | Rust ≥ 1.85 · Node ≥ 18 + pnpm · Tauri CLI 2 | |
| User data (never delete) | `data\`, `%USERPROFILE%\.<app>` | back up, never rewrite |

---

*Update this file whenever the machine's topology changes. The rule text should not need to change with it.*
