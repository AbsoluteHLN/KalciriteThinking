# KalciriteThinking

**Portable engineering discipline for agents working across many repositories on one machine.**

[中文说明](README.zh.md) · [Rule text](skills/kalcirite-project-rules/SKILL.md) · [Boundary template](PROJECT-BOUNDARY.md)

---

## The problem

When several repositories share one machine, the usual agent failure modes are structural, not intellectual:

- every project re-downloads its own dependency tree, and a "helpful" cleanup destroys the shared cache through a junction;
- each UI reset invents a new colour palette instead of using the canonical design system;
- a plugin is half-rebuilt inside a consuming project because nobody looked in the shared catalogue;
- build output, scratch files, and documentation scatter across the repository root;
- verification is interleaved with editing, so time and tokens vanish in re-check loops;
- work that only needed reading is done on an expensive model;
- a delegation arrives without context, so the child re-derives everything — or fabricates it.

KalciriteThinking writes down the boundaries that prevent those outcomes, in a form **any agent** can load: no vendor lock-in, no IDE-specific features, no hidden state.

## What it contains

| Layer | File | Purpose |
|---|---|---|
| Rules (portable) | [`skills/kalcirite-project-rules/SKILL.md`](skills/kalcirite-project-rules/SKILL.md) | The discipline itself: 10 sections, environment-neutral |
| Boundary (machine-specific) | [`PROJECT-BOUNDARY.md`](PROJECT-BOUNDARY.md) | Cache paths, UI source, tool catalogue, layout names, routing provider |
| Config examples | [`examples/`](examples/) | Boundary files for DSH / Claude-style skill roots and a project-local override |
| Sync helper | [`scripts/sync-skill.ps1`](scripts/sync-skill.ps1) | Copy the rule text into any agent's skill directory |

## The ten principles

1. **Build first, verify once.** Complete the change, build it, then run one central verification pass.
2. **Route by reasoning depth, not by task size.** Cheap models read; strong models judge. Discover routes, never guess names, never leave the authorised provider.
3. **One dependency cache.** Everything installs into a single machine-level cache and is linked in. No project-local dependency payloads, ever.
4. **One canonical UI source.** Integrate it and follow its contract; project CSS carries layout only, never colour.
5. **Reuse before rebuild.** Search the shared catalogue; if it is missing, build it *inside* the catalogue on the existing boundaries.
6. **One clean layout.** `src/ docs/ dev-docs/ verify-evidence/ cxbuild/ temp/`. One build-output root, one scratch root.
7. **Archive on change.** Superseded files are archived or deleted with a checklist — not left on the main path.
8. **Self-contained handoff.** Absolute paths, explicit write scope, stated return format.
9. **Evidence-gated claims.** Verified / attempted / not attempted are three different words.
10. **Facts are checked, not remembered.** Paths, ports, versions: measure first.

## Install

### A. As an agent skill (recommended)

Copy `skills/kalcirite-project-rules/` into the skill root your agent scans, then place a filled `PROJECT-BOUNDARY.md` where the agent can read it (machine config root or repository root).

```powershell
# DSH (DeepSeek Harness): user skill root
pwsh -File scripts/sync-skill.ps1 -Target "$env:DSH_HOME\skills"
# Claude-Code-style skill root
pwsh -File scripts/sync-skill.ps1 -Target "$HOME\.claude\skills"
# Any other agent: point -Target at its skill directory
```

The rule text uses relative links (`../PROJECT-BOUNDARY.md`), so it keeps working from any target directory.

### B. As a repository instruction file

Append the rule sections you need to `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or your agent's instruction file, and keep only the machine values in a boundary file. The rule text is plain Markdown with no tool-specific syntax.

### C. As a human checklist

Read [`skills/kalcirite-project-rules/SKILL.md`](skills/kalcirite-project-rules/SKILL.md) directly — it is written to be useful to people reviewing a repository as well.

## Configure

1. Copy `PROJECT-BOUNDARY.md` to your agent-config root.
2. Fill in `DEP_CACHE`, `UI_SOURCE`, `TOOL_HOME`, layout names, and the authorised model provider.
3. Delete any row that does not apply to your machine — an empty value makes the rules **stop and report** instead of guessing.
4. For a single repository that deviates, add a project-local `PROJECT-BOUNDARY.md`; it wins over the machine file.

Worked examples: [`examples/`](examples/).

## Scope and safety

- The rule text contains **no secrets, accounts, or private paths** — those belong in your boundary file, which you should keep out of version control if it names internal hosts.
- Nothing here executes on install; the sync helper only copies files.
- Everything is Markdown and PowerShell — review it before you trust it.

## License

MIT — see [LICENSE](LICENSE).
