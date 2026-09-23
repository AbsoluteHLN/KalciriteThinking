# scripts

| Script | Purpose |
|---|---|
| `install-skill.ps1` | **Guided install.** Interviews the user for the machine paths and details (including the sub-agent / model-selection facts), copies the rule text, then writes the answers back into `<skill dir>\PROJECT-BOUNDARY.md` and into the `kalcirite:local-profile` block of the installed `SKILL.md`. |
| `sync-skill.ps1` | **Rule-text update.** Copies the rule text over an existing installation and restores the local-profile block, so machine answers survive. Never asks questions, never rewrites the boundary file. |

## Install (first time, or when the machine changes)

```powershell
# interview + install + write back
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills"
& .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills" -Reconfigure

# non-interactive: reuse answers recorded in an existing boundary file
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary .\local\PROJECT-BOUNDARY.md

# preview without writing
& .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -WhatIf
```

Parameters: `-Target` (required), `-Source`, `-FromBoundary` (read answers from a generated
boundary file), `-AnswerFile` (a `.psd1` hashtable), `-SkipInterview`, `-Reconfigure`, `-Force`,
`-WhatIf`.

Behaviour worth knowing:

- Every path answer is checked with `Test-Path` as it is recorded; a missing path is either
  created, written with `(unverified)`, or skipped through an explicit choice.
- `none` / blank is a valid answer: it means "no assumption", and the rules stop and report for
  that domain instead of guessing.
- Re-running without `-Reconfigure` reads the existing answers back and only refreshes the files.
- A hand-written boundary file (one without the `kalcirite:answers` block) is never overwritten
  without `-Force`; generated ones get a `.bak` copy first.
- The skill directory is managed: the script replaces it wholesale, so keep local edits to
  `SKILL.md` out of it.

## Update the rule text only

```powershell
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
& .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -WhatIf     # preview
```

Parameters: `-Target` (required), `-Source`, `-BoundaryPath` (first install only; an existing
boundary is never overwritten), `-Force`, `-WhatIf`.

## Notes

- Both scripts work in Windows PowerShell 5.1 and PowerShell 7+ (`pwsh` is optional; when it is
  on `PATH`, `pwsh -File scripts\<name>.ps1 …` is equivalent).
- Both are deliberately **ASCII-only**: Windows PowerShell 5.1 misreads non-ASCII script files
  that have no BOM. The questions themselves are documented, in Chinese, in
  [`../boundary/QUESTIONS.md`](../boundary/QUESTIONS.md) — the agent-side interview (rule text
  §0.2) asks the same set.
- The scripts copy files only; they execute nothing from the repository.
