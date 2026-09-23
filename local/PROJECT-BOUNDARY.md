# PROJECT-BOUNDARY — 本机边界文件

> **本机专用**。机器相关事实的唯一来源，规则正文 [`../skills/kalcirite-project-rules/SKILL.md`](../skills/kalcirite-project-rules/SKILL.md) 从它取值。
> 查找顺序（规则正文 §0.1）：`<项目根>` → `<skill 目录>` → `<agent 配置根>`。
> 值全部实测于本机；改环境就改这里，不要改规则正文。留空 = 该域不做假设，规则停下来报告。

## 1. 唯一依赖缓存

| 键 | 值 |
|---|---|
| `DEP_CACHE` | `E:\dependency-cache` |
| `DEP_CACHE_INDEX` | `E:\dependency-cache\INDEX.md` |
| `pnpm store` | `E:\dependency-cache\pnpm-store` |
| `npm cache` | `E:\dependency-cache\npm-cache` |
| `pip cache` | `E:\dependency-cache\pip-cache` |
| `CARGO_HOME` | `E:\dependency-cache\cargo` |
| `ELECTRON_CACHE` | `E:\dependency-cache\electron\Cache` |
| `ELECTRON_BUILDER_CACHE` | `E:\dependency-cache\electron-builder\Cache` |

