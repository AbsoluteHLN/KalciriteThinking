<#
.SYNOPSIS
    Update the rule text in an agent's skill directory, preserving the recorded
    machine answers, and report what version changed.

.DESCRIPTION
    Copies skill/kalcirite-project-rules/ (SKILL.md plus reference/) over
    <Target>\kalcirite-project-rules\, then restores the 'kalcirite:local-profile'
    block and keeps the boundary file that lives beside the installed SKILL.md.

    It prints the rule-text version before and after, so an update is visible in
    the transcript rather than assumed. Version history: CHANGELOG.md.

    Use this for rule-text updates. Machine values are NOT touched: to change
    paths, providers, or ports, edit the machine-config document, re-export with
    export-boundary.ps1, and install with install-skill.ps1.

    This script is ASCII-only on purpose: Windows PowerShell 5.1 misreads
    non-ASCII script files that have no BOM.

.PARAMETER Target
    Skill root the agent scans, e.g. D:\Cetus\dshconfig\skills or "$HOME\.claude\skills".

.PARAMETER Source
    This repository's skill directory. Defaults to ..\skill\kalcirite-project-rules.

.PARAMETER BoundaryPath
    Optional boundary file to install beside the skill. An existing boundary file
    is never overwritten by this script.

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

function Get-SkillVersion([string] $SkillMdPath) {
    if (-not (Test-Path -LiteralPath $SkillMdPath -PathType Leaf)) { return '' }
    $m = [regex]::Match((Read-Utf8 $SkillMdPath), '(?m)^\s*version:\s*"?([^"\r\n]+?)"?\s*$')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ''
}

function Count-Files([string] $Dir) {
    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return 0 }
    return @(Get-ChildItem -LiteralPath $Dir -Recurse -File).Count
}

if (-not $Source) {
    $Source = Join-Path (Split-Path -Parent $PSScriptRoot) "skill\$skillName"
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

# ------------------------------------------------------- before the change ---

$priorBlock    = Get-ProfileBlock $skillMd
$boundaryDest  = Join-Path $dest 'PROJECT-BOUNDARY.md'
$legacyBoundary = Join-Path $Target 'PROJECT-BOUNDARY.md'
$priorVersion  = Get-SkillVersion $skillMd
$newVersion    = Get-SkillVersion (Join-Path $Source 'SKILL.md')
$priorCount    = Count-Files $dest
$newCount      = Count-Files $Source

# The destination directory is replaced wholesale, so read the machine values out
# first: the in-skill boundary, otherwise a legacy boundary one level up.
$priorBoundary = $null
if (Test-Path -LiteralPath $boundaryDest -PathType Leaf) { $priorBoundary = Read-Utf8 $boundaryDest }
elseif (Test-Path -LiteralPath $legacyBoundary -PathType Leaf) { $priorBoundary = Read-Utf8 $legacyBoundary }

if (-not (Test-Path -LiteralPath $dest)) {
    Write-Host "rule text       -> new install (no existing skill at $dest)"
}
elseif ($priorVersion -eq '' -or $newVersion -eq '') {
    Write-Host "rule text       -> version unknown ($priorCount -> $newCount files)"
}
elseif ($priorVersion -eq $newVersion) {
    Write-Host "rule text       -> version $newVersion (unchanged; files $priorCount -> $newCount)"
}
else {
    Write-Host "rule text       -> version $priorVersion -> $newVersion  (see CHANGELOG.md)"
}

# ---------------------------------------------------------------- install ----

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

# --------------------------------------------------------- after the change --

if (-not $WhatIfPreference -and (Test-Path -LiteralPath $skillMd)) {
    $installedVersion = Get-SkillVersion $skillMd
    if ($newVersion -ne '' -and $installedVersion -ne $newVersion) {
        throw "installed SKILL.md reports version '$installedVersion' but the source says '$newVersion': the copy did not land"
    }
    $block = Get-ProfileBlock $skillMd
    if (-not $block) { Write-Host 'warning: installed SKILL.md has no local-profile block: the gate will fire' }
    elseif ($block -match 'UNRESOLVED') {
        Write-Host 'warning: local profile says UNRESOLVED; run install-skill.ps1 before doing any work'
    }
    if (-not (Test-Path -LiteralPath $boundaryDest -PathType Leaf)) {
        Write-Host 'warning: no boundary file beside the installed SKILL.md'
        Write-Host "         fix with: install-skill.ps1 -Target `"$Target`" -FromBoundary <exported PROJECT-BOUNDARY.md>"
    }
}

Write-Host @"

next steps
  1. boundary file (machine values): $dest\PROJECT-BOUNDARY.md
     missing or stale? edit the machine-config document, re-export it, then
     run install-skill.ps1 -Target "$Target" -FromBoundary <exported file>
  2. reload the agent so the skill catalog picks the update up
"@
