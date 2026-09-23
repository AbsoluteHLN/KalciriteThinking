# KalciriteThinking

**适用于「一台机器、多个仓库」的通用 agent 工程纪律。**

[English](README.en.md) · [规则正文](skills/kalcirite-project-rules/SKILL.md) · [边界模板](PROJECT-BOUNDARY.md)

## 声明

我第一次实际去规范化这种技能，不确保适用于你的工作流，可以以此仅作参考！

## 组成

| 层 | 文件 | 作用 |
|---|---|---|
| 规则（可移植） | [`skills/kalcirite-project-rules/SKILL.md`](skills/kalcirite-project-rules/SKILL.md) | 纪律本体，与环境无关 |
| 边界（机器相关） | [`PROJECT-BOUNDARY.md`](PROJECT-BOUNDARY.md) | 缓存路径、UI 源、工具库、目录名、模型提供方 |
| 配置示例 | [`examples/`](examples/) | DSH / Claude 风格 skill 根、项目级覆盖示例 |
| 同步脚本 | [`scripts/sync-skill.ps1`](scripts/sync-skill.ps1) | 把规则正文复制进任意 agent 的 skill 目录 |

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

## 安装

```powershell
# A. 作为 agent skill（推荐）：复制进 agent 扫描的 skill 根
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -BoundaryPath .\PROJECT-BOUNDARY.md
& .\scripts\sync-skill.ps1 -Target "$HOME\.claude\skills" -BoundaryPath .\PROJECT-BOUNDARY.md
# 其他 agent：把 -Target 指向它的 skill 目录

# B. 作为仓库指令文件：把需要的章节并入 AGENTS.md / CLAUDE.md / CONTRIBUTING.md
# C. 作为人工检查清单：直接读 SKILL.md
```

Windows PowerShell 5.1 与 PowerShell 7+ 均可运行。脚本只复制文件，不执行任何逻辑；规则正文会从 skill 自身目录与机器配置根解析 `PROJECT-BOUNDARY.md`。

## 配置

1. 复制 `PROJECT-BOUNDARY.md` 到 agent 配置根。
2. 填写 `DEP_CACHE`、`UI_SOURCE`、`TOOL_HOME`、目录名、授权模型提供方。
3. 不适用的行直接删掉；留空会让规则**停下来报告**，而不是去猜。
4. 单个仓库有例外时，加一份项目级 `PROJECT-BOUNDARY.md`，其效力高于机器级文件。

示例见 [`examples/`](examples/)。规则正文不含密钥、账号或私有路径——那些属于你的边界文件；若其中含内网主机名，请勿纳入版本控制。

## 许可

MIT，见 [LICENSE](LICENSE)。