缓存内只读区：`archive\`、`legacy-stores\`、`quarantine\`。

## 2. 唯一 UI 上游

| 键 | 值 |
|---|---|
| `UI_SOURCE` | `E:\Projects\KalciriteUI\ui-source` |
| `UI_PREVIEW` | `E:\Projects\KalciriteUI\artist-Paralos-main` |
| `UI_DEFAULT_VERSION` | `v2.5`（其次 `v2.3`；`v1` 仅在需要柔和玻璃风格时用） |
| `UI_STYLING_RULE` | 项目样式表只做布局；配色/状态/动效走 token 与 variant |

> `E:\projectHLN\ui-system` 已于本机不存在，不要再引用；UI 权威只有 `E:\Projects\KalciriteUI\ui-source`。

## 3. 共享工具 / 插件库

| 键 | 值 |
|---|---|
| `TOOL_HOME` | `E:\KalciriteTools` |
| `TOOL_INDEX` | `E:\KalciriteTools\INDEX.md` |
| `TOOL_REGISTRY` | `E:\KalciriteTools\registry.json` |
| `TOOL_VALIDATOR` | `& 'E:\dependency-cache\node-runtime\node.exe' 'E:\KalciriteTools\ops-tools\validate-kalcirite-registry.mjs'` |

库内执行授权：`toolrouterDirectExecution`、`toolrouterLifecycleImport`、`sandboxDirectConstruction` 均为 `deny-without-soul-runtime-execution-gate`，授权方 `soul-hln-runtime-capability-supervisor`。

## 4. 项目目录

| 键 | 值 |
|---|---|
| `BUILD_ROOT` | `cxbuild/` |
| `TMP` | `temp/` |
| `EVIDENCE` | `verify-evidence/` |
| `DOCS` | `docs/` |
| `DEV_DOCS` | `dev-docs/` |
| `SRC` | `src/` |

## 5. 成本分级模型路由

| 键 | 值 |
|---|---|
| `ROUTE_PROVIDER` | `csu` |
| `CHEAP_MODELS` | `GLM`、`DeepSeek`、`Qwen`（**配置 id**，不是显示名 `csu/GLM-5.3-Flash` 之类） |
| `ROUTE_TOOL` | `list_subagent_models` |
| 强模型路由 | 父会话 / agent 默认 |

### 5.1 子代理与模型选用（宿主相关）

| 键 | 本机值 |
|---|---|
| `HOST_AGENT` | DeepSeek Harness（DSH），Cordis 组合 |
| `DELEGATION_TOOLS` | `subagent`（新上下文）、`subagent_fork`（继承父对话，**固定走父路由**，不提供模型选择） |
| `ROUTE_SELECTION_SUPPORTED` | `none` —— **当前不支持**：`settings.yaml` 里没有 `subagent-model-selection` 段（2026-09 实测） |
| `ROUTE_ENABLE_SETTING` | `settings.yaml` → `subagent-model-selection: {enabled: true, allowedModels: [{provider: csu, model: <id>}, …]}`；`enabled: true` 而列表为空会直接报错 |
| `ROUTE_TAKES_EFFECT` | **新会话生效**：会话创建时读取并记为 `subagent/model-selection-policy`，子代理继承；已恢复的会话沿用当时记录的策略，事后改 settings 不影响运行中会话 |
| `CONCURRENCY_LIMIT` | 未配置 |

> 在补上该段并**新开会话**之前，委派工具不暴露 `provider`/`model`/`reasoning_effort`，也没有 `list_subagent_models`：**不得伪造字段**，退回父路由或内联完成，并在报告里说明"模型选择不可用"。
> 详见 [`../boundary/DELEGATION.md`](../boundary/DELEGATION.md)。

## 6. 本机环境事实

| 键 | 值 |
|---|---|
| `SHELL_NOTE` | PATH 上只有 Windows PowerShell 5.1（`pwsh` 不可用）：脚本用 `& .\xxx.ps1` 或 `powershell -File` 调用 |
| 系统代理 | `http://127.0.0.1:7897`（WinINET；Rust 侧读注册表同一地址） |
| 直连可用 | `api.github.com` |
| 常被 TLS 重置 | `objects.githubusercontent.com`、`release-assets.githubusercontent.com` → 走代理 |
| 固定端口 | Taskasion：`14410` Vite dev（`strictPort`）、`14411` core REST（仅回环） |
| 工具链 | Rust ≥ 1.85 · Node ≥ 18 + pnpm · Tauri CLI 2 |
| 用户数据（永不删除） | exe 同级 `data\`（`todo.md`/`goals.md`/`audit.jsonl`）；独立运行默认 `%USERPROFILE%\.taskasion`，可用 `TASKASION_DATA_DIR` 覆盖 |
| 打包纪律 | 发布 zip 一律 PowerShell `Compress-Archive`（Git Bash tar 中文名编码已坏） |
| 本机 skill 根 | `D:\Cetus\dshconfig\skills`（即 `$env:DSH_HOME\skills`） |

## 7. 采集答案（机器可读）

<!-- kalcirite:answers:begin -->
```json
{
  "DEP_CACHE": "E:\\dependency-cache",
  "DEP_CACHE_INDEX": "E:\\dependency-cache\\INDEX.md",
  "PNPM_STORE": "E:\\dependency-cache\\pnpm-store",
  "NPM_CACHE": "E:\\dependency-cache\\npm-cache",
  "PIP_CACHE": "E:\\dependency-cache\\pip-cache",
  "CARGO_HOME": "E:\\dependency-cache\\cargo",
  "ELECTRON_CACHE": "E:\\dependency-cache\\electron\\Cache",
  "ELECTRON_BUILDER_CACHE": "E:\\dependency-cache\\electron-builder\\Cache",
  "UI_SOURCE": "E:\\Projects\\KalciriteUI\\ui-source",
  "UI_PREVIEW": "E:\\Projects\\KalciriteUI\\artist-Paralos-main",
  "UI_VERSION": "v2.5",
  "TOOL_HOME": "E:\\KalciriteTools",
  "TOOL_INDEX": "E:\\KalciriteTools\\INDEX.md",
  "TOOL_REGISTRY": "E:\\KalciriteTools\\registry.json",
  "TOOL_VALIDATOR": "& 'E:\\dependency-cache\\node-runtime\\node.exe' 'E:\\KalciriteTools\\ops-tools\\validate-kalcirite-registry.mjs'",
  "BUILD_ROOT": "cxbuild/",
  "TMP": "temp/",
  "EVIDENCE": "verify-evidence/",
  "DOCS": "docs/",
  "DEV_DOCS": "dev-docs/",
  "ROUTE_PROVIDER": "csu",
  "CHEAP_MODELS": "GLM, DeepSeek, Qwen",
  "ROUTE_TOOL": "list_subagent_models",
  "HOST_AGENT": "DeepSeek Harness (DSH)",
  "DELEGATION_TOOLS": "subagent, subagent_fork",
  "ROUTE_SELECTION_SUPPORTED": "none",
  "ROUTE_ENABLE_SETTING": "settings.yaml -> subagent-model-selection {enabled, allowedModels}",
  "ROUTE_TAKES_EFFECT": "new session (read at session creation and inherited by children)",
  "CONCURRENCY_LIMIT": "",
  "SHELL_NOTE": "PowerShell 5.1 only (pwsh not on PATH): use & .\\xxx.ps1 or powershell -File",
  "PROXY": "http://127.0.0.1:7897",
  "PORTS": "14410 (Vite dev), 14411 (core REST)",
  "NEVER_DELETE": "data\\ next to the exe; %USERPROFILE%\\.taskasion; archive\\, legacy-stores\\, quarantine\\ inside DEP_CACHE",
  "GENERATED": "hand-maintained"
}
```
<!-- kalcirite:answers:end -->
