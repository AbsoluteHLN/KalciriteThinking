<#
.SYNOPSIS
    Export the tool-facing boundary file from the human machine-config document.

.DESCRIPTION
    One document, one editor. The machine-config document (MACHINE-CONFIG.md or a
    per-machine variant) is the only hand-edited home for a machine's values.
    PROJECT-BOUNDARY.md is a derivative that tools read: the skill's section 0.1
    resolution order, `install-skill.ps1 -FromBoundary`, and any host adapter.

    This script rebuilds the boundary from the document, so the two cannot drift.
    It keeps the document's own section headings and rewrites every row shaped:

        | `SOME_KEY` | the value | optional human commentary |

    as a two-column row. The third cell is dropped on purpose - use it for notes,
    never for values. Prose, file lists and examples are ignored automatically, so
    a document can stay readable without leaking decoration into machine values.

.PARAMETER Source
    Machine-config document. Defaults to .\MACHINE-CONFIG.md.

.PARAMETER Out
    Boundary file to write. Defaults to .\PROJECT-BOUNDARY.md.

.PARAMETER Require
    Keys that must have a row. A key is present with an empty value only when the
    machine genuinely has no assumption for it, so a missing row is an oversight.

.EXAMPLE
    & .\scripts\export-boundary.ps1 -Source ..\MACHINE-CONFIG.zh.md -Out ..\PROJECT-BOUNDARY.md

.EXAMPLE
    # then install it
    & .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary ..\PROJECT-BOUNDARY.md
#>
[CmdletBinding()]
param(
    [string] $Source,

    [string] $Out,

    [string[]] $Require
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Source)) { $Source = Join-Path (Get-Location).Path 'MACHINE-CONFIG.md' }
if ([string]::IsNullOrWhiteSpace($Out))    { $Out    = Join-Path (Get-Location).Path 'PROJECT-BOUNDARY.md' }
if (-not $Require -or $Require.Count -eq 0) {
    $Require = @('DEP_CACHE', 'BUILD_ROOT', 'TMP', 'EVIDENCE', 'DOCS', 'DEV_DOCS', 'UI_SOURCE', 'TOOL_HOME', 'HOST_AGENT')
}

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "machine-config document not found: $Source"
}

$answersBegin = '<!-- kalcirite:answers:begin -->'
$answersEnd   = '<!-- kalcirite:answers:end -->'
$layoutKeys   = @('BUILD_ROOT', 'TMP', 'EVIDENCE', 'DOCS', 'DEV_DOCS', 'SRC')

# ------------------------------------------------------------------ parse ----

$doc = Get-Content -LiteralPath $Source -Raw -Encoding UTF8

# A row is one backticked ALL-CAPS key in the first cell and the value alone in
# the second. The pattern deliberately does not anchor the end of the line, so a
# third cell (commentary) may follow and is simply not captured.
$rowPattern = '^\|\s*`([A-Z][A-Z0-9_]*)`\s*\|\s*(.*?)\s*\|'
$headPattern = '^##\s+(.+?)\s*$'

$sections = New-Object System.Collections.Generic.List[object]
$answers  = [ordered]@{}
$order    = New-Object System.Collections.Generic.List[string]
$current  = $null

foreach ($line in ($doc -split "`r?`n")) {
    if ($line -match $headPattern) {
        $title = $matches[1]
        if ($title -notmatch 'collected answers|machine readable') {
            $current = [pscustomobject]@{ Title = $title; Keys = (New-Object System.Collections.Generic.List[string]) }
            $sections.Add($current)
        }
        else { $current = $null }
        continue
    }
    if ($line -match $rowPattern) {
        $key   = $matches[1]
        $value = $matches[2]
        if ($value -match '^`(.*)`$') { $value = $matches[1] }
        $value = $value.Trim()
        if (-not $answers.Contains($key)) { $order.Add($key) }
        $answers[$key] = $value
        if ($null -ne $current -and -not $current.Keys.Contains($key)) { $current.Keys.Add($key) }
    }
}

