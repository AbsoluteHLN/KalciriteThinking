# 本机项目规则（KalciriteThinking 中文本地版）

> 本文件是 [`skills/kalcirite-project-rules/SKILL.md`](skills/kalcirite-project-rules/SKILL.md) 的中文同义版本，
> 并把本机边界值（`DEP_CACHE`、`UI_SOURCE`、`TOOL_HOME`、目录名、模型路由）就地写实。
>
> **给本机 agent 用**：把本文件与英文规则一起加载；两者冲突时以本文件为准（本机实测口径 > 通用文本）。
> 换机器时只改「§B 本机边界值」，规则正文不动。

---

## §A 十条纪律（中性表述）

1. **先构建，后一次验证**：一次改到完整 → 构建 → 集中一次验证；禁止边改边反复全量验证。
2. **按推理深度路由模型**：批量读取、机械重构、逐文件审计、文档成稿交给廉价模型；设计、取舍、安全、终裁留在强模型。先发现路由（`list_subagent_models`），不猜模型名，不越出授权提供方。
3. **唯一依赖缓存**：一切依赖装进 `E:\dependency-cache` 并链接使用；项目内不出现依赖实体；缓存只读，禁止 clean/删除链接。
4. **唯一 UI 上游**：接入 `E:\Projects\KalciriteUI`，先读目标版本 `README.md` + `contract.md`；项目样式表只管布局，配色/状态/动效全部走 token 与 variant。
5. **先复用后新建**：先查 `E:\KalciriteTools`；确实没有，也在该库内按既有边界新建，并统一接口、跑校验入口。
6. **干净目录**：`src/ docs/ dev-docs/ verify-evidence/ cxbuild/ temp/`，一个构建产物根、一个临时根、一个证据根。
7. **变动即归档**：被取代的文件进各自 `archive/`，或按删除前清单安全删除；主路径上只留当前真相。
8. **自包含转接**：绝对路径、明确可写范围、约定回传格式（摘要 + 改动清单 + 证据路径 + 未决项 + 未能验证项）。
9. **有证据才算结论**：已验证 / 已尝试 / 未尝试是三个不同的词；构建与验证输出落入 `verify-evidence/`。
10. **事实靠实测**：路径、端口、版本先 `Test-Path` / 实测再断言，不凭记忆。

## §B 本机边界值

| 键 | 本机值 |
|---|---|
| `DEP_CACHE` | `E:\dependency-cache`（索引 `INDEX.md`、规则 `DEPENDENCY-BOUNDARY.md`） |
| 包管理器指向 | `store-dir` / `virtualStoreDir` 钉在 workspace 配置；`node_modules` 为 junction；`CARGO_HOME`、`PIP_CACHE_DIR`、`npm_config_cache`、`ELECTRON_*` 指向缓存 |
| 缓存内只读区 | `archive\`、`legacy-stores\`、`quarantine\` |
| `UI_SOURCE` | `E:\Projects\KalciriteUI\ui-source`（预览工作台 `artist-Paralos-main`） |
| `UI_DEFAULT_VERSION` | 最新稳定版（当前 v2.5，其次 v2.3；v1 仅在需要柔和玻璃风格时用） |
| `TOOL_HOME` | `E:\KalciriteTools`（索引 `INDEX.md`、注册表 `registry.json`） |
| `TOOL_VALIDATOR` | `& 'E:\dependency-cache\node-runtime\node.exe' 'E:\KalciriteTools\ops-tools\validate-kalcirite-registry.mjs'` |
| `BUILD_ROOT` / `TMP` / `EVIDENCE` | `cxbuild/` / `temp/` / `verify-evidence/` |
| 授权模型提供方 | `csu`（模型 id：`GLM`、`DeepSeek`、`Qwen`；显示名与 id 不同，路由用 id） |
| 委派路由开关 | `settings.yaml` 的 `subagent-model-selection: {enabled: true, allowedModels: [...]}`，**会话创建时**读取并被子代理继承 |
| 本机 skill 根 | `D:\Cetus\dshconfig\skills`（即 `$env:DSH_HOME\skills`） |
| 本机 shell 说明 | PATH 上只有 Windows PowerShell 5.1（`pwsh` 不可用）：脚本用 `& .\scripts\xxx.ps1` 或 `powershell -File` 调用 |

## §C 项目专有事实（仅适用于对应仓库）

### Taskasion（`E:\Projects\Taskasion`）

| 项 | 值 |
|---|---|
| 固定端口 | `14410` Vite dev server（`strictPort`）、`14411` core REST（仅回环）——三处必须一致：`src/api.ts`、`tauri.conf.json` CSP、`main.rs` CORE_PORT |
| 用户数据（永不删改） | exe 同级 `data\`（`todo.md` / `goals.md` / `audit.jsonl`）；独立运行默认 `%USERPROFILE%\.taskasion`，可用 `TASKASION_DATA_DIR` 覆盖 |
| 运行中的 widget | 重建前 `taskkill //F //IM Taskasion.exe`，重建后 `Start-Process <exe>`（exe 被锁会 `os error 5`） |
| 构建产物路径例外 | 旧口径 `build\cargo-target\`、`build\Taskasion-<ver>-portable.zip`、`dist\`：**仅**为兼容既有发布流程保留；新任务一律走 `cxbuild\` |

### 本机网络

| 项 | 值 |
|---|---|
| 直连可用 | `api.github.com` |
| 常被 TLS 重置 | `objects.githubusercontent.com`、`release-assets.githubusercontent.com` → 用系统代理 |
| 系统代理 | `http://127.0.0.1:7897`（WinINET；Rust 侧从注册表读同一地址） |
| 打包纪律 | 发布 zip 一律 PowerShell `Compress-Archive`（Git Bash tar 中文名编码已坏） |

## §D 红线

- 在项目内安装依赖、联网拉依赖，或删除 `node_modules` / 执行 `cargo clean`。
- 把依赖实体复制或新建进任何项目目录。
- 为省钱把需要判断的工作交给廉价模型。
- 用会话并未开放的 `provider`/`model` 字段假装完成路由。
- 自造配色常量、另起一套设计语言。
- 凭记忆断言路径/端口/版本。
- 声称"已验证"却拿不出 `verify-evidence/` 里的输出。

## §E 同步到 agent

```powershell
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -BoundaryPath .\PROJECT-BOUNDARY.md
```

同步后本机 skill 根下的结构：

```
D:\Cetus\dshconfig\
├─ PROJECT-BOUNDARY.md            <- 机器级边界值（也在 skills 根下，供 skill 就近解析）
└─ skills\
   ├─ PROJECT-BOUNDARY.md         <- sync 脚本安装的就近副本
   └─ kalcirite-project-rules\
      └─ SKILL.md                 <- 先找 ./PROJECT-BOUNDARY.md，再找机器配置根
```
