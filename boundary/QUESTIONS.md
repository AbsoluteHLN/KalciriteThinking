# 入职问卷（索引）

安装这个技能时，规则正文需要一个**只属于这台机器**的边界文件。采集它的问题清单只有一份，在技能里：

> **[`../skill/kalcirite-project-rules/reference/interview.md`](../skill/kalcirite-project-rules/reference/interview.md)**

agent 侧的执行规则（什么时候问、一次问完、写回哪里、留空怎么处理）在
[`../skill/kalcirite-project-rules/SKILL.md`](../skill/kalcirite-project-rules/SKILL.md) §0.2。
本文件不重复那张表，只说明**为什么这些问题、为什么会话之外必须落盘**。

## 三道闸门

| 闸门 | 位置 | 作用 |
|---|---|---|
| 1. 问 | agent，一次问完 | 拿到本机事实 |
| 2. 记 | 操作者手写的机器配置文档，模板见 [`MACHINE-CONFIG.template.md`](MACHINE-CONFIG.template.md) | 人不丢、机器也能读 |
| 3. 导出并安装 | `scripts/export-boundary.ps1` → `scripts/install-skill.ps1` | 生成 agent 读的 `PROJECT-BOUNDARY.md` 并装进技能目录 |

**只有第 2 步是人写的。** 边界文件是派生物：手改会在下次导出时丢掉，安装脚本也不再自己造值。

## 为什么必须落盘

会话里的答案会随上下文消失，然后 agent 只能**猜路径**——这正是整套规则要消灭的东西。
所以规则正文 §0.2 把"边界未解析"设成硬闸门：**在答案落盘之前，任何编辑、构建、安装、删除都不允许开始**。
装的宿主适配器会在写入和命令上再拦一次，措辞相同。

## 哪个问题可以留空

留空不是偷懒，是一个**决定**：它让那部分规则停下来报告，而不是编一个值。

| 键 | 留空 / `none` 的后果 |
|---|---|
| `DEP_CACHE` | **必答**——任何依赖操作都无法开始 |
| `UI_SOURCE` | 降级为"一个项目一个 UI 源 + 样式 token 化" |
| `TOOL_HOME` | 降级为"先查项目自身 `tools/`" |
| `BUILD_ROOT` / `TMP` / `EVIDENCE` / `DOCS` / `DEV_DOCS` | 用文档里的默认值 |
| `ROUTE_PROVIDER` / `CHEAP_MODELS` / `ROUTE_TOOL` | 委派沿用父路由，报告里写明"模型选择不可用" |
| `DELEGATION_TOOLS` / `ROUTE_SELECTION_SUPPORTED` | 按**不支持**处理，不许伪造 `provider` / `model` 字段 |
| `SHELL_NOTE` | 不作假设；命令失败时再问 |
| `EXTRA_TOP_LEVEL` | 顶层白名单保持关闭 |
| `NEVER_DELETE` | 除规则正文红线外，不额外保护任何路径 |

## 环境变了要重问

缓存搬家、换 UI 上游、换模型提供方、换 shell、换仓库布局——**更新机器配置文档并重新导出**，
不要改规则正文。规则正文保持与环境无关；两次访谈之间只需要改这一份文档。

宿主相关的细节（委派工具、能否选模型、何时生效）见 [`DELEGATION.md`](DELEGATION.md)；
给新宿主写适配器的契约见 [`hosts/CONTRACT.md`](hosts/CONTRACT.md)。
