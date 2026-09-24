# One dependency cache, linked — never vendored

Read this when: installing, resolving, updating, or downloading any dependency, or
when a build reports missing packages.

`<DEP_CACHE>` is the single dependency root on this machine. If it is blank, no
dependency work happens at all: stop and report.

## Hard rules

1. **Query the cache first** for every install, resolve, or download (package
   managers, language toolchains, app bundlers). Cache hit → use it. No online
   reinstall.
2. **No dependency payload inside a project.** `node_modules`, `.venv`, vendored
   dependency trees, toolchain caches exist **only** in `<DEP_CACHE>`; the project
   holds a junction / symlink / configured pointer at most.
3. **Never clean, delete, reorganise, or overwrite the cache.** Archive/quarantine
   areas inside it are read-only.
4. **Confirm closure before building.** If the closure cannot be satisfied from the
   cache: **stop and report the missing list**. "Reinstall dependencies" is not a
   repair step.
5. **Fetching is an exception with a gate.** If a package is genuinely absent, report
   the list, get explicit human authorisation, then bring the new payload **into the
   cache** and update the cache index.
6. **No shadow runtimes.** Interpreters and virtual environments must come from the
   cache, not from a system Conda, a user-level cache, or a project-local `.venv`.
7. **Never delete a linked dependency directory** — deleting a junction recursively
   punches through into the shared cache. Never run a toolchain's "clean" command on
   a cache-backed build.

## Pointer mechanisms (pick per ecosystem)

| Ecosystem | Mechanism | Note |
|---|---|---|
| Node (pnpm) | workspace config `storeDir` + `virtualStoreDir`; `node_modules` junction into the cache | pnpm may ignore `.npmrc`'s store dir; pin it in the workspace file |
| Node (npm) | `npm_config_cache`; junction for the installed tree | |
| Rust/Cargo | `CARGO_HOME` (+ optional per-project `.cargo/config.toml`) | offline builds; the embedded registry path is expected and accepted |
| Python | `PIP_CACHE_DIR`; interpreter and site-packages owned by the cache | disable user site-packages |
| Electron / build tools | tool-specific cache env vars | avoids re-downloading binaries |

## Executable checks

```powershell
pnpm config get store-dir        # expect the cache store path
npm  config get cache            # expect the cache path
$env:CARGO_HOME                  # expect the cache cargo path
$env:PIP_CACHE_DIR               # expect the cache pip path
(Get-Item '<project>\node_modules' -Force).LinkType   # expect Junction / SymbolicLink
```

```bash
readlink -f node_modules          # expect a path inside the cache
test -e "$DEP_CACHE" && echo present
```

Bypass the package-manager script wrapper when it tries to re-verify and prune
modules (a common way junctions get destroyed): call the tool binary directly
(e.g. `node_modules/.bin/<tool> build`).

## Failure protocol

1. Cache hit → link → build.
2. Cache miss → **stop** → report the exact missing packages and why they are needed.
3. Reported and authorised → fetch once → land the payload in the cache → link →
   record it in the cache index.
4. Never: install into the project, create a second store, or vendor a copy.

## Why a per-project install is a defect, not a preference

A second payload tree is a second version of the truth. It goes stale silently, it
double-counts disk and download budget, it breaks the "confirm closure before
building" guarantee (the project now *has* a closure, so nothing reports the gap),
and it makes every later audit answer a different question. When a build seems to
require one, the real finding is a missing or incomplete cache entry — report that.
