# Boundary example — project-local override

Place this file at a repository root as `PROJECT-BOUNDARY.md`. It **wins over** the machine-level
boundary file, so it should only restate what genuinely differs for this repository.

```md
# PROJECT-BOUNDARY — <repo name>

## Inheritance

Machine file: `<machine-config>/PROJECT-BOUNDARY.md` (all keys not listed here).

## Overrides

| Key | Value | Why |
|---|---|---|
| `BUILD_ROOT` | `build\out` | legacy release pipeline pins this path; migration tracked in `dev-docs/migrations/` |
| fixed ports | `14410` dev server, `14411` local REST | both are referenced from three places: `src/api.ts`, `tauri.conf.json` CSP, `main.rs` CORE_PORT |
| user data (never delete) | `data\todo.md`, `data\goals.md`, `data\audit.jsonl` | live user content at the executable's side |
| `UI_DEFAULT_VERSION` | `v2.3` | product character locked to the curated industrial set |

## Project pointer

| Field | Value |
|---|---|
| Package manager | npm + Cargo |
| Pointer mechanism | `npm_config_cache` + `CARGO_HOME`; `node_modules` is a junction into the cache |
| Source snapshot | `<DEP_CACHE>\<name>-src-tauri` (restore source if the tree is lost) |
| Compat exception | the old `build\` output path is kept **only** for the release pipeline; new targets use `BUILD_ROOT` |
```

## Why project overrides are worth having

- The machine file stays generic and shareable; the project file carries the exceptions.
- An exception is *recorded* rather than silently maintained as a second layout.
- A reviewer can see at a glance which rules this repository bends and why.
