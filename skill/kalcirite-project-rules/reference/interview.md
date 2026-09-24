# First-run interview

Read this when: the boundary is unresolved, `SKILL.md` §0.2 sent you here, or the
machine changed (new cache, new UI source, new provider, new shell).

The rule text knows the rules; it does not know this machine. Until the answers
exist on disk, every path, port, and model id in it is a placeholder.

## Gate

**Stop before touching anything** if any of these is true:

- no boundary file resolves by the `SKILL.md` §0.1 order;
- the boundary still contains `<PLACEHOLDER>` or `<...>` tokens;
- the local profile block in `SKILL.md` is present but empty.

Do not edit, build, install, reorganise, or delete until the answers are written
back. An answer that lives only in the conversation is lost.

## Flow: three steps, in this order

| Step | Who | Produces |
|---|---|---|
| 1. Ask | the agent, once, in one batch | the answers |
| 2. Record | the agent | the machine-config document — one hand-edited, human-facing document (the rules repository ships a `MACHINE-CONFIG` template showing its shape) |
| 3. Export + install | the rules repository's exporter, then its installer | `PROJECT-BOUNDARY.md` in the skill directory |

The paths to the exporter, the installer and the template are **not** in this file: they
are recorded in §0 of the machine-config document itself, so the rule text stays
environment-neutral. When §0 is unavailable, reproduce step 3 with any tool.

The machine-config document is hand-edited and human-facing; the boundary file is
generated from it and agent-facing. Never edit the generated file — the next
export overwrites it. On a non-Windows host, reproduce step 3 with any tool: the
boundary file is the document's keyed rows plus a `kalcirite:answers` JSON block.

## Questions

Ask **in one batch**, in the user's language. Each question carries a **probed
default** labelled *detected* (you read it) or *guess* (you did not).

| # | Ask | Keys | How to probe | If the user leaves it blank |
|---|---|---|---|---|
| 1 | Which single directory is the ONE dependency store for this machine — every project and every build resolves from it (no per-project or per-build payload)? | `DEP_CACHE` (+ derived sub-keys) | workspace drive + `\dependency-cache`; `pnpm store path`; `npm config get cache` | **blocking** — no dependency work at all |
| 2 | Keep the conventional sub-layout under it (`pnpm-store`, `npm-cache`, `pip-cache`, `cargo`, `electron\Cache`, `electron-builder\Cache`)? | derived | which sub-directories already exist | name each one individually |
| 3 | Is there a canonical UI source (design system / component engine), and where? | `UI_SOURCE`, `UI_VERSION`, `UI_PREVIEW` | sibling `*ui*` / `ui-source` directories | record `none`; §4 degrades to "one UI source per project, and styling must still be tokenised" |
| 4 | Is there a shared tool/plugin catalogue, and where? | `TOOL_HOME`, `TOOL_INDEX`, `TOOL_REGISTRY`, `TOOL_VALIDATOR` | sibling catalogue repo; `INDEX.md`, `registry.json`, `**/validate-*` | record `none`; §5 degrades to "search the project's own `tools/` first" |
| 5 | Build output root, scratch root, evidence root, docs roots? | `BUILD_ROOT`, `TMP`, `EVIDENCE`, `DOCS`, `DEV_DOCS` | defaults `cxbuild/`, `temp/`, `verify-evidence/`, `docs/`, `dev-docs/` | use the defaults |
| 6 | Which model provider is authorised, and what are its cheap model **ids** (not display names)? Plus the delegation facts: which sub-agent tools exist, can a delegation pick its own route, which setting enables that, when does it take effect, any concurrency limit? | `ROUTE_PROVIDER`, `CHEAP_MODELS`, `ROUTE_TOOL`, `HOST_AGENT`, `DELEGATION_TOOLS`, `ROUTE_SELECTION_SUPPORTED`, `ROUTE_ENABLE_SETTING`, `ROUTE_TAKES_EFFECT`, `CONCURRENCY_LIMIT` | the agent's model settings / config file; the host's tool list | record `none` for each; delegation stays on the parent route and model selection is reported as unavailable (`delegation.md`) |
| 7 | What shell/OS constraints change command syntax? | `SHELL_NOTE` | `$PSVersionTable`, `Get-Command pwsh`, `bash` availability | assume nothing; re-ask when a command fails |
| 8 | Proxy, fixed ports, and paths or data that must never be deleted? | `PROXY`, `PORTS`, `NEVER_DELETE` | project docs, config files, registry | record what is confirmed; mark the rest `(unverified)` |
| 9 | Are there top-level names this machine's projects legitimately need beyond the built-in layout? | `EXTRA_TOP_LEVEL` | existing project roots | leave blank — the whitelist then stays closed |

Question 3 (UI) and question 4 (tools) can be skipped outright when the project
in front of you obviously has neither; record `none` rather than asking.

## Interview rules

1. **Write the answers back before proceeding.** Prefer the project root when the
   values are project-scoped, otherwise the skill directory, then the agent config
   root. Also fill the local profile block inside `SKILL.md` whenever that file is
   writable — it is the last resort for hosts with no boundary support.
2. **Verify every path as you record it**, with an existence check. A path that
   does not exist is written with `(unverified)`, never silently.
3. **Blank is a legitimate answer.** Blank or `none` makes the rules *stop and
   report* for that domain; it never authorises guessing.
4. **Re-ask when the environment changes** — a moved cache, a new UI source, a new
   provider, a new shell. Update the config document, not the rule text.
5. **If the user declines to answer**, state which domains are now unrouted, and
   keep working only in domains that need no boundary value.
6. **Do not interview twice.** If a filled boundary file already exists, read it
   and proceed; ask only about values that are new, stale, or contradictory.

## What "blank" resolves to

| Key | Blank means |
|---|---|
| `DEP_CACHE` | blocking: no install, resolve, or download of any kind |
| `UI_SOURCE` | one UI source per project, styling still tokenised; do not invent a design system |
| `TOOL_HOME` | search the project's own `tools/` first; do not create a shared catalogue unasked |
| `BUILD_ROOT` / `TMP` / `EVIDENCE` / `DOCS` / `DEV_DOCS` | the documented defaults apply |
| `ROUTE_*` / `DELEGATION_TOOLS` | delegation runs on the inherited route; model selection is reported unavailable |
| `SHELL_NOTE` | assume nothing; re-ask when a command fails |
| `NEVER_DELETE` | nothing beyond the red lines in `SKILL.md` §9 is protected |

## Project overrides

A project may override any machine value with its own `PROJECT-BOUNDARY.md` (or a
`PROJECT-BOUNDARY` section in its `AGENTS.md` / `.kalcirite/boundary.md`). Project
answers win; machine answers fill the gaps. Record a project-only exception in the
project's file, not in the machine document, and never in this rule text.
