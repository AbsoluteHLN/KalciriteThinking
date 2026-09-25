# KalciriteThinking

**适用于「一台机器、多个仓库」的通用 agent 工程纪律。**

[English](README.en.md) · [规则正文](skill/kalcirite-project-rules/SKILL.md) · [本机配置模板](boundary/MACHINE-CONFIG.template.md) · [更新日志](CHANGELOG.md)

## 声明

我第一次实际去规范化这种技能，不确保适用于你的工作流，可以以此仅作参考！

## 三层结构

| 层 | 位置 | 内容 | 可否直接共享 |
|---|---|---|---|
| **通用层** | 本仓库 | 规则正文与其参考页、本机配置模板与提问清单、宿主适配器契约与绑定、脚本 | 可以。不含任何私有路径 |
| **本机配置文档** | 仓库外，单独一份 | 这台机器的全部专有事项：宿主与环境、依赖缓存、UI 上游、工具库、目录契约、模型路由、网络与端口 | **不要**。只作参考，不进别人的机器 |
| **机器可读边界文件** | 由本机配置文档导出 | 键值表 + `kalcirite:answers` JSON，供安装脚本与宿主适配器读取 | 同上 |

### 本机配置单独成文

机器相关的事实**不写进规则正文，也不散落在各处**，而是集中在一份文档里。这一份刻意放成本仓库的**兄弟目录**，例如 `<上级目录>\KalciriteThinking-private\MACHINE-CONFIG.zh.md`（本机层，另发布于一个**私有**仓库）：不在仓库树内（仓库 `.gitignore` 另外兜底排除 `local/` 与 `private/`），放进公开版本控制就等于把一台机器的路径、账号、端口发布出去。

- **一份文档，一个位置。** 路径、端口、缓存、模型路由这类事实只在该文档里出现一次；规则正文永远环境中性，按 §0.1 的顺序解析取值。
- **工具读的那份是派生物。** `export-boundary.ps1` 从文档的键值表生成 `PROJECT-BOUNDARY.md`：保留 `##` 分节、丢掉第三列说明、附上 `kalcirite:answers` JSON 块。安装脚本与宿主适配器都只读这一份，所以「人写的值」和「工具读的值」不会各说各话。
- **安装脚本不生成任何值。** 它只把导出的边界文件逐字节复制进去，再填 `local-profile` 块。谁想知道值是从哪来的，答案永远只有一处。
- **别人不需要这份文档。** 别人拿到的是空白模板 + 入职问卷（规则正文 §0.2，问题清单在 [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md)），由**他自己**回答，落进**他自己的**一份同结构文档。
- **换机器只改这一份。** 规则正文、模板、脚本、适配器都不用动。

本机层的文档是**一份已经填好的答案**，不是规则的一部分。

### 两个技能：通用版 + 边界版

本机层把导出的边界文件发布为一个独立技能 —— `kalcirite-project-boundary`（私有仓库，一台机器一个）：它**只含**这台机器对通用版的补充边界值，不含任何规则正文，与通用技能 `kalcirite-project-rules` 装进**同一个 skill 根目录**。于是：

- 技能目录里两个技能并排，通用版**干净安装**（不含本机数据，公开仓库永远干净）；
- 取值时按 §0.1 第 2 顺位从边界技能目录找到 `PROJECT-BOUNDARY.md`（第 3 顺位仍是「与 `SKILL.md` 同目录」，供单技能安装的老形状）；
- 没有边界技能也能用：单技能安装把边界文件放进通用技能目录，行为与从前一致。

## 仓库结构

| 路径 | 内容 |
|---|---|
| [`skill/kalcirite-project-rules/`](skill/kalcirite-project-rules/) | 规则正文 `SKILL.md`；细节拆到 `reference/`（入职问卷、委派与模型选用、依赖缓存、UI 与工具库、宿主适配器契约） |
| [`boundary/`](boundary/) | 通用层的边界资料：配置模板、提问清单、项目级示例 |
| [`boundary/hosts/`](boundary/hosts/) | 已落地的宿主绑定：[DSH](boundary/hosts/dsh.md)；宿主必须实现什么由规则正文的 `reference/host-adapters.md` 规定 |
| [`scripts/`](scripts/) | 导出器与安装/同步脚本，用法见 [`scripts/README.md`](scripts/README.md) |
| [`CHANGELOG.md`](CHANGELOG.md) | 规则正文的版本历史；`sync-skill.ps1` 会打印版本差 |

