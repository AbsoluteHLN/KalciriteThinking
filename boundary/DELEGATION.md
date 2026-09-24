# 子代理与模型选用（安装时必须问清的细节）

规则正文 §2 定的是**判断标准**：廉价模型读、强模型判断，先发现路由再命名，不越出授权提供方。完整流程在 [`../skill/kalcirite-project-rules/reference/delegation.md`](../skill/kalcirite-project-rules/reference/delegation.md)。

但"**能不能选模型、怎么选、在哪个开关里开、什么时候生效**"完全取决于宿主 agent——这是**宿主/机器相关**的事实，不能写死在通用规则里。安装到一台新机器时，这部分必须单独问清并写回边界文件，否则 agent 会以为"可以指定模型"，然后要么伪造字段，要么白烧一遍预算去试探。

## 必须问清的六件事

| # | 问题 | 写入键 | 为什么必须问 |
|---|---|---|---|
| 1 | 宿主 agent 是什么（名称/版本）？ | `HOST_AGENT` | 决定用哪套等价说法 |
| 2 | 有哪些委派 / 子代理工具？语义差别是什么？ | `DELEGATION_TOOLS` | 新上下文 vs 继承父对话，回传内容完全不同 |
| 3 | 委派时**能不能**指定 provider / model？ | `ROUTE_SELECTION_SUPPORTED` | 不能就是不能，不许伪造字段 |
| 4 | 用什么工具或命令**发现**可用路由？ | `ROUTE_TOOL` | 先发现，再命名；不猜 |
| 5 | 开哪个开关才能选模型？改动**何时生效**？ | `ROUTE_ENABLE_SETTING`、`ROUTE_TAKES_EFFECT` | 有的宿主是会话创建时读取，改完必须新开会话 |
| 6 | 有没有并发 / 预算上限？ | `CONCURRENCY_LIMIT` | 并行委派会撞上限，撞了就白等 |

## DSH（DeepSeek Harness）的答案

`settings.yaml`：

```yaml
subagent-model-selection:
  enabled: true
  allowedModels:
    - { provider: <provider-id>, model: <model-id> }
```

| 事实 | 说明 |
|---|---|
| 校验规则 | 路由必须是非空字符串且不重复；`enabled: true` 但 `allowedModels` 为空会直接抛错 |
| 生效时机 | **会话创建时**读取，记为会话事件 `subagent/model-selection-policy`，并被子代理继承；已恢复的会话沿用当时记录的策略——**事后改 settings 不影响运行中的会话** |
| 暴露了什么 | 开启后 `subagent` / `subagent_fork` 才带 `provider` / `model` / `reasoning_effort`，并多出一个 `list_subagent_models` |
| `subagent_fork` 例外 | 它刻意不提供模型选择，始终走父路由（为了复用父会话的 KV cache）——不要指望用它换模型 |
| 字段取值 | 路由字段要填**配置里的 id**，不是界面显示名（如显示 `csu/GLM-5.3-Flash`，配置 id 是 `GLM`） |
| 没开启时 | 委派工具不暴露这些字段：**不要伪造**，退回父路由或直接内联完成，并在报告里说明"模型选择不可用" |

配置片段见 [`hosts/dsh.md`](hosts/dsh.md)。

## 其他宿主怎么记录

| 情况 | 记法 |
|---|---|
| 有等价的模型路由设置 | 把设置位置写进 `ROUTE_ENABLE_SETTING`，把生效时机写进 `ROUTE_TAKES_EFFECT`（"新会话生效" / "立即生效" / "需要重启"） |
| 有委派但**不能**选模型 | `ROUTE_SELECTION_SUPPORTED = none`；规则降级为：要么父会话内联完成，要么接受子代理无法控制成本这一事实 |
| 完全没有委派能力 | `DELEGATION_TOOLS = none`；§2 的成本分级只用于"要不要开新会话"，不再谈模型选择 |
| 有并发上限 | 写进 `CONCURRENCY_LIMIT`；并行委派前先看它 |

无论哪种情况，**边界文件里没写"支持选模型"，就按不支持处理**。

## 写回哪里

1. 机器配置文档的 §6（模型路由与子代理选用）——完整键值；
2. 被加载的 `SKILL.md` 的 `kalcirite:local-profile` 块——至少写 `ROUTE_PROVIDER`、`CHEAP_MODELS`、`ROUTE_TOOL`、`ROUTE_SELECTION_SUPPORTED`。

agent 的首次访谈（[`../skill/kalcirite-project-rules/reference/interview.md`](../skill/kalcirite-project-rules/reference/interview.md) 第 6 问）会逐项问这些，答案写进机器配置文档，再由 `scripts/export-boundary.ps1` 导出成边界文件。
