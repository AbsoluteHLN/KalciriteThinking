# KalciriteThinking

**Portable engineering discipline for agents working across many repositories on one machine.**

[中文](README.md) · [Rule text](skills/kalcirite-project-rules/SKILL.md) · [Boundary template](boundary/PROJECT-BOUNDARY.template.md)

## Disclaimer

This is my first real attempt at formalising a discipline like this. It is not guaranteed to fit your workflow — treat it as reference material only.

## Two layers

| Layer | Directory | Contents | Shareable as-is |
|---|---|---|---|
| **Portable** | [`skills/`](skills/) [`boundary/`](boundary/) [`scripts/`](scripts/) [`examples/`](examples/) | Rule text, boundary template and question bank, installer, examples | Yes — no private paths |
| **Local** | [`local/`](local/) | One machine's real boundary values and project-specific facts | **No** — reference only |

The local layer is *a filled-in answer sheet*, not part of the rules. Others take the portable layer and generate their own with the installer.

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

## Install: it interviews you, then writes back

The rule text hard-codes no paths. Installing therefore **asks for this machine's details first** and writes the answers back into your local copy — that is what keeps the rules intelligent: stop and ask rather than guess.

```powershell
# First install: interview -> copy the rules -> write back the boundary and local profile
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills"
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills"       # Claude-style root
# Any other agent: point -Target at its skill directory

# Machine changed: ask again
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -Reconfigure

# Rule text only (keeps your answers)
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

Six groups of questions:

1. **The one dependency cache** — where it lives and how its subdirectories are split.
2. **The canonical UI source** — path, default version, preview source (`none` if absent).
3. **The shared tool/plugin catalogue** — where it lives.
4. **Project layout names** (`src` / `docs` / `dev-docs` / `verify-evidence` / `cxbuild` / `temp`).
5. **Cost-tiered model routing** — the authorised provider and each tier's model.
6. **Sub-agents and model selection** — which host agent this is, which delegation tools it exposes, whether a child may be given a model, where the switch lives, when it takes effect, and the concurrency cap.

The question bank is in [`boundary/QUESTIONS.md`](boundary/QUESTIONS.md); the sub-agent / model-selection details are in [`boundary/DELEGATION.md`](boundary/DELEGATION.md).

Answers land in two places: `PROJECT-BOUNDARY.md` inside the skill directory (nearest-hit resolution, §0.1 rule 2) and the `local-profile` block inside the installed `SKILL.md`. **Blank is a valid answer** meaning "no assumption" — the rules stop and report instead of guessing. A per-project `<project>/PROJECT-BOUNDARY.md` wins over both.

The scripts run on Windows PowerShell 5.1 and PowerShell 7+, copy files only, and execute nothing. See [`scripts/README.md`](scripts/README.md) and [`examples/`](examples/).

## Other ways to use it

- **As a repository instruction file**: append the sections you need to `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`.
- **As a human checklist**: read `SKILL.md` directly.

The rule text contains no secrets, accounts, or private paths; keep your boundary file out of version control if it names internal hosts.

## License

MIT — see [LICENSE](LICENSE).