if ($answers.Count -eq 0) {
    throw "no key rows found in $Source (expected rows shaped: | ``KEY`` | value | ...)"
}

$missing = @($Require | Where-Object { -not $answers.Contains($_) })
if ($missing.Count -gt 0) {
    throw ("machine-config document is missing required keys: " + ($missing -join ', ') + "  ($Source)")
}

# ---------------------------------------------------------------- render -----

function Format-Cell([string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '_(blank - the rules stop and report)_' }
    return $Value.Replace('|', '\|')
}

$stamp      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$sourceName = Split-Path -Leaf $Source
$answers['GENERATED'] = "generated from $sourceName at $stamp by export-boundary.ps1"

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# PROJECT-BOUNDARY - machine boundary file')
$lines.Add('')
$lines.Add('> GENERATED - do not hand-edit. This file is a derivative of')
$lines.Add("> ``$sourceName``, rebuilt by ``export-boundary.ps1``.")
$lines.Add('> Edit the human document, then re-export; edits made here are lost.')
$lines.Add('>')
$lines.Add("> Generated $stamp.")
$lines.Add('>')
$lines.Add('> The rule text beside this file stays environment-neutral and resolves values')
$lines.Add('> through its section 0.1 order: project root -> this skill directory -> agent')
$lines.Add('> config root -> local profile. Blank means "no assumption": the rules stop and')
$lines.Add('> report rather than guess.')
$lines.Add('')

$presentLayout = @($layoutKeys | Where-Object { $answers.Contains($_) })
if ($presentLayout.Count -gt 0) {
    $lines.Add('## Layout contract')
    $lines.Add('')
    $lines.Add('| Key | Value |')
    $lines.Add('|---|---|')
    foreach ($key in $presentLayout) {
        $lines.Add('| `' + $key + '` | ' + (Format-Cell ([string]$answers[$key])) + ' |')
    }
    $lines.Add('')
    $lines.Add('The accepted top-level name set comes from the host adapter (built-in list')
    $lines.Add('plus these segments plus `EXTRA_TOP_LEVEL` plus its configured extras), not')
    $lines.Add('from this file.')
    $lines.Add('')
}

foreach ($section in $sections) {
    $present = @($section.Keys | Where-Object { $_ -ne 'GENERATED' })
    if ($present.Count -eq 0) { continue }
    $lines.Add('## ' + $section.Title)
    $lines.Add('')
    $lines.Add('| Key | Value |')
    $lines.Add('|---|---|')
    foreach ($key in $present) {
        $lines.Add('| `' + $key + '` | ' + (Format-Cell ([string]$answers[$key])) + ' |')
    }
    $lines.Add('')
}

$lines.Add('## Collected answers (machine readable)')
$lines.Add('')
$lines.Add('Read back by `install-skill.ps1 -FromBoundary <this file>` and by host adapters.')
$lines.Add('')
$lines.Add($answersBegin)
$lines.Add('```json')
$lines.Add(($answers | ConvertTo-Json -Depth 3))
$lines.Add('```')
$lines.Add($answersEnd)
$lines.Add('')

$text = ($lines -join "`r`n")

# ----------------------------------------------------------------- write -----

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Out, $text, $encoding)

if (-not (Test-Path -LiteralPath $Out -PathType Leaf)) {
    throw "export failed, nothing was written: $Out"
}

$bytes  = [System.IO.File]::ReadAllBytes($Out)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)

Write-Host ("exported {0} answers -> {1}" -f $answers.Count, $Out)
Write-Host ("sections: {0}" -f (($sections | Where-Object { $_.Keys.Count -gt 0 } | ForEach-Object { $_.Title }) -join ' | '))
Write-Host ("keys: {0}" -f ($order -join ' '))
Write-Host ("utf8 without BOM: {0}" -f (-not $hasBom))
