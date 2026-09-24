# KalciriteThinking

**Portable engineering discipline for agents working across many repositories on one machine.**

[中文](README.md) · [Rule text](skill/kalcirite-project-rules/SKILL.md) · [Machine-config template](boundary/MACHINE-CONFIG.template.md) · [Changelog](CHANGELOG.md)

## Disclaimer

This is my first real attempt at formalising a discipline like this. It is not guaranteed to fit your workflow — treat it as reference material only.

## Three layers

| Layer | Location | Contents | Shareable as-is |
|---|---|---|---|
| **Portable** | this repository | Rule text and its reference pages, machine-config template and question bank, host-adapter contract and bindings, scripts | Yes — no private paths |
| **Machine-config document** | outside this repository, one single document | Everything specific to one machine: host and environment, dependency cache, UI source, tool catalogue, layout contract, model routing, network and ports | **No** — reference only |
| **Machine-readable boundary file** | exported from the machine-config document | Key/value tables plus the `kalcirite:answers` JSON read by the installer and the host adapter | Same |

### The machine config is its own document

Machine facts are **not written into the rule text, and not scattered around**: they live in one document. That document is deliberately a **sibling directory** of this repository rather than a subdirectory of it, e.g. `<parent>\KalciriteThinking-local\MACHINE-CONFIG.md` (the repository's `.gitignore` also excludes `local/` as a safety net) — committing it would publish one machine's paths, accounts and ports.

- **One document, one place.** Paths, ports, caches and model routes appear there exactly once; the rule text stays environment-neutral and resolves values through its §0.1 order.
- **What the tools read is derived.** `export-boundary.ps1` turns the document's key/value tables into `PROJECT-BOUNDARY.md`: it keeps the `##` sections, drops the third commentary column and appends the `kalcirite:answers` JSON block. The installer and the host adapter read only that file, so the hand-written values and the machine-read values cannot drift apart.
- **The installer generates nothing.** It copies the exported boundary file in byte-for-byte, then fills the `local-profile` block. There is exactly one place a value can come from.
- **Others do not need this document.** They get a blank template plus the first-run interview (rule text §0.2, question bank in [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md)); *they* answer, and the answers land in *their own* document with the same shape.
- **Moving machine touches only this document.** Rule text, templates, scripts and adapter stay put.

The local documents are *a filled-in answer sheet*, not part of the rules.

## Repository layout

| Path | Contents |
|---|---|
| [`skill/kalcirite-project-rules/`](skill/kalcirite-project-rules/) | The rule text `SKILL.md`; depth moved into `reference/` (interview, delegation and model selection, dependency cache, UI and tool catalogue, host-adapter contract) |
| [`boundary/`](boundary/) | Portable-side boundary material: config template, question bank, per-project examples |
| [`boundary/hosts/`](boundary/hosts/) | Shipped host bindings: [DSH](boundary/hosts/dsh.md); what any host must implement is specified by `reference/host-adapters.md` in the rule text |
| [`scripts/`](scripts/) | The exporter and the install/sync scripts; usage in [`scripts/README.md`](scripts/README.md) |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history of the rule text; `sync-skill.ps1` prints the delta |

The adapter code itself is not here — it lives in the shared tool catalogue as `agent-adapters/dsh-kalcirite-boundary` (its concrete path is in the machine-config document).

## The ten principles

1. **Build first, verify once.** Complete the change, build it, then run one central verification pass.
2. **Route by reasoning depth, not by task size.** Cheap models read; strong models judge. Discover routes, never guess names, never leave the authorised provider.
3. **One dependency cache.** Everything installs into a single machine-level cache and is linked in. No project-local dependency payloads.
4. **One canonical UI source.** Integrate it and follow its contract; project CSS carries layout only, never colour.
5. **Reuse before rebuild.** Search the shared catalogue; if it is missing, build it inside the catalogue on the existing boundaries.
6. **One clean layout.** `src/ docs/ dev-docs/ verify-evidence/ cxbuild/ temp/`. One build-output root, one scratch root.
7. **Archive on change.** Superseded files are archived or deleted with a checklist — not left on the main path.
8. **Self-contained handoff.** Absolute paths, explicit write scope, stated return format.
9. **Evidence-gated claims.** Verified / attempted / not attempted are three different words.
10. **Facts are checked, not remembered.** Paths, ports, versions: measure first.

## Install: three steps, and only the first is hand-written

The rule text hard-codes no paths, so values must first land in a document and then be derived into the file the tools read.

```powershell
# 1. copy the template out of the repo and fill it in (keep it out of the repo)
Copy-Item .\boundary\MACHINE-CONFIG.template.md ..\MACHINE-CONFIG.md

# 2. export the tool-facing boundary file
& .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.md -Out ..\PROJECT-BOUNDARY.md

# 3. install: copy the rules + copy the boundary file verbatim + fill the local profile
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
# Any other agent: point -Target at its skill directory

# Rule text only (keeps your answers)
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

The installer has **no interactive mode**: the interview belongs to the agent, and rule text §0.2 defines its entry point and its questions. With no `-FromBoundary` and no boundary already installed, it stops and prints the three commands above.

The `MACHINE-CONFIG.md` you fill in has eight sections: host and environment, dependency cache, UI source, tool catalogue, layout contract, model routing, sub-agents and delegation, and project-specific exceptions. The question bank is in [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md); the sub-agent / model-selection details are in [`reference/delegation.md`](skill/kalcirite-project-rules/reference/delegation.md) (generic recording) and [`boundary/hosts/dsh.md`](boundary/hosts/dsh.md) (the measured DSH answers).

Answers land in two places: `PROJECT-BOUNDARY.md` inside the skill directory (nearest-hit resolution, §0.1 rule 2) and the `local-profile` block inside the installed `SKILL.md`. **Blank is a valid answer** meaning "no assumption" — the rules stop and report instead of guessing. A per-project `<project>/PROJECT-BOUNDARY.md` wins over both.

The installer rejects any document whose values are literally `<...>`, refuses an empty `DEP_CACHE` outright, and never overwrites a hand-written legacy boundary file without `-Force`.

What you maintain by hand is the **machine-config document**; that `PROJECT-BOUNDARY.md` is its machine-readable export, produced by the exporter — do not edit it by hand.

The scripts run on Windows PowerShell 5.1 and PowerShell 7+, and copy or generate files only, executing nothing from the repository. Full usage in [`scripts/README.md`](scripts/README.md); per-project examples in [`boundary/examples/`](boundary/examples/).

## Making the rules actually hold: a host adapter

A skill is a document: it is read once and decays across long sessions and compaction, and nothing reacts to a misplaced file. Making the layout boundary hold requires a mechanism on the host side.

- **Location**: `agent-adapters/dsh-kalcirite-boundary` in the shared tool catalogue (the concrete path on my machine is in the machine-config document, not in the portable layer).
- **Injection**: the resolved boundary values and layout contract join every prompt assembly, so the facts no longer decay with the skill document.
- **Interception**: `write` / `edit` and shell commands are checked against the rules — a **new** top-level entry outside the allow list, a dependency payload inside the project, build output outside the build root, and an unconfigured boundary. By default each path is denied once with an explanation, and an identical retry proceeds.
- **Only paths that do not exist yet are ever flagged**, so adopting a legacy project is never blocked.
- **Unconfigured means no passage**: a missing boundary file or an empty `DEP_CACHE` hard-blocks writes and install-like commands until §0.2 has been answered.

**The split**: the skill text carries the rules and their resolution order (portable across agents); the adapter carries injection and interception (host-specific). That split is a contract another host can implement, shipped with the rule text as [`reference/host-adapters.md`](skill/kalcirite-project-rules/reference/host-adapters.md); the binding shipped for my machine is in [`boundary/hosts/dsh.md`](boundary/hosts/dsh.md).

**One hard constraint**: files under `skill/` are the portable layer that gets installed on its own, so they may only reference files inside that directory. The rules repository's own paths (exporter, installer, template, host bindings) are referred to **by name**, with the real location recorded in §0 of the machine-config document — which is exactly what the rule text's own §0.1 demands of itself.

## Other ways to use it

- **As a repository instruction file**: append the sections you need to `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`.
- **As a human checklist**: read [`SKILL.md`](skill/kalcirite-project-rules/SKILL.md) directly.

The rule text contains no secrets, accounts, or private paths. **Keep your machine-config document outside this repository** (and gitignored) — that is the one holding real values; if it names internal hosts, never commit it.

## License

MIT — see [LICENSE](LICENSE).
