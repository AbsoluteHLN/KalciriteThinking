# One dependency store — converged, never per-build

Read this when: installing, resolving, updating, or downloading any dependency; when
a build reports missing packages; or when you suspect more than one copy of a
dependency tree on the machine.

`<DEP_CACHE>` is the single dependency root on this machine. If it is blank, no
dependency work happens at all: stop and report.

## What convergence means

**One store per ecosystem, machine-wide** — not one store per project, and not one
folder of dependencies per build:

| Ecosystem | The one store | What every consumer does |
|---|---|---|
| Node (pnpm) | the content-addressed `pnpm-store` | resolve into it; a project's `node_modules` is a junction into it |
| Node (npm / yarn) | the npm cache + the shared virtual store | the same: link, never a private payload |
| Rust (cargo) | the registry + git index under `CARGO_HOME` | the registry is the payload; a project `target/` holds *compiled artifacts only* |
| Python | the pip cache + the managed interpreter tree | site-packages live in the store; the project points at them |
| Electron / bundlers | the binary caches (electron, electron-builder) | binaries are downloaded once, into the cache |

Three consequences:

1. **One payload per ecosystem.** A second content-addressed store, a second
   registry index, or a second virtual tree is the same defect as a per-project
   `node_modules`: another version of the truth that drifts.
2. **Consumers link, they do not copy.** The project holds a junction / symlink /
   configured pointer that resolves into the store — shared **bytes**, not "it is
   cached elsewhere too".
3. **No payload exists only for one build.** `cxbuild/<target>/node_modules`, a
   per-variant `vendor/`, an unpacked bundle carrying its own dependency tree — all
   of it is *one folder per build*, the exact pattern this rule forbids. Build
   output is **generated code, never dependencies**: if a packaged app must run
   standalone, its dependencies are produced into the build output from the store,
   not installed into it.

## Hard rules

1. **Query the store first** for every install, resolve, or download (package
   managers, language toolchains, app bundlers). Store hit → use it. No online
   reinstall.
2. **No dependency payload outside the store.** `node_modules`, `.venv`, vendored
   dependency trees, toolchain caches exist **only** in `<DEP_CACHE>` — a project,
   a build, or a variant may hold a junction / symlink / configured pointer at
   most.
3. **Never clean, delete, reorganise, or overwrite the store.** Archive/quarantine
   areas inside it are read-only.
4. **Confirm closure before building.** If the closure cannot be satisfied from
   the store: **stop and report the missing list**. "Reinstall dependencies" is
   not a repair step.
5. **Fetching is an exception with a gate.** If a package is genuinely absent,
   report the list, get explicit human authorisation, then bring the new payload
   **into the store** and update the store index.
6. **No shadow runtimes.** Interpreters and virtual environments must come from
   the store, not from a system Conda, a user-level cache, or a project-local
   `.venv`.
7. **Never delete a linked dependency directory** — deleting a junction
   recursively punches through into the shared store. Never run a toolchain's
   "clean" command on a store-backed build.

## Pointer mechanisms (pick per ecosystem)

| Ecosystem | Mechanism | Note |
|---|---|---|
| Node (pnpm) | workspace config `storeDir` + `virtualStoreDir`; `node_modules` junction into the store | pnpm may ignore `.npmrc`'s store dir; pin it in the workspace file |
| Node (npm) | `npm_config_cache`; junction for the installed tree | |
| Rust/Cargo | `CARGO_HOME` (+ optional per-project `.cargo/config.toml`) | offline builds; the embedded registry path is expected and accepted |
| Python | `PIP_CACHE_DIR`; interpreter and site-packages owned by the store | disable user site-packages |
| Electron / build tools | tool-specific cache env vars | avoids re-downloading binaries |

## Proving convergence

```powershell
# 1. The project holds no payload of its own: expect NO output.
Get-ChildItem -Path <project> -Recurse -Force -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -in 'node_modules','vendor','.venv','venv','site-packages','Pods' -and $null -eq $_.LinkType }
# 2. A payload that is present must be a link into the store:
(Get-Item '<project>\node_modules' -Force).LinkType   # expect Junction / SymbolicLink
(Get-Item '<project>\node_modules').Target            # expect a path inside <DEP_CACHE>
# 3. The store is the one root, machine-wide:
pnpm config get store-dir ; npm config get cache
$env:CARGO_HOME ; $env:PIP_CACHE_DIR
```

```bash
# 1. The project holds no real payload directory: expect no output.
#    (find without -L: links are not reported as directories)
find <project> -type d \( -name node_modules -o -name vendor -o -name .venv \
  -o -name venv -o -name site-packages -o -name Pods \)
# 2. A payload that is present must link into the store:
readlink -f node_modules          # expect a path inside the store
# 3. The store is the one root, machine-wide:
pnpm config get store-dir ; npm config get cache
echo "$CARGO_HOME" "$PIP_CACHE_DIR"
test -e "$DEP_CACHE" && echo present
```

A payload-named directory **without** a link type, anywhere under the project, is a
defect: an install ran that was not pointed at the store. Point the package manager
at the store and re-link; remove the stray tree only after the closure is confirmed
satisfied from the store (deleting a *linked* tree would punch into it).

Bypass the package-manager script wrapper when it tries to re-verify and prune
modules (a common way junctions get destroyed): call the tool binary directly
(e.g. `node_modules/.bin/<tool> build`).

## Failure protocol

1. Store hit → link → build.
2. Store miss → **stop** → report the exact missing packages and why they are
   needed.
3. Reported and authorised → fetch once → land the payload in the store → link →
   record it in the store index.
4. Never: install into the project, create a second store, add a payload for one
   build, or vendor a copy.

## Why a second payload tree is a defect, wherever it lands

A second payload tree — per project, per build, or per variant — is a second
version of the truth. It goes stale silently, it double-counts disk and download
budget, it breaks the "confirm closure before building" guarantee (the build now
*has* a closure, so nothing reports the gap), and it makes every later audit answer
a different question. When a build seems to require one, the real finding is a
missing or incomplete store entry — report that.
