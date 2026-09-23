<#
.SYNOPSIS
    Copy the portable rule text into an agent's skill directory and optionally
    install a boundary file.

.DESCRIPTION
    Copies skills/kalcirite-project-rules/ (SKILL.md plus any resources) into
    <Target>/kalcirite-project-rules/, overwriting an existing installation.

    The rule text references ../PROJECT-BOUNDARY.md, so a boundary file should
    exist one level above the installed skill directory:
      - BoundaryPath installs to <Target>\..\PROJECT-BOUNDARY.md  (default layout)
      - -BoundaryPath <file> installs that file to <Target>\..\PROJECT-BOUNDARY.md

    Nothing is executed; the script only copies files.

.PARAMETER Target
    Skill root the agent scans, e.g. D:\Cetus\dshconfig\skills or ~/.claude/skills.

.PARAMETER Source
    This repository's skills directory. Defaults to ..\skills relative to the script.

.PARAMETER BoundaryPath
    Optional boundary file to install one level above the skill root.

.PARAMETER Force
    Required to overwrite an existing installation when -WhatIf is not used.

.EXAMPLE
    pwsh -File scripts/sync-skill.ps1 -Target "$env:DSH_HOME\skills"

.EXAMPLE
    pwsh -File scripts/sync-skill.ps1 -Target "$HOME\.claude\skills" `
        -BoundaryPath .\my-machine-PROJECT-BOUNDARY.md -Force
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $Target,

    [string] $Source,

    [string] $BoundaryPath,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$skillName = 'kalcirite-project-rules'
if (-not $Source) {
    $Source = Join-Path (Split-Path -Parent $PSScriptRoot) "skills\$skillName"
}

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Source skill directory not found: $Source"
}
if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) {
    throw "Source does not look like a skill (SKILL.md missing): $Source"
}

$Target = [System.IO.Path]::GetFullPath($Target)
$dest = Join-Path $Target $skillName

if ((Test-Path -LiteralPath $dest) -and -not $Force -and -not $WhatIfPreference) {
    throw "Destination already exists: $dest  (re-run with -Force to overwrite, or -WhatIf to preview)"
}

if ($PSCmdlet.ShouldProcess($dest, 'Copy skill')) {
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
    Write-Host "installed skill -> $dest"
}

if ($BoundaryPath) {
    if (-not (Test-Path -LiteralPath $BoundaryPath -PathType Leaf)) {
        throw "Boundary file not found: $BoundaryPath"
    }
    $boundaryDest = Join-Path (Split-Path -Parent $Target) 'PROJECT-BOUNDARY.md'
    if (Test-Path -LiteralPath $boundaryDest) {
        # Never clobber a live boundary file: it holds machine-specific values.
        Write-Host "kept existing boundary -> $boundaryDest"
    }
    elseif ($PSCmdlet.ShouldProcess($boundaryDest, 'Install boundary file')) {
        Copy-Item -LiteralPath $BoundaryPath -Destination $boundaryDest -Force
        Write-Host "installed boundary -> $boundaryDest"
    }
}

Write-Host @"

next steps
  1. ensure a boundary file exists at: $(Join-Path (Split-Path -Parent $Target) 'PROJECT-BOUNDARY.md')
  2. fill in DEP_CACHE / UI_SOURCE / TOOL_HOME / layout names / model provider
  3. reload the agent so the skill catalog picks the new directory up
"@
