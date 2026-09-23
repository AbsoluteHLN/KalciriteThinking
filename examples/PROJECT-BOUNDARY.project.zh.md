# 边界文件示例 —— 项目级覆盖

把本文件放在某个仓库根目录，命名为 `PROJECT-BOUNDARY.md`。它的效力**高于**机器级边界文件，
因此只写该仓库真正不同的部分。

```md
# PROJECT-BOUNDARY —— <仓库名>

## 继承

机器级文件：`<机器配置根>/PROJECT-BOUNDARY.md`（此处未列出的键全部继承）。

## 覆盖项

| 键 | 值 | 原因 |
|---|---|---|
| `BUILD_ROOT` | `build\out` | 旧发布流水线钉死该路径；迁移记录在 `dev-docs/migrations/` |
| 固定端口 | `14410` 开发服务器、`14411` 本地 REST | 三处引用必须一致：`src/api.ts`、`tauri.conf.json` CSP、`main.rs` CORE_PORT |
| 用户数据（永不删除） | `data\todo.md`、`data\goals.md`、`data\audit.jsonl` | 可执行文件同级的实时用户内容 |
| `UI_DEFAULT_VERSION` | `v2.3` | 产品调性锁定在收紧的工业系列 |

## 项目指向

| 项 | 值 |
|---|---|
| 包管理 | npm + Cargo |
| 指向机制 | `npm_config_cache` + `CARGO_HOME`；`node_modules` 为指向缓存的 junction |
| 源码快照 | `<DEP_CACHE>\<name>-src-tauri`（源码树丢失时的恢复源） |
| 兼容例外 | 旧 `build\` 输出路径**仅为**发布流水线保留；新产物一律走 `BUILD_ROOT` |
```

## 为什么值得有项目级覆盖

- 机器级文件保持通用、可共享；例外只写在项目文件里。
- 例外是被**记录**下来的，而不是悄悄维护成第二套目录结构。
- 评审者一眼就能看出：这个仓库在哪些规则上做了让步，为什么。