适配器代码本身不在这里，而在公共工具库的 `agent-adapters/dsh-kalcirite-boundary`（本机实例路径见本机配置文档）。

## 十条原则

1. **先构建，后一次验证**：改动做完整 → 构建 → 集中一次验证。
2. **按推理深度路由，而非按任务大小**：廉价模型读、强模型判断；先发现路由，不猜模型名，不越出授权提供方。
3. **唯一依赖库（全机一个大文件夹，使用与安装都只在这里）**：每个生态一套库（pnpm / cargo / npm / pip），全机共用；依赖的安装与使用只发生在共享库内——安装钉定指向库、取用一律链接进库；项目里、构建里、变体里都不允许各自一份依赖，依赖库顶层也不允许并列存放「某个软件用的依赖」。
4. **唯一 UI 上游**：接入并遵守其契约；项目样式表只管布局，不管配色。
5. **先复用后新建**：先查公共工具库；确实没有，也在库内按既有边界新建。
6. **干净目录**：`src/ docs/ dev-docs/ verify-evidence/ cxbuild/ temp/`，一个构建产物根、一个临时根。
7. **变动即归档**：被取代的文件进 archive 或按清单安全删除，不留主路径。
8. **自包含转接**：绝对路径、明确可写范围、约定回传格式。
9. **有证据才算结论**：已验证 / 已尝试 / 未尝试，是三个不同的词。
10. **事实靠实测**：路径、端口、版本先量后说。

## 安装：三步，只有第一步是手写

规则正文里没有任何硬编码路径，所以取值必须先落到一份文档上，再派生成工具读的文件。

