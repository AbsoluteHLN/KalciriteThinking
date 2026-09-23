# scripts

| Script | Purpose |
|---|---|
| `sync-skill.ps1` | Copy `skills/kalcirite-project-rules/` into an agent's skill root, and install a boundary file beside the skill (`<Target>\PROJECT-BOUNDARY.md`) **only if none exists** (an existing boundary is never overwritten — it holds hand-filled machine values). |

## Usage

```powershell
# preview
pwsh -File scripts/sync-skill.ps1 -Target "$env:DSH_HOME\skills" -WhatIf

# install the skill + template boundary (skips an existing boundary)
pwsh -File scripts/sync-skill.ps1 -Target "$env:DSH_HOME\skills" -BoundaryPath ..\PROJECT-BOUNDARY.md

# overwrite an existing installation after editing the rule text
pwsh -File scripts/sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
```

Parameters: `-Target` (required, skill root), `-Source` (defaults to `..\skills\kalcirite-project-rules`),
`-BoundaryPath` (optional), `-Force`, `-WhatIf`.

The script copies files only; it executes nothing from the repository.
