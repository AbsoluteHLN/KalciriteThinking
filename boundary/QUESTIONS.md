# 入职问卷（安装时提问什么）

安装这个技能时，规则正文需要一个**只属于这台机器**的边界文件。这份问卷就是采集它的问题清单。

两种执行方式，**同一套问题**：

| 方式 | 谁问 | 命令 / 动作 |
|---|---|---|
| 向导 | 脚本 | `& .\scripts\install-skill.ps1 -Target <skill 根>` |
| 访谈 | agent | 规则正文 §0.2：agent 发现边界未解析时先问再动手 |

答案写到 `PROJECT-BOUNDARY.md`（放置顺序见 [`PROJECT-BOUNDARY.template.md`](PROJECT-BOUNDARY.template.md)），并同步写回技能内的 `local-profile` 块。

## 提问原则

1. **一次问完**，不要挤牙膏；每题带一个**探测出来的**默认值，并标明它是"探测"还是"猜测"。
2. **能自己查到的不问人**：先用 `Test-Path`、`Get-Command`、配置文件读取去探测。
3. **留空是合法答案**。`none` / 空表示该域不做假设——规则会**停下来报告**，而不是编一个路径。
4. **写回前先验证**：每个路径落盘前做一次存在性检查；不存在的写成 `(unverified)` 并说明。
5. **环境变了要重问**：缓存搬家、换 UI 上游、换模型提供方——更新边界文件，不要改规则正文。

## 问题清单

| # | 键 | 问题 | 默认探测 | 留空 / `none` 的后果 |
|---|---|---|---|---|
| 1 | `DEP_CACHE` | 所有依赖统一装到哪个根目录？ | 工作盘 + `\dependency-cache`；`pnpm store path`、`npm config get cache` | **必答**——依赖相关的工作无法开始 |
| 2 | 缓存子布局 | 是否沿用 `<DEP_CACHE>\{pnpm-store, npm-cache, pip-cache, cargo, electron\Cache, electron-builder\Cache}`？ | 目录已存在的按存在，其余按约定 | 各自单独指定 |
| 3 | `UI_SOURCE` | 有没有统一的 UI 上游（设计系统 / 组件引擎）？在哪？ | 同级目录里的 `*UI*`、`ui-source` | 记 `none`；§4 降级为"一个项目一个 UI 源 + 样式 token 化" |
| 4 | `UI_VERSION` | 默认接哪个版本？ | 上游 `ui-source` 下最新稳定版目录 | 必须先读契约再选，不得默认取最新 |
| 5 | `UI_PREVIEW` | 有预览工作台吗？ | 上游同级目录 | 无预览，直接改产物 |
| 6 | `TOOL_HOME` | 共享工具 / 插件库在哪？ | 同级目录里的工具库仓库 | 记 `none`；§5 降级为"先查项目 `tools/`" |
| 7 | `TOOL_*` | 索引 / 注册表 / 校验入口的文件名？ | 探测 `INDEX.md`、`registry.json`、`**/validate-*.mjs` | 改库后无校验入口，需人工复核 |
| 8 | 目录名 | 构建产物根 / 临时根 / 证据根 / 文档根？ | `cxbuild/`、`temp/`、`verify-evidence/`、`docs/`、`dev-docs/` | 用默认值 |
| 9 | `ROUTE_PROVIDER` + `CHEAP_MODELS` | 授权提供方是谁？廉价模型的 **id**（不是显示名）有哪些？ | 读 agent 的模型配置 / settings | 记 `none`；转接只能沿用父路由（§2.3） |
| 10 | `ROUTE_TOOL` | 怎么发现可用路由？ | 工具目录（DSH：`list_subagent_models`） | 问用户；不许试探 |
| 11 | **子代理与模型选用**（宿主相关，详见 [`DELEGATION.md`](DELEGATION.md)） | 宿主 agent 是什么？有哪些委派工具、语义差别？委派**能不能**指定 provider/model？开哪个设置、**何时生效**？有无并发上限？ | 宿主的工具清单与配置文件 | 全部记 `none`：按"不支持选模型"处理，沿用父路由并在报告里说明 |
| 12 | `SHELL_NOTE` | 命令语法受什么约束？ | `$PSVersionTable`、`Get-Command pwsh`、`bash` 可用性 | 命令写法按探测结果 |
| 13 | `PROXY` / 端口 / 用户数据 | 代理地址？固定端口？哪些路径永不删除？ | 项目文档、配置文件、注册表 | 记已确认的部分，其余标未验证 |

## 写回到哪里

1. 优先写**项目级** `<项目根>/PROJECT-BOUNDARY.md`（只对该仓库生效）；
2. 机器级写 `<skill 目录>/PROJECT-BOUNDARY.md`（随技能走）；
3. 如能写入被加载的 `SKILL.md`，同时把结果填进 `kalcirite:local-profile` 标记块——这样 agent 即使读不到边界文件也有本机值。

写入格式由向导生成，末尾带一个机器可读的答案块（`kalcirite:answers`），便于以后 `install-skill.ps1 -FromBoundary` 直接读回复用。