```powershell
# 1. 把模板复制出仓库并填好（这份永远留在仓库外）
Copy-Item .\boundary\MACHINE-CONFIG.template.md ..\MACHINE-CONFIG.md

# 2. 导出工具读的边界文件
& .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.md -Out ..\PROJECT-BOUNDARY.md

# 3. 安装：复制规则正文 + 逐字节复制边界文件 + 填本机档案块
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
# 其他 agent：把 -Target 指向它的 skill 目录

# 只更新规则正文（保留本机答案）
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

安装脚本**没有交互模式**：交互这件事属于 agent，规则正文 §0.2 规定了它的入口和问法。若既没给 `-FromBoundary`、目标位置也没有现成的边界文件，脚本执行**干净安装**：只复制规则正文、`local-profile` 块留空 —— 这是两技能形状下的一等安装模式（边界值由 `kalcirite-project-boundary` 技能提供，§0.1 第 2 顺位解析）。

### 任意宿主都能装：Codex / Claude Code / DSH / 其他

规则正文本身**不绑定任何宿主**：没有宿主工具名、没有宿主路径、没有插件机制假设。任何支持开放 `SKILL.md` 技能格式的宿主，把 `skill/kalcirite-project-rules/` 目录拷进它的技能目录即可 —— 单技能形状再把 `PROJECT-BOUNDARY.md` 放在 `SKILL.md` 旁边，两技能形状把边界文件放进并排的 `kalcirite-project-boundary/` 技能目录：

| 宿主 | 项目级 | 全局 |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.codex/skills/` | `~/.codex/skills/` |
| DeepSeek Harness (DSH) | — | `<DSH_HOME>\skills\`（用上面的安装脚本） |

上面的两个 `.ps1` 只是「导出 + 安装」两步在 Windows 上的便利实现，**不是契约本身**。在非 Windows 宿主上，agent 用自己的文件工具即可完成同样的事：边界文件的完整形状（键值行 + `kalcirite:answers` JSON 块 + 放置位置）由 [`reference/interview.md`](skill/kalcirite-project-rules/reference/interview.md) 的 *The boundary file's shape* 一节定义，照着写就是一份合法的边界文件。宿主如果连技能机制都没有，把需要的章节并进 `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` 也可以（见文末「其他用法」）。新技能通常需要重启宿主进程才会被加载。

它填的 `MACHINE-CONFIG.md` 有八节：宿主与环境、依赖缓存、UI 上游、工具库、目录契约、模型路由、子代理与委派、项目专有例外。问题清单与写法见 [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md)，子代理/模型选用的细节见 [`reference/delegation.md`](skill/kalcirite-project-rules/reference/delegation.md)（通用记法）与 [`boundary/hosts/dsh.md`](boundary/hosts/dsh.md)（DSH 实测答案）。

答案的落点按 §0.1 解析：两技能形状下在边界技能目录的 `PROJECT-BOUNDARY.md`（第 2 顺位），单技能形状下在技能目录内（第 3 顺位）；已安装 `SKILL.md` 里的 `local-profile` 块是兜底（第 5 顺位），干净安装下留空。**留空是合法答案**，含义是「不作假设」—— 规则会停下来报告，而不是去猜。项目级例外再放一份 `<项目根>/PROJECT-BOUNDARY.md`，效力最高（第 1 顺位）。

`-Force` 之前，脚本会拒绝任何取值字面写成 `<...>` 的文档，也会直接拒掉空的 `DEP_CACHE`；手写的旧边界文件在没给 `-Force` 时不会被覆盖。

你手工维护的是**本机配置文档**；上面那份 `PROJECT-BOUNDARY.md` 是它的机器可读导出，由导出器生成，别手改。

脚本在 Windows PowerShell 5.1 与 PowerShell 7+ 均可运行，只复制和生成文件，不执行任何仓库逻辑。完整用法见 [`scripts/README.md`](scripts/README.md)，项目级示例见 [`boundary/examples/`](boundary/examples/)。

## 让规则真的生效：宿主适配器

技能是文档：读一次，之后随长会话与压缩衰减，而且没有任何东西对「放错位置的文件」做出反应。要让布局边界真正生效，必须在宿主侧补机制。

- **位置**：公共工具库里的 `agent-adapters/dsh-kalcirite-boundary`（本机实例路径见本机配置文档，不属于通用层）。
- **注入**：把解析出的边界值与布局契约加入每次 prompt 组装，事实不再随技能文档衰减。
- **拦截**：对 `write` / `edit` 与 shell 命令按规则作出反应 —— 白名单之外的**新**顶层条目、项目内依赖载荷、构建根之外的构建产物、边界未配置时直接挡下。默认每个路径只拒绝一次并说明理由，原样重试即放行。
- **只拦截尚不存在的路径**，接管遗留项目不会误伤。
- **没配置就不放行**：边界文件缺失或 `DEP_CACHE` 为空时，写入与安装类命令会被硬挡，直到按 §0.2 回答完问卷。

**分工**：技能正文给规则与解析顺序（跨 agent 通用），适配器负责注入与拦截（宿主专有）。这份分工是一份可实现的契约，随规则正文一起发布，见 [`reference/host-adapters.md`](skill/kalcirite-project-rules/reference/host-adapters.md)；本机已落地的绑定见 [`boundary/hosts/dsh.md`](boundary/hosts/dsh.md)。其他宿主可照同样分工自建。

**一条硬约束**：`skill/` 下的文件是会被单独安装出去的便携层，因此只能引用同目录内的文件。规则仓库自己的路径（导出器、安装器、模板、宿主绑定）一律**按名字**提到，真实位置写进本机配置文档 §0 —— 这也正是规则正文 §0.1 对自己的要求。

## 其他用法

- **作为仓库指令文件**：把需要的章节并入 `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`。
- **作为人工检查清单**：直接读 [`SKILL.md`](skill/kalcirite-project-rules/SKILL.md)。

规则正文不含密钥、账号或私有路径。**本机配置文档请放在本仓库之外**（并 gitignore），它才是写实的那一份；若其中含内网主机名，更不要提交。

## 许可

MIT，见 [LICENSE](LICENSE)。
