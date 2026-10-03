# One dependency store — installed and used only there; one big folder, never per-build, never per-software

Read this when: installing, resolving, updating, or downloading any dependency; when
a build reports missing packages; or when you suspect more than one copy of a
dependency tree on the machine.

`<DEP_CACHE>` is the single dependency root on this machine. If it is blank, no
dependency work happens at all: stop and report.

The store is the **only place dependencies are installed and used from**: every
install is pinned so its payload lands there, and every consumer resolves through
a link into it. A dependency used or installed anywhere else — a project-local
payload, a per-software location, or the package manager's own default location —
is a violation, even when it "works".

## What convergence means

**One big folder per ecosystem, machine-wide** — not one store per project, not one
folder of dependencies per build, and not one sibling folder per software:

| Ecosystem | The one store | What every consumer does |
|---|---|---|
| Node (pnpm) | the content-addressed `pnpm-store` | resolve into it; a project's `node_modules` is a junction into it |
| Node (npm / yarn) | the npm cache + the shared virtual store | the same: link, never a private payload |
| Rust (cargo) | the registry + git index under `CARGO_HOME` | the registry is the payload; a project `target/` holds *compiled artifacts only* |
| Python | the pip cache + the managed interpreter tree | site-packages live in the store; the project points at them |
| Electron / bundlers | the binary caches (electron, electron-builder) | binaries are downloaded once, into the cache |

### The canonical folder shape (relative to `<DEP_CACHE>`)

Names differ per machine; the **shape** does not. One root folder per ecosystem, and
inside it one folder per role — never a folder per project, per build, or per software:

| Root folder | Sub-tree roles |
|---|---|
| `pnpm/` | `store/` — content-addressed payload; `vstore/` (or a project-level virtual store) — the shared virtual tree; `home/` — `PNPM_HOME` (shims, tools, config); `cache/` — package metadata; resolution views per dependency graph |
| `npm-cache/` | `_cacache/` — HTTP/tarball cache |
| `npm-global/` | the npm **prefix**: exactly one `node_modules/` plus its bin shims at the root (a prefix split across several top-level entries is a defect) |
| `cargo/` | `registry/` — index + crate payload; `git/`; `bin/` — toolchain proxies; `targets/<project>/`, `build/<project>/` — build caches; `config.toml` |
| `rustup/` | `toolchains/`, `settings.toml` |
| `pip-cache/` | pip's HTTP cache |
| `electron/`, `electron-builder/` | binary caches; extracted runtimes are shared inputs, not build output |
| `ms-playwright/`, `node-gyp-cache/`, `ffmpeg/` | browser, header and binary caches |
| `flutter/`, `vcpkg/` | language/package ecosystems with their own `sdks`/`downloads`/`packages` roles |
| `node/`, `node-runtime/`, `corepack/` | **infrastructure** — interpreters and tooling homes, not dependency payloads |
| `shared/` | shared virtual store, managed interpreter environments, shared runtimes |
| `profiles/` | per-tool profile homes (declared infrastructure) |
| `quarantine/` | holding area for incidents and removed duplicates — **read-only, only ever added to** |

Three consequences — and a fourth that applies to the store's own top level:

1. **One payload per ecosystem.** A second content-addressed store, a second
   registry index, or a second virtual tree is the same defect as a per-project
   `node_modules`: another version of the truth that drifts.
2. **Consumers link, they do not copy — and installs land in the store,
   nowhere else.** The project holds a junction / symlink / configured pointer
   that resolves into the store; every package manager is pinned so new payloads
   land in the store. Shared **bytes**, not "it is cached elsewhere too".
3. **No payload exists only for one build.** `cxbuild/<target>/node_modules`, a
   per-variant `vendor/`, an unpacked bundle carrying its own dependency tree — all
   of it is *one folder per build*, the exact pattern this rule forbids. Build
   output is **generated code, never dependencies**: if a packaged app must run
   standalone, its dependencies are produced into the build output from the store,
   not installed into it.
4. **The store's top level is closed — one big folder, no per-software siblings.**
   At the top level of `<DEP_CACHE>` there is one entry per ecosystem store or
   cache, plus declared infrastructure (runtimes, build caches, quarantine). A
   sibling entry that is "the dependencies of X" — a per-software virtual store, a
   per-software package payload, a legacy duplicate of an existing cache — forks
   the store, and the next consumer of that software forks it again. Convergence
   runs down two axes at once: across projects/builds/variants, **and** across the
   software that lives on the machine. The store keeps a **guide at its root**
   (a README) listing every top-level entry, its role, and what may write there;
   a new entry is a decision recorded in the guide, never a side effect.

## Hard rules

1. **Query the store first, and install only into it.** Every install, resolve,
   or download (package managers, language toolchains, app bundlers) goes to the
   store first, and any new payload lands **in the store** — never in a project,
   a per-software location, or the tool's own default location. Store hit → use
   it. No online reinstall.
2. **No dependency payload outside the store.** `node_modules`, `.venv`, vendored
   dependency trees, toolchain caches exist **only** in `<DEP_CACHE>` — a project,
   a build, or a variant may hold a junction / symlink / configured pointer at
   most. Likewise at the top level of the store itself: no per-software store or
   payload beside the real one.
3. **The store is guided and its top level closed.** The README at the store's root
   lists every top-level entry and its role. Before creating a new top-level entry:
   it must be an ecosystem store/cache or declared infrastructure, and it must be
   added to the guide in the same change.
