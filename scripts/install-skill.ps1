<#
.SYNOPSIS
    Install the portable rule text and write this machine's answers into it.

.DESCRIPTION
    This script does not ask questions. The first-run interview belongs to the
    agent (skill section 0.2), which records the answers in the machine-config
    document; `export-boundary.ps1` turns that document into a boundary file, and
    this script installs it. Three steps, always in this order:

      1. copy      - skill/kalcirite-project-rules/ -> <Target>\kalcirite-project-rules
      2. place     - copy the boundary file into the installed skill directory,
                     byte for byte, so the file tools read is exactly the file
                     the exporter produced (no second renderer, no drift)
      3. write back- fill the 'kalcirite:local-profile' block inside the installed
                     SKILL.md, so agents without a host adapter still see the values

    Answers come from -FromBoundary, or from the boundary already installed in
    the target. There is no interactive mode on purpose.

    This script is ASCII-only on purpose: Windows PowerShell 5.1 misreads
    non-ASCII script files that have no BOM.

.PARAMETER Target
    Skill root the agent scans, e.g. <DSH_HOME>\skills or "$HOME\.claude\skills".

.PARAMETER Source
    This repository's skill directory. Defaults to ..\skill\kalcirite-project-rules.

.PARAMETER FromBoundary
    Boundary file to install (its 'kalcirite:answers' block supplies the local
    profile). Defaults to the boundary already installed in the target.

.PARAMETER Force
    Overwrite an installed boundary file that was not produced by the exporter.

.EXAMPLE
    & .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md

.EXAMPLE
    # reinstall the rule text over an existing install, reusing its boundary
    & .\scripts\sync-skill.ps1 -Target "$env:DSH_HOME\skills" -Force
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $Target,

    [string] $Source,

    [string] $FromBoundary,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$skillName    = 'kalcirite-project-rules'
$beginTag     = '<!-- kalcirite:local-profile:begin -->'
$endTag       = '<!-- kalcirite:local-profile:end -->'
$answersBegin = '<!-- kalcirite:answers:begin -->'
$answersEnd   = '<!-- kalcirite:answers:end -->'

# ---------------------------------------------------------------- helpers ----

