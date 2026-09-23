<#
.SYNOPSIS
    Update the rule text in an agent's skill directory, preserving the recorded
    machine answers.

.DESCRIPTION
    Copies skills/kalcirite-project-rules/ (SKILL.md plus any resources) over
    <Target>\kalcirite-project-rules\, then restores the 'kalcirite:local-profile'
    block and keeps the boundary file that lives beside the installed SKILL.md.

    Use this for rule-text updates. Use install-skill.ps1 for the first install
    and whenever the machine's paths or details change: that is the script that
    asks the questions (including the sub-agent / model-selection ones) and writes
    the answers back.

.PARAMETER Target
    Skill root the agent scans, e.g. D:\Cetus\dshconfig\skills or "$HOME\.claude\skills".

.PARAMETER Source
    This repository's skill directory. Defaults to ..\skills\kalcirite-project-rules.

.PARAMETER BoundaryPath
    Optional boundary file to install beside the skill (first install only; an
    existing boundary file is never overwritten).

.PARAMETER Force
    Required to overwrite an existing installation when -WhatIf is not used.

.EXAMPLE
    & .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force

.EXAMPLE
    & .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -WhatIf
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
$beginTag  = '<!-- kalcirite:local-profile:begin -->'
$endTag    = '<!-- kalcirite:local-profile:end -->'

function Read-Utf8([string] $Path) { return [System.IO.File]::ReadAllText($Path) }

function Write-Utf8([string] $Path, [string] $Text) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Get-ProfileBlock([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $t = Read-Utf8 $Path
    $i = $t.IndexOf($beginTag)
    $j = $t.IndexOf($endTag)
    if ($i -ge 0 -and $j -gt $i) { return $t.Substring($i, $j - $i + $endTag.Length) }
    return $null
}

function Set-ProfileBlock([string] $Path, [string] $Block) {
    $t = Read-Utf8 $Path
    $i = $t.IndexOf($beginTag)
    $j = $t.IndexOf($endTag)
    if ($i -ge 0 -and $j -gt $i) {
        Write-Utf8 $Path ($t.Substring(0, $i) + $Block + $t.Substring($j + $endTag.Length))
        return $true
    }
    return $false
}

if (-not $Source) {
    $Source = Join-Path (Split-Path -Parent $PSScriptRoot) "skills\$skillName"
}

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Source skill directory not found: $Source"
}
if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) {
    throw "Source does not look like a skill (SKILL.md missing): $Source"
}

$Target  = [System.IO.Path]::GetFullPath($Target)
$dest    = Join-Path $Target $skillName
$skillMd = Join-Path $dest 'SKILL.md'

if ((Test-Path -LiteralPath $dest) -and -not $Force -and -not $WhatIfPreference) {
    throw "Destination already exists: $dest  (re-run with -Force to overwrite, or -WhatIf to preview)"
}

$priorBlock    = Get-ProfileBlock $skillMd
$boundaryDest  = Join-Path $dest 'PROJECT-BOUNDARY.md'
$legacyBoundary = Join-Path $Target 'PROJECT-BOUNDARY.md'
# The destination directory is replaced wholesale, so read the machine values out
# first: the in-skill boundary, otherwise a legacy boundary one level up.
$priorBoundary = $null
if (Test-Path -LiteralPath $boundaryDest -PathType Leaf) { $priorBoundary = Read-Utf8 $boundaryDest }
elseif (Test-Path -LiteralPath $legacyBoundary -PathType Leaf) { $priorBoundary = Read-Utf8 $legacyBoundary }

if ($PSCmdlet.ShouldProcess($dest, 'Copy skill')) {
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path (Join-Path $Source '*') -Destination $dest -Recurse -Force
    Write-Host "installed skill -> $skillMd"

    if ($priorBlock) {
        if (Set-ProfileBlock $skillMd $priorBlock) {
            Write-Host 'restored local profile block (machine answers kept)'
        }
        else {
            Write-Host 'note: the new SKILL.md has no local-profile markers; answers were not restored'
        }
    }

    if ($priorBoundary -and -not (Test-Path -LiteralPath $boundaryDest)) {
        Write-Utf8 $boundaryDest $priorBoundary
        Write-Host "restored boundary -> $boundaryDest"
    }
}

if ($BoundaryPath) {
    if (-not (Test-Path -LiteralPath $BoundaryPath -PathType Leaf)) {
        throw "Boundary file not found: $BoundaryPath"
    }
    if (Test-Path -LiteralPath $boundaryDest) {
        Write-Host "kept existing boundary -> $boundaryDest"
    }
    elseif ($PSCmdlet.ShouldProcess($boundaryDest, 'Install boundary file')) {
        Copy-Item -LiteralPath $BoundaryPath -Destination $boundaryDest -Force
        Write-Host "installed boundary -> $boundaryDest"
    }
}

Write-Host @"

next steps
  1. boundary file (machine values): $dest\PROJECT-BOUNDARY.md
     missing or stale? run install-skill.ps1 -Target "$Target" -Reconfigure
  2. reload the agent so the skill catalog picks the update up
"@
