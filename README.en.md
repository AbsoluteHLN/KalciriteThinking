# KalciriteThinking

**Portable engineering discipline for agents working across many repositories on one machine.**

[中文](README.md) · [Rule text](skills/kalcirite-project-rules/SKILL.md) · [Boundary template](PROJECT-BOUNDARY.md)

## What it contains

| Layer | File | Purpose |
|---|---|---|
| Rules (portable) | [`skills/kalcirite-project-rules/SKILL.md`](skills/kalcirite-project-rules/SKILL.md) | The discipline itself, environment-neutral |
| Boundary (machine-specific) | [`PROJECT-BOUNDARY.md`](PROJECT-BOUNDARY.md) | Cache paths, UI source, tool catalogue, layout names, model provider |
| Config examples | [`examples/`](examples/) | Boundary files for DSH / Claude-style skill roots and a project-local override |
| Sync helper | [`scripts/sync-skill.ps1`](scripts/sync-skill.ps1) | Copy the rule text into any agent's skill directory |

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

## Install

```powershell
# A. As an agent skill (recommended): copy into the skill root your agent scans
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -BoundaryPath .\PROJECT-BOUNDARY.md
& .\scripts\sync-skill.ps1 -Target "$HOME\.claude\skills" -BoundaryPath .\PROJECT-BOUNDARY.md
# Any other agent: point -Target at its skill directory

# B. As a repository instruction file: append the sections you need to AGENTS.md / CLAUDE.md / CONTRIBUTING.md
# C. As a human checklist: read SKILL.md directly
```

Works in Windows PowerShell 5.1 and PowerShell 7+. The helper only copies files; nothing executes on install. The rule text resolves `PROJECT-BOUNDARY.md` from the skill's own directory and from the machine config root.

## Configure

1. Copy `PROJECT-BOUNDARY.md` to your agent-config root.
2. Fill in `DEP_CACHE`, `UI_SOURCE`, `TOOL_HOME`, layout names, and the authorised model provider.
3. Delete any row that does not apply — an empty value makes the rules **stop and report** instead of guessing.
4. For a single repository that deviates, add a project-local `PROJECT-BOUNDARY.md`; it wins over the machine file.

Worked examples: [`examples/`](examples/). The rule text contains no secrets, accounts, or private paths — those belong in your boundary file; keep it out of version control if it names internal hosts.

## License

MIT — see [LICENSE](LICENSE).