function Read-Utf8([string] $Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Write-Utf8([string] $Path, [string] $Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function ConvertTo-OrderedAnswers($Object) {
    $h = [ordered]@{}
    foreach ($p in $Object.PSObject.Properties) { $h[$p.Name] = [string]$p.Value }
    return $h
}

function Get-AnswersFromBoundaryFile([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = Read-Utf8 $Path
    $block = [regex]::Match($text, '(?s)' + [regex]::Escape($answersBegin) + '(.*?)' + [regex]::Escape($answersEnd))
    if (-not $block.Success) { return $null }
    $json = [regex]::Match($block.Groups[1].Value, '(?s)```(?:json)?\s*(\{.*?\})\s*```')
    if (-not $json.Success) { return $null }
    try { return ConvertTo-OrderedAnswers ($json.Groups[1].Value | ConvertFrom-Json) }
    catch { return $null }
}

function Get-SkillVersion([string] $SkillMdPath) {
    if (-not (Test-Path -LiteralPath $SkillMdPath -PathType Leaf)) { return 'unknown' }
    $m = [regex]::Match((Read-Utf8 $SkillMdPath), '(?m)^\s*version:\s*"?([^"\r\n]+?)"?\s*$')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return 'unknown'
}

function Format-Cell([string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '_(blank - the rules stop and report)_' }
    return $Value.Replace('|', '\|')
}

# ------------------------------------------------------------ local block ----

function New-LocalProfileBlock($a, [string] $Stamp, [string] $BoundaryPath) {
    $rows = @(
        @('DEP_CACHE', $a['DEP_CACHE']),
        @('pnpm / npm / pip / cargo', (@($a['PNPM_STORE'], $a['NPM_CACHE'], $a['PIP_CACHE'], $a['CARGO_HOME']) -join ' | ')),
        @('UI_SOURCE', $a['UI_SOURCE']),
        @('UI_DEFAULT_VERSION', $a['UI_VERSION']),
        @('TOOL_HOME', $a['TOOL_HOME']),
        @('TOOL_VALIDATOR', $a['TOOL_VALIDATOR']),
        @('BUILD_ROOT / TMP / EVIDENCE', (@($a['BUILD_ROOT'], $a['TMP'], $a['EVIDENCE']) -join ' / ')),
        @('ROUTE_PROVIDER', $a['ROUTE_PROVIDER']),
        @('CHEAP_MODELS', $a['CHEAP_MODELS']),
        @('ROUTE_TOOL', $a['ROUTE_TOOL']),
        @('ROUTE_SELECTION_SUPPORTED', $a['ROUTE_SELECTION_SUPPORTED']),
        @('DELEGATION_TOOLS', $a['DELEGATION_TOOLS']),
        @('ROUTE_TAKES_EFFECT', $a['ROUTE_TAKES_EFFECT']),
        @('SHELL_NOTE', $a['SHELL_NOTE']),
        @('proxy / ports', (@($a['PROXY'], $a['PORTS']) -join ' ; ')),
        @('never delete', $a['NEVER_DELETE'])
    )

    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add($beginTag)
    [void]$lines.Add('## Local profile')
    [void]$lines.Add('')
    [void]$lines.Add("> Filled on $Stamp by ``install-skill.ps1``. Source of truth: the boundary file at")
    [void]$lines.Add("> ``$BoundaryPath`` (exported from this machine's config document) - edit there, not here.")
    [void]$lines.Add('> Machine-specific values only. Keep the rest of this file environment-neutral.')
    [void]$lines.Add('')
    [void]$lines.Add('| Key | Value |')
    [void]$lines.Add('|---|---|')
    foreach ($r in $rows) {
        $v = Format-Cell ([string]$r[1])
        [void]$lines.Add("| ``" + $r[0] + "`` | " + $v + ' |')
    }
    [void]$lines.Add('')
    [void]$lines.Add('> Any value reading `(unverified)` was recorded without an existence check.')
    [void]$lines.Add($endTag)
    return ($lines -join "`r`n")
}

function Set-LocalProfileBlock([string] $SkillMdPath, [string] $Block) {
    $text = Read-Utf8 $SkillMdPath
    $i = $text.IndexOf($beginTag)
    $j = $text.IndexOf($endTag)
    if ($i -ge 0 -and $j -gt $i) {
        $new = $text.Substring(0, $i) + $Block + $text.Substring($j + $endTag.Length)
    }
    else {
        # No markers (older copy): insert after the YAML frontmatter.
        $idx = -1
        if ($text.StartsWith('---')) {
            $idx = $text.IndexOf("`n---", 3)
            if ($idx -ge 0) { $idx = $text.IndexOf("`n", $idx + 1) }
        }
        if ($idx -lt 0) { $new = $Block + "`r`n`r`n" + $text }
        else { $new = $text.Substring(0, $idx + 1) + "`r`n" + $Block + "`r`n" + $text.Substring($idx + 1) }
    }
    Write-Utf8 $SkillMdPath $new
}

# ------------------------------------------------------------ main flow -----

if (-not $Source) { $Source = Join-Path (Split-Path -Parent $PSScriptRoot) "skill\$skillName" }
if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Source skill directory not found: $Source" }
if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) { throw "Source is not a skill (SKILL.md missing): $Source" }

$Target         = [System.IO.Path]::GetFullPath($Target)
$dest           = Join-Path $Target $skillName
$skillMd        = Join-Path $dest 'SKILL.md'
$boundaryOut    = Join-Path $dest 'PROJECT-BOUNDARY.md'
$legacyBoundary = Join-Path $Target 'PROJECT-BOUNDARY.md'

# 1. locate the answers ------------------------------------------------------
$boundarySource = ''
if ($FromBoundary) {
    if (-not (Test-Path -LiteralPath $FromBoundary -PathType Leaf)) { throw "Boundary file not found: $FromBoundary" }
    $boundarySource = (Resolve-Path -LiteralPath $FromBoundary).Path
}
else {
    foreach ($candidate in @($boundaryOut, $legacyBoundary)) {
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and (Get-AnswersFromBoundaryFile $candidate)) {
            $boundarySource = $candidate
            break
        }
    }
    if (-not $boundarySource) {
        throw @"
No boundary file to install from.

Run the first-run interview from the rule text (section 0.2), write the answers
into this machine's config document, then export and install:

  1. <config doc>   | `KEY` | value | ...   (see boundary/MACHINE-CONFIG.template.md)
  2. & .\scripts\export-boundary.ps1 -Source <config doc> -Out <boundary file>
  3. & .\scripts\install-skill.ps1 -Target "$Target" -FromBoundary <boundary file>
"@
    }
}

$answers = Get-AnswersFromBoundaryFile $boundarySource
if (-not $answers) {
    throw "No kalcirite:answers block in $boundarySource. Export it first: .\scripts\export-boundary.ps1 -Source <config doc> -Out $boundarySource"
}
if ($answers['DEP_CACHE'] -is [string] -and [string]::IsNullOrWhiteSpace($answers['DEP_CACHE'])) {
    throw "DEP_CACHE is empty in ${boundarySource}: the dependency rule would have nothing to resolve."
}

$boundaryText = Read-Utf8 $boundarySource
if ($boundaryText -match '@[A-Z][A-Z0-9_]*@' -or $boundaryText -match '<PLACEHOLDER>') {
    throw "Boundary file still holds unresolved placeholders: $boundarySource"
}
# An unedited template exports cleanly (every row is present), so the placeholder
# test has to happen on the values: `<...>` is what the template ships with.
$unresolved = @($answers.Keys | Where-Object { ([string]$answers[$_]).Trim() -match '^<.*>$' })
if ($unresolved.Count -gt 0) {
    throw ("Boundary still holds template placeholders (values are literally <...>): " + ($unresolved -join ', ') + "  ($boundarySource)")
}

$stamp   = (Get-Date).ToString('yyyy-MM-dd HH:mm')
$version = Get-SkillVersion (Join-Path $Source 'SKILL.md')

Write-Host "answers from    -> $boundarySource"
Write-Host "rule text       -> $Source (version $version)"

# 2. install the rule text ---------------------------------------------------
$hadBoundary = Test-Path -LiteralPath $boundaryOut -PathType Leaf
$handWritten = $false
if ($hadBoundary -and -not (Get-AnswersFromBoundaryFile $boundaryOut)) { $handWritten = $true }
if ($handWritten -and -not $Force) {
    throw "Boundary file was hand-written, refusing to overwrite: $boundaryOut  (re-run with -Force)"
}

# The install step below replaces the skill directory wholesale, and the machine
# boundary lives INSIDE that directory. Snapshot it before the removal, or the
# backup copy below has no source left to copy from.
$priorBoundaryText = $null
if ($hadBoundary) { $priorBoundaryText = Read-Utf8 $boundaryOut }

if ($PSCmdlet.ShouldProcess($dest, 'Install rule text')) {
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path (Join-Path $Source '*') -Destination $dest -Recurse -Force
    Write-Host "installed skill -> $skillMd"
}

# 3. place the boundary and write the profile block back ---------------------
if ($PSCmdlet.ShouldProcess($boundaryOut, 'Place machine boundary file')) {
    if ($priorBoundaryText -and -not (Test-Path -LiteralPath ($boundaryOut + '.bak'))) {
        Write-Utf8 ($boundaryOut + '.bak') $priorBoundaryText
    }
    Write-Utf8 $boundaryOut $boundaryText
    if (-not (Test-Path -LiteralPath $boundaryOut -PathType Leaf)) {
        throw "boundary write-back failed, the install would be incomplete: $boundaryOut"
    }
    Write-Host "placed boundary -> $boundaryOut"
}

if ($PSCmdlet.ShouldProcess($skillMd, 'Fill the local profile block')) {
    Set-LocalProfileBlock $skillMd (New-LocalProfileBlock $answers $stamp $boundaryOut)
    Write-Host "filled profile  -> $skillMd"
}

if (Test-Path -LiteralPath $legacyBoundary -PathType Leaf) {
    Write-Host ''
    Write-Host "note: an older boundary still exists at $legacyBoundary"
    Write-Host '      the skill now reads the copy inside its own directory; the old file is left untouched'
}

Write-Host @"

next steps
  1. review the boundary file:        $boundaryOut
  2. reload / restart the agent so the skill catalog picks the directory up
  3. per project, add <project>\PROJECT-BOUNDARY.md only where values differ
  4. later rule-text updates:         sync-skill.ps1 -Target <same root> -Force
"@
