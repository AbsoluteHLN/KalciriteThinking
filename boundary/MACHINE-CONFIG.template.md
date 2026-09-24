# 本机配置（模板）

> **一台机器的全部专有事实，只写在这一份文档里。** 它属于操作者，不属于这个仓库：建议放在仓库外（例如 `E:\KalciriteThinking-local\MACHINE-CONFIG.zh.md`），或用本仓库 `.gitignore` 排除。
> 通用层（规则正文、模板、脚本、示例）不含任何本机路径，可以直接给别人。
>
> 工具读的那一份是 `PROJECT-BOUNDARY.md`，由 [`../scripts/export-boundary.ps1`](../scripts/export-boundary.ps1) 从**下面这些键值表**导出。
> **改值只改这里，然后重新导出**；`PROJECT-BOUNDARY.md` 是派生物，手改会在下次导出时丢掉。

**取值的规则**：三列表格里第二格是**值本身**，第三格只是给人看的说明，不会被导出。所以值里不要写说明，说明里不要写成值。
键名必须是一个反引号包住的**全大写 + 下划线**名字（`^[A-Z][A-Z0-9_]*$`），否则导出时会被当成普通文字跳过。
拿不准的行**留空**：空值让规则**停下来报告**，而不是去猜——**填错比留空更糟**。

## 0. 生效链

```powershell
# 1. 拷走本模板，改下面 §1 - §8 的键值表
Copy-Item .\boundary\MACHINE-CONFIG.template.md ..\MACHINE-CONFIG.zh.md

# 2. 导出工具读的边界文件
& .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.zh.md -Out ..\PROJECT-BOUNDARY.md

# 3. 安装（第一次，或改过值之后）
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md

# 4. 平时只更新规则正文（保留已装好的本机值）
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

- 第 3 步把边界文件**原样**写进技能目录，并在已装 `SKILL.md` 里填 `kalcirite:local-profile` 块。安装脚本不生成任何值：**导出脚本是唯一的边界文件生成者**。
- 装了宿主适配器时，适配器读的正是技能目录里那一份；改完重新导出并同步即可，不必改规则正文。
- 不用 Windows 时，第 2 步可以用任何工具复现：**文档里 `| \`KEY\` | 值 |` 的行 + 一个 `kalcirite:answers` JSON 块**就是边界文件的全部内容。

## 1. 宿主与 agent 环境

| 键 | 值 | 说明 |
|---|---|---|
| `HOST_AGENT` | `<名称与版本>` | 宿主 agent / harness |
| `HOST_PROFILE` | `<profile 名>` | 宿主当前 profile，留空表示不适用 |
| `DSH_HOME` | `<agent 配置根>` | 读取边界文件顺序里的第 3 档 |
| `SKILL_ROOT` | `<技能安装根>` | 安装脚本的 `-Target` |
| `NODE_RUNTIME` | `<可执行文件路径>` | 跑校验脚本用，避免依赖系统 node |
| `ADAPTER_PATH` | `<适配器包目录>` | 宿主适配器；没有就留空 |

## 2. 唯一依赖缓存

