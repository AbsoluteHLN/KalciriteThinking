# PROJECT-BOUNDARY — 机器边界文件（模板）

> 规则正文 [`../skills/kalcirite-project-rules/SKILL.md`](../skills/kalcirite-project-rules/SKILL.md) 与环境无关；
> 本文件是**唯一**存放机器相关事实的地方。
>
> **放到哪里**（规则正文 §0.1 按此顺序查找，取第一个命中）：
>
> 1. `<项目根>/PROJECT-BOUNDARY.md` —— 项目级覆盖，优先级最高
> 2. `<skill 目录>/PROJECT-BOUNDARY.md` —— 与 `SKILL.md` 同目录（安装向导写在这里）
> 3. `<agent 配置根>/PROJECT-BOUNDARY.md` —— 如 `$DSH_HOME\PROJECT-BOUNDARY.md`、`~/.claude/PROJECT-BOUNDARY.md`
>
> **怎么填**：跑 `scripts/install-skill.ps1`（逐项提问并写回），或让 agent 按规则正文 §0.2 访谈你。
>
> 不适用的行**删掉**。留下 `<PLACEHOLDER>` 会让规则**停下来报告**，而不是去猜——**填错比留空更糟**。

---

## 1. 唯一依赖缓存

| 键 | 值 | 说明 |
|---|---|---|
| `DEP_CACHE` | `<DEP_CACHE>` | 机器上唯一的依赖缓存根 |
| `DEP_CACHE_INDEX` | `<DEP_CACHE>\INDEX.md` | 目录清单与归属记录 |
| `pnpm store` | `<DEP_CACHE>\pnpm-store` | 在 workspace 配置里钉住（`storeDir` / `virtualStoreDir`） |
| `npm cache` | `<DEP_CACHE>\npm-cache` | 环境变量 `npm_config_cache` |
| `pip cache` | `<DEP_CACHE>\pip-cache` | 环境变量 `PIP_CACHE_DIR` |
| `CARGO_HOME` | `<DEP_CACHE>\cargo` | 环境变量；离线 cargo 构建 |
| `ELECTRON_CACHE` | `<DEP_CACHE>\electron\Cache` | 环境变量 |
| `ELECTRON_BUILDER_CACHE` | `<DEP_CACHE>\electron-builder\Cache` | 环境变量 |

缓存内**只读**区域：`archive\`、`legacy-stores\`、`quarantine\`。

---

## 2. 唯一 UI 上游

| 键 | 值 | 说明 |
|---|---|---|
| `UI_SOURCE` | `<UI_SOURCE>` 或 `none` | 设计系统 / 组件引擎的源仓库 |
| `UI_PREVIEW` | `<UI_PREVIEW>` 或空 | 可选：预览工作台 |
| `UI_DEFAULT_VERSION` | `<UI_VERSION>` | 先读该版本的 `README.md` + `contract.md` |
| `UI_STYLING_RULE` | 项目样式表只做布局；配色/状态/动效走 token 与 variant | 禁止自造颜色常量 |

`UI_SOURCE = none` 时 §4 降级为：**一个项目一个 UI 源，且样式必须 token 化**；不允许在一个项目里另起第二套设计语言。

---

## 3. 共享工具 / 插件库

| 键 | 值 | 说明 |
|---|---|---|
| `TOOL_HOME` | `<TOOL_HOME>` 或 `none` | 先复用；确实没有也在库内新建 |
| `TOOL_INDEX` | `<TOOL_HOME>\INDEX.md` | 导航 |
| `TOOL_REGISTRY` | `<TOOL_HOME>\registry.json` | 模块路径、授权、校验入口 |
| `TOOL_VALIDATOR` | `<TOOL_VALIDATOR>` | 任何库改动后都要跑 |

`TOOL_HOME = none` 时 §5 降级为：先查项目自身 `tools/`，再决定是否新建，仍在既有目录边界内。

---

## 4. 项目目录

| 键 | 值 |
|---|---|
| `BUILD_ROOT` | `<BUILD_ROOT>` —— 一切构建产物：桌面/Web/App、安装包、绿色版目录、一键启动脚本 |
| `TMP` | `<TMP>` —— 所有临时文件 |
| `EVIDENCE` | `<EVIDENCE>` —— 构建/测试输出、报告、截图 |
| `DOCS` | `<DOCS>` —— 面向读者 |
| `DEV_DOCS` | `<DEV_DOCS>` —— 设计、决策、接口、迁移说明 |
| `SRC` | `src/` —— 核心代码 |

---

## 5. 成本分级模型路由

| 键 | 值 | 说明 |
|---|---|---|
| `ROUTE_PROVIDER` | `<PROVIDER>` 或 `none` | 绝不越出这个提供方 |
| `CHEAP_MODELS` | `<ID1>, <ID2>, …` | **配置里的 id**，不是界面显示名 |
| `ROUTE_TOOL` | `<ROUTE_TOOL>` | 路由发现工具（DSH：`list_subagent_models`） |
| 强模型路由 | 父会话 / agent 默认 | 设计、取舍、安全、终裁 |

### 5.1 子代理与模型选用（宿主相关，必须单独问清）

"能不能选模型、在哪个开关里开、改动何时生效"由**宿主 agent** 决定，通用规则定不了。完整说明见 [`DELEGATION.md`](DELEGATION.md)。

| 键 | 值 | 说明 |
|---|---|---|
| `HOST_AGENT` | `<HOST_AGENT>` | 宿主 agent / harness 与版本 |
| `DELEGATION_TOOLS` | `<TOOL1>, <TOOL2>, …` 或 `none` | 有哪些委派工具，语义差别（新上下文 / 继承父对话） |
| `ROUTE_SELECTION_SUPPORTED` | `yes` / `none` | 委派时能否指定 provider + model |
| `ROUTE_ENABLE_SETTING` | `<SETTING_PATH>` 或 `none` | 开启路由选择的设置项位置 |
| `ROUTE_TAKES_EFFECT` | `<新会话 / 重启 / 立即>` | 改动何时生效 |
| `CONCURRENCY_LIMIT` | `<N>` 或 `none` | 并发 / 预算上限 |

> 没有写 `ROUTE_SELECTION_SUPPORTED = yes`，就按**不支持**处理：沿用父路由，不许伪造 `provider` / `model` 字段。

---

## 6. 项目指针清单（每个仓库填一行）

| 项目路径 | 包管理器 | 指针机制 | 备注 |
|---|---|---|---|
| `<PROJECTS_ROOT>\<name>` | pnpm workspace | workspace `storeDir` + `virtualStoreDir`；`node_modules` junction | |
| `<PROJECTS_ROOT>\<name>` | npm + Rust | `npm_config_cache` + `CARGO_HOME` | |
| | | | |

---

## 7. 本机环境事实（用前实测）

| 键 | 值 | 说明 |
|---|---|---|
| `SHELL_NOTE` | `<SHELL_NOTE>` | 会改变命令写法的约束（PowerShell 版本、是否有 `pwsh`、bash 可用性） |
| 系统代理 | `<PROXY>` 或空 | 直连会被重置的域名才走代理 |
| 固定端口 | `<PORTS>` | 项目专有，绝不可猜 |
| 工具链 | `<TOOLCHAIN>` | |
| 用户数据（永不删除） | `<NEVER_DELETE>` | 只备份，不重写 |

---

*机器拓扑变化时更新本文件；规则正文不应该跟着改。*