4. **Never clean, delete, reorganise, or overwrite the store.** Archive/quarantine
   areas inside it are read-only.
5. **Confirm closure before building.** If the closure cannot be satisfied from
   the store: **stop and report the missing list**. "Reinstall dependencies" is
   not a repair step.
6. **Fetching is an exception with a gate.** If a package is genuinely absent,
   report the list, get explicit human authorisation, then bring the new payload
   **into the store** and update the store index and guide.
7. **No shadow runtimes.** Interpreters and virtual environments must come from
   the store, not from a system Conda, a user-level cache, or a project-local
   `.venv`.
8. **Never delete a linked dependency directory** — deleting a junction
   recursively punches through into the shared store. Never run a toolchain's
   "clean" command on a store-backed build.
9. **No unlinked duplicate inside the store either.** One store per ecosystem is
   only half of convergence: inside it, identical content must exist **once**, as
   shared physical bytes. A second physical copy of bytes that the store already
   holds — the classic result of an install that ran while the store lived on
   another volume — is the same defect one level down: it double-counts disk,
   drifts, and hides the true size of the machine's dependency footprint.

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
# 4. The store's top level is closed: every entry is listed in the store guide.
Get-ChildItem -Path <DEP_CACHE> -Directory | Select-Object -ExpandProperty Name
#    compare against the top-level table in <DEP_CACHE>\README.md — anything
#    not listed (especially a payload named after a software) is a defect.
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
# 4. The store's top level is closed: compare against the store guide's table.
ls -1 "$DEP_CACHE"                # every entry must be listed in $DEP_CACHE/README.md
```

A payload-named directory **without** a link type, anywhere under the project, is a
defect: an install ran that was not pointed at the store. Point the package manager
at the store and re-link; remove the stray tree only after the closure is confirmed
satisfied from the store (deleting a *linked* tree would punch into it).

Bypass the package-manager script wrapper when it tries to re-verify and prune
modules (a common way junctions get destroyed): call the tool binary directly
(e.g. `node_modules/.bin/<tool> build`).

## Physical convergence — one copy of the bytes, however many paths

Layout convergence (one store, linked consumers) is only half of the rule: the trees
inside the store must not carry the same content twice either.

1. **Logical ≠ physical.** A tree that reports 2 GB may hold 2 GB or 2 MB of real
   bytes, depending on hard links and junctions. Audit **physical** bytes: count a
   file with more than one link once, never once per path, and never follow a
   junction during the walk. A "huge" store is usually hard links and symlinks
   being counted twice — measure before concluding anything.
2. **Identical content is shared, never copied twice.** When a file inside the store
   has the same bytes as one the store already holds (or as another file in the
   store), replace it with a hard link — same volume — or a junction. This is the
   mechanism the package managers already use; a real copy appears when the install
   ran with its store on a different volume, or with a copy-style import method.
3. **Replace safely: link first, then rename.** Create the new link under a
   temporary name and rename it over the target, so the original disappears only
   after a valid replacement exists. Never delete first and link second — a failure
   between the two steps loses the file.
4. **A content-addressed store names files by hash.** In pnpm's store the file path
   is `<store>/<hash[0:2]>/<hash[2:]>`, where the concatenation is the content's
   SHA-512 in hex. "Is this content already in the store?" is therefore one hash
   plus one `stat` — no index lookup needed.
5. **Leave mutable files alone.** Skip metadata that tools rewrite
   (`package.json`, lockfiles, `.modules.yaml`), regenerable artefacts
   (`.o`, `.rlib`, `.pyc`, logs, sqlite/log files) and build caches (`.vite`,
   `.turbo`, `.next`, coverage) — linking those risks cross-contamination for
   almost no space.

Audit physical bytes (Node, portable):

```js
// node physical-bytes.mjs <DEP_CACHE>   — hard-linked files counted once
import fs from 'node:fs'; import path from 'node:path';
const root = process.argv[2]; const seen = new Set(); let bytes = 0;
(function walk(d){ for (const e of fs.readdirSync(d,{withFileTypes:true})) {
  const p = path.join(d, e.name); const st = fs.lstatSync(p);
  if (st.isSymbolicLink()) continue;
  if (st.isDirectory()) { walk(p); continue; }
  if (st.nlink > 1) { const id = st.dev + ':' + st.ino; if (seen.has(id)) return; seen.add(id); }
  bytes += st.size;
} })(root);
console.log((bytes / 1073741824).toFixed(3), 'GiB physical');
```

## Failure protocol

1. Store hit → link → build.
2. Store miss → **stop** → report the exact missing packages and why they are
   needed.
3. Reported and authorised → fetch once → land the payload in the store → link →
   record it in the store index.
4. Never: install into the project, create a second store, add a payload for one
   build, or vendor a copy.

## Why a second payload tree is a defect, wherever it lands

A second payload tree — per project, per build, per variant, **or per software** —
is a second version of the truth. It goes stale silently, it double-counts disk and
download budget, it breaks the "confirm closure before building" guarantee (the
build now *has* a closure, so nothing reports the gap), and it makes every later
audit answer a different question. A per-software store beside the real one is the
same fork one level up: the software's consumer reads its private copy, the store
sits there for the other software, and the two copies disagree by the next update.
When a build or a program seems to require one, the real finding is a missing or
incomplete store entry — report that.