| 键 | 值 | 说明 |
|---|---|---|
| `DEP_CACHE` | `<DEP_CACHE>` | 机器上唯一的依赖缓存根；**留空则完全禁止任何依赖操作** |
| `DEP_CACHE_INDEX` | `<DEP_CACHE>\INDEX.md` | 目录清单与归属记录 |
| `PNPM_STORE` | `<DEP_CACHE>\pnpm-store` | 在 workspace 配置里钉住（`storeDir` / `virtualStoreDir`） |
| `NPM_CACHE` | `<DEP_CACHE>\npm-cache` | 环境变量 `npm_config_cache` |
| `PIP_CACHE` | `<DEP_CACHE>\pip-cache` | 环境变量 `PIP_CACHE_DIR` |
| `CARGO_HOME` | `<DEP_CACHE>\cargo` | 环境变量；离线 cargo 构建 |
| `ELECTRON_CACHE` | `<DEP_CACHE>\electron\Cache` | 环境变量 |
| `ELECTRON_BUILDER_CACHE` | `<DEP_CACHE>\electron-builder\Cache` | 环境变量 |
| `CACHE_READONLY` | `archive\ legacy-stores\ quarantine\` | 缓存内只读区，永不清理 |

## 3. 唯一 UI 上游

| 键 | 值 | 说明 |
|---|---|---|
| `UI_SOURCE` | `<UI_SOURCE>` 或 `none` | 设计系统 / 组件引擎的源仓库 |
| `UI_PREVIEW` | `<UI_PREVIEW>` 或留空 | 可选：预览工作台 |
| `UI_VERSION` | `<默认版本>` | 先读该版本的 `README.md` + `contract.md` |
| `UI_STYLING_RULE` | `布局在项目 CSS；配色 / 状态 / 动效走 token 与 variant` | 禁止自造颜色常量 |

`UI_SOURCE = none` 时降级为：**一个项目一个 UI 源，且样式必须 token 化**；不允许在一个项目里另起第二套设计语言。

## 4. 共享工具 / 插件库

| 键 | 值 | 说明 |
|---|---|---|
| `TOOL_HOME` | `<TOOL_HOME>` 或 `none` | 先复用；确实没有也在库内新建 |
| `TOOL_INDEX` | `<TOOL_HOME>\INDEX.md` | 导航 |
| `TOOL_REGISTRY` | `<TOOL_HOME>\registry.json` | 条目路径、状态、校验入口 |
| `TOOL_VALIDATOR` | `<完整命令行>` | 任何库改动后都要跑 |
| `TOOL_EXEC_AUTH` | `<授权模型>` 或留空 | 会执行或构造沙箱的条目归谁授权 |

`TOOL_HOME = none` 时降级为：先查项目自身 `tools/`，再决定是否新建，仍在既有目录边界内。

## 5. 项目目录契约

| 键 | 值 | 说明 |
|---|---|---|
| `BUILD_ROOT` | `cxbuild/` | 唯一构建产物根：桌面/Web/App、安装包、绿色版目录、一键启动脚本 |
| `TMP` | `temp/` | 唯一临时根 |
| `EVIDENCE` | `verify-evidence/` | 构建/测试输出、报告、截图 |
| `DOCS` | `docs/` | 面向读者 |
| `DEV_DOCS` | `dev-docs/` | 设计、决策、接口、迁移说明 |
| `SRC` | `src/` | 核心代码 |
| `EXTRA_TOP_LEVEL` |  | 额外放行的顶层名，逗号或空格分隔；留空＝不放行任何额外名字 |

顶层白名单由**适配器**决定（内置表 + 上面这些段名 + `EXTRA_TOP_LEVEL` + 适配器自身配置），不是由边界文件决定。只有**新建**顶层条目才判违规，已存在的目录不受影响。

## 6. 模型路由与子代理选用

| 键 | 值 | 说明 |
|---|---|---|
| `ROUTE_PROVIDER` | `<provider-id>` 或 `none` | 绝不越出这个提供方 |
| `CHEAP_MODELS` | `<ID1>, <ID2>, …` | **配置里的 id**，不是界面显示名 |
| `ROUTE_TOOL` | `<路由发现工具>` | 先发现再命名，不猜 |
| `DELEGATION_TOOLS` | `<工具1>, <工具2>` 或 `none` | 语义差别：新上下文 / 继承父对话 |
| `ROUTE_SELECTION_SUPPORTED` | `yes` / `none` | 委派时能否指定 provider + model |
| `ROUTE_ENABLE_SETTING` | `<设置项位置>` 或 `none` | 开哪个开关才能选模型 |
| `ROUTE_TAKES_EFFECT` | `new session` / `restart` / `immediate` | 改动何时生效 |
| `CONCURRENCY_LIMIT` | `<N>` 或留空 | 并发 / 预算上限；留空＝不作上限假设 |

> 没有写 `ROUTE_SELECTION_SUPPORTED = yes`，就按**不支持**处理：沿用父路由，不许伪造 `provider` / `model` 字段。
> 宿主相关细节与 DSH 的实测答案见 [`hosts/dsh.md`](hosts/dsh.md)，通用记法与六问见
> [`../skill/kalcirite-project-rules/reference/delegation.md`](../skill/kalcirite-project-rules/reference/delegation.md)。

## 7. 本机环境

| 键 | 值 | 说明 |
|---|---|---|
| `SHELL_NOTE` | `<会改变命令写法的约束>` | PowerShell 版本、是否有 `pwsh`、bash 可用性 |
| `TOOLCHAIN` | `<最低版本>` | 用前实测 |
| `PROXY` | `<代理地址>` 或留空 | 只是提示；直连会被重置的域名才走代理 |
| `NET_DIRECT` | `<可直连域名>` | 可留空 |
| `NET_RESET` | `<常被重置的域名>` | 可留空 |
| `PORTS` | `<端口清单>` | 项目专有，绝不可猜 |
| `PACKAGING` | `<打包方式>` | 可留空 |
| `NEVER_DELETE` | `<路径与数据的清单>` | 只备份，不重写 |

## 8. 项目专有例外

只对相应仓库生效的例外，写在这里而不是写进规则正文或规则文件。

| 键 | 值 | 说明 |
|---|---|---|
| `<PROJECT>_<TOPIC>` | `<本仓库专有的约束>` | 键名同样要全大写；一段只写一个主题 |
| `<PROJECT>_BUILD_LEGACY` | `<旧输出路径>` | 仅为兼容既有发布流程保留，新任务一律走 `BUILD_ROOT` |

### 8.1 项目指针清单（每个仓库一行，可选）

| 项目路径 | 包管理器 | 指针机制 | 备注 |
|---|---|---|---|
| `<PROJECTS_ROOT>\<name>` | pnpm workspace | workspace `storeDir` + `virtualStoreDir`；`node_modules` junction | |
| `<PROJECTS_ROOT>\<name>` | npm + Rust | `npm_config_cache` + `CARGO_HOME` | |

---

*机器拓扑变化时更新本文件；规则正文不应该跟着改。*
*本文件的英文版说明见 [`../README.en.md`](../README.en.md)。*
