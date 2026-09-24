# scripts

Three steps, in this order. **Only the first is hand-edited** — the boundary file is a
derivative, and `install-skill.ps1` does not generate values at all.

| Step | Script | Purpose |
|---|---|---|
| 1. edit | — | the machine-config document ([`../boundary/MACHINE-CONFIG.template.md`](../boundary/MACHINE-CONFIG.template.md)): one section per domain, rows shaped `` | `KEY` | value | commentary | `` |
| 2. export | `export-boundary.ps1` | rebuilds the tool-facing `PROJECT-BOUNDARY.md` from that document: keeps its `##` headings, drops the commentary column, appends the `kalcirite:answers` JSON block |
| 3. install | `install-skill.ps1` | copies the rule text into `<Target>\kalcirite-project-rules\`, copies the exported boundary file in **verbatim**, fills the `kalcirite:local-profile` block |
| — | `sync-skill.ps1` | rule-text updates only: copies the rule text, restores the profile block and the existing boundary file, prints the version delta |

## First install

```powershell
# 1. copy the template out of the repo and fill it in (keep it out of the repo)
Copy-Item .\boundary\MACHINE-CONFIG.template.md ..\MACHINE-CONFIG.md

# 2. export
& .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.md -Out ..\PROJECT-BOUNDARY.md

# 3. install
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills" -FromBoundary ..\PROJECT-BOUNDARY.md

# preview without writing
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md -WhatIf
```

Parameters: `-Target` (required), `-Source`, `-FromBoundary`, `-Force`, `-WhatIf`.

Behaviour worth knowing:

- **No `-FromBoundary` and no boundary already installed → it stops** and prints the three
  commands. There is no interactive mode; the interview belongs to the agent (rule text §0.2).
- Every row is present in an unedited template, so a copied-but-unfilled document exports
  cleanly. The installer therefore rejects any value that is literally `<...>`, and refuses an
  empty `DEP_CACHE` outright.
- `none` / blank is a valid answer: it means "no assumption", and the rules stop and report for
  that domain instead of guessing.
- A hand-written boundary file (one without the `kalcirite:answers` block) is never overwritten
  without `-Force`; a generated one gets a `.bak` copy first.
- The skill directory is managed: the script replaces it wholesale, so keep local edits to
  `SKILL.md` out of it. If a legacy boundary sits one level up in `<Target>`, it is left
  untouched and reported.

## Update the rule text only

```powershell
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -WhatIf     # preview
```

Prints `version 3.0 -> 3.1 (see CHANGELOG.md)` and, afterwards, refuses to report success if the
installed `SKILL.md` does not carry the source version. Parameters: `-Target` (required),
`-Source`, `-BoundaryPath` (an existing boundary is never overwritten), `-Force`, `-WhatIf`.

## Changing a machine value

Edit the machine-config document, re-export, then install again — never edit
`PROJECT-BOUNDARY.md`, and never edit the values inside `SKILL.md`:

```powershell
& .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.md -Out ..\PROJECT-BOUNDARY.md
& .\scripts\install-skill.ps1   -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
```

## Notes

- All three scripts work in Windows PowerShell 5.1 and PowerShell 7+ (`pwsh` is optional; when it
  is on `PATH`, `pwsh -File scripts\<name>.ps1 …` is equivalent).
- All three are deliberately **ASCII-only**: Windows PowerShell 5.1 misreads non-ASCII script
  files that have no BOM.
- The question bank lives in the skill, not here:
  [`../skill/kalcirite-project-rules/reference/interview.md`](../skill/kalcirite-project-rules/reference/interview.md).
  [`../boundary/QUESTIONS.md`](../boundary/QUESTIONS.md) explains why each answer must reach disk.
- The scripts copy and generate files; they execute nothing from the repository.
