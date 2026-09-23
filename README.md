# KalciriteThinking

**适用于「一台机器、多个仓库」的通用 agent 工程纪律。**

[English](README.en.md) · [规则正文](skills/kalcirite-project-rules/SKILL.md) · [边界模板](boundary/PROJECT-BOUNDARY.template.md)

## 声明

我第一次实际去规范化这种技能，不确保适用于你的工作流，可以以此仅作参考！

## 两层结构

| 层 | 目录 | 内容 | 可否直接共享 |
|---|---|---|---|
| **通用层** | [`skills/`](skills/) [`boundary/`](boundary/) [`scripts/`](scripts/) [`examples/`](examples/) | 规则正文、边界模板与提问清单、安装脚本、示例 | 可以。不含任何私有路径 |
| **本机层** | [`local/`](local/) | 本机写实边界值、项目专有事实 | **不要**。只作参考，不进别人的机器 |

本机层的文件是**一份已经填好的答案**，不是规则的一部分。别人拿到的是通用层，然后用安装向导生成自己的本机层。

## 十条原则

1. **先构建，后一次验证**：改动做完整 → 构建 → 集中一次验证。
2. **按推理深度路由，而非按任务大小**：廉价模型读、强模型判断；先发现路由，不猜模型名，不越出授权提供方。
3. **唯一依赖缓存**：一切依赖装进机器级缓存并链接使用，项目内永不出现依赖实体。
4. **唯一 UI 上游**：接入并遵守其契约；项目样式表只管布局，不管配色。
5. **先复用后新建**：先查公共工具库；确实没有，也在库内按既有边界新建。
6. **干净目录**：`src/ docs/ dev-docs/ verify-evidence/ cxbuild/ temp/`，一个构建产物根、一个临时根。
7. **变动即归档**：被取代的文件进 archive 或按清单安全删除，不留主路径。
8. **自包含转接**：绝对路径、明确可写范围、约定回传格式。
9. **有证据才算结论**：已验证 / 已尝试 / 未尝试，是三个不同的词。
10. **事实靠实测**：路径、端口、版本先量后说。

## 安装：先提问，再写回

规则正文里没有任何硬编码路径。安装必须**先问清这台机器的细节**，再把答案写回本地技能内容 —— 这是保证智能的前提：宁可停下来问，也不要猜。

```powershell
# 首次安装：交互式提问 → 复制规则 → 写回边界文件与本机档案块
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills"
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills"       # Claude 风格
# 其他 agent：把 -Target 指向它的 skill 目录

# 机器细节变了：重新提问
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -Reconfigure

# 只更新规则正文（保留本机答案）
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

向导会问的六类事：

1. **唯一依赖缓存**放在哪、子目录怎么分；
2. **唯一 UI 上游**在哪、默认版本、预览源（没有就答 `none`）；
3. **公共工具/插件库**在哪；
4. **项目目录**名字（`src` / `docs` / `dev-docs` / `verify-evidence` / `cxbuild` / `temp`）；
5. **成本分级模型路由**：授权的提供方与各档模型；
6. **子代理与模型选用**：这台机器的宿主 agent 是什么、它暴露哪些委派工具、能否为子代理指定模型、开关在哪、何时生效、并发上限。

问题清单与写法见 [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md)，子代理/模型选用的细节见 [`boundary/DELEGATION.md`](boundary/DELEGATION.md)。

答案会写回两处：技能目录内的 `PROJECT-BOUNDARY.md`（就近解析，§0.1 第 2 顺位）和已安装 `SKILL.md` 里的 `local-profile` 块。**留空是合法答案**，含义是「不作假设」—— 规则会停下来报告，而不是去猜。项目级例外再放一份 `<项目根>/PROJECT-BOUNDARY.md`，效力最高。

脚本在 Windows PowerShell 5.1 与 PowerShell 7+ 均可运行，只复制文件，不执行任何逻辑。用法见 [`scripts/README.md`](scripts/README.md)，示例见 [`examples/`](examples/)。

## 其他用法

- **作为仓库指令文件**：把需要的章节并入 `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`。
- **作为人工检查清单**：直接读 `SKILL.md`。

规则正文不含密钥、账号或私有路径；若你的边界文件含内网主机名，请勿纳入版本控制。

## 许可

MIT，见 [LICENSE](LICENSE)。
