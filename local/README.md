# local/ — 本机专用层

这一层**只属于这台机器**，不是给别人装的：

| 文件 | 内容 |
|---|---|
| [`PROJECT-BOUNDARY.md`](PROJECT-BOUNDARY.md) | 本机边界值：`E:\dependency-cache`、`E:\Projects\KalciriteUI`、`E:\KalciriteTools`、端口、代理、shell 约束 |
| [`LOCAL-RULES.zh.md`](LOCAL-RULES.zh.md) | 中文规则 + 本机写实值 + 项目专有事实（Taskasion 等） |

## 边界

- **通用层**（`skills/`、`boundary/`、`scripts/`、`examples/`）不含任何本机路径，可以直接给别人。
- 别人安装时拿到的是空白模板 + 入职问卷，由 `scripts/install-skill.ps1` 或 agent 的首次访谈（规则正文 §0.2）填成**他们自己**的边界。
- 本目录里的路径**不要**复制进通用层，也不要用它当别人的示例——示例在 [`../examples/`](../examples/)。
- 本机路径变了，改这里；规则正文不动。

## 同步到本机 agent

```powershell
# 首次：向导提问并写回
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary .\local\PROJECT-BOUNDARY.md

# 更新规则正文：保留已填答案
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```
