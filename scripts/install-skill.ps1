<#
.SYNOPSIS
    Guided install: interview the user for machine paths and details, install the
    portable rule text, and write the answers back into the local installation.

.DESCRIPTION
    Three steps, always in this order:

      1. interview  - ask the boundary questions (see boundary/QUESTIONS.md), each
                      with a probed default; every path is checked as it is recorded
      2. install    - copy skills/kalcirite-project-rules/ into <Target>
      3. write back - generate <skill dir>\PROJECT-BOUNDARY.md and fill the
                      'kalcirite:local-profile' block inside the installed SKILL.md,
                      so the answers travel with the skill content itself

    Re-running is safe: existing answers are read back from the generated boundary
    file and reused unless -Reconfigure is given.

    This script is ASCII-only on purpose: Windows PowerShell 5.1 misreads non-ASCII
    script files that have no BOM. The questions themselves are documented in
    Chinese and English in boundary/QUESTIONS.md.

.PARAMETER Target
    Skill root the agent scans, e.g. D:\Cetus\dshconfig\skills or "$HOME\.claude\skills".

.PARAMETER Source
    This repository's skill directory. Defaults to ..\skills\kalcirite-project-rules.

.PARAMETER FromBoundary
    Read answers from an existing generated boundary file (its 'kalcirite:answers'
    block) instead of interviewing. Use it to reinstall the same machine profile.

.PARAMETER AnswerFile
    Read answers from a .psd1 file containing a hashtable.

.PARAMETER SkipInterview
    Never prompt. Answers must come from -AnswerFile, -FromBoundary, or an
    already-installed boundary file.

.PARAMETER Reconfigure
    Interview again even though answers already exist.

.PARAMETER Force
    Overwrite a boundary file that this script did not generate.

.EXAMPLE
    & .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills"

.EXAMPLE
    # non-interactive, reuse this machine's recorded profile
    & .\scripts\install-skill.ps1 -Target "$env:DSH_HOME\skills" -FromBoundary .\local\PROJECT-BOUNDARY.md

.EXAMPLE
    & .\scripts\install-skill.ps1 -Target "$HOME\.claude\skills" -Reconfigure
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $Target,

    [string] $Source,

    [string] $FromBoundary,

    [string] $AnswerFile,

    [switch] $SkipInterview,

    [switch] $Reconfigure,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$skillName      = 'kalcirite-project-rules'
$beginTag       = '<!-- kalcirite:local-profile:begin -->'
$endTag         = '<!-- kalcirite:local-profile:end -->'
$answersBegin   = '<!-- kalcirite:answers:begin -->'
$answersEnd     = '<!-- kalcirite:answers:end -->'

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

function Expand-UserPath([string] $Value) {
    $v = $Value.Trim().Trim('"').Trim("'")
    $v = [System.Environment]::ExpandEnvironmentVariables($v)
    if ($v.StartsWith('~')) {
        $v = Join-Path $env:USERPROFILE $v.Substring(1).TrimStart('\', '/')
    }
    return $v
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

function Get-AnswersFromPsd1([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Answer file not found: $Path" }
    $data = Import-PowerShellDataFile -LiteralPath $Path
    $h = [ordered]@{}
    foreach ($k in $data.Keys) { $h[[string]$k] = [string]$data[$k] }
    return $h
}

function New-DefaultAnswers {
    return [ordered]@{
        DEP_CACHE              = ''
        DEP_CACHE_INDEX        = ''
        PNPM_STORE             = ''
        NPM_CACHE              = ''
        PIP_CACHE              = ''
        CARGO_HOME             = ''
        ELECTRON_CACHE         = ''
        ELECTRON_BUILDER_CACHE = ''
        UI_SOURCE              = 'none'
        UI_VERSION             = ''
        UI_PREVIEW             = 'none'
        TOOL_HOME              = 'none'
        TOOL_INDEX             = ''
        TOOL_REGISTRY          = ''
        TOOL_VALIDATOR         = ''
        BUILD_ROOT             = 'cxbuild/'
        TMP                    = 'temp/'
        EVIDENCE               = 'verify-evidence/'
        DOCS                   = 'docs/'
        DEV_DOCS               = 'dev-docs/'
        ROUTE_PROVIDER           = 'none'
        CHEAP_MODELS             = ''
        ROUTE_TOOL               = 'list_subagent_models'
        HOST_AGENT               = ''
        DELEGATION_TOOLS         = 'none'
        ROUTE_SELECTION_SUPPORTED = 'none'
        ROUTE_ENABLE_SETTING     = ''
        ROUTE_TAKES_EFFECT       = ''
        CONCURRENCY_LIMIT        = ''
        SHELL_NOTE             = ''
        PROXY                  = ''
        PORTS                  = ''
        NEVER_DELETE           = ''
        GENERATED              = ''
    }
}

function Get-ProbedCacheDefault {
    $candidates = New-Object System.Collections.ArrayList
    if ($env:SystemDrive) { [void]$candidates.Add((Join-Path $env:SystemDrive 'dependency-cache')) }
    foreach ($d in @('E:', 'D:', 'C:')) { [void]$candidates.Add(($d + '\dependency-cache')) }
    if ($env:USERPROFILE) { [void]$candidates.Add((Join-Path $env:USERPROFILE 'dependency-cache')) }
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
    return ''
}

function Get-ProbedShellNote {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    $note = "Windows PowerShell $($PSVersionTable.PSVersion)"
    if (-not $pwsh) { $note += '; pwsh not on PATH -> call scripts as & .\x.ps1 or powershell -File' }
    if ($bash) { $note += '; bash available' }
    return $note
}

function Get-LatestVersionDirDefault([string] $UiSource) {
    if (-not $UiSource -or $UiSource -eq 'none') { return '' }
    if (-not (Test-Path -LiteralPath $UiSource -PathType Container)) { return '' }
    $dirs = Get-ChildItem -LiteralPath $UiSource -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^v\d' } | Sort-Object Name
    if ($dirs) { return ($dirs | Select-Object -Last 1).Name }
    return ''
}

function Read-TextAnswer([string] $Prompt, [string] $Default, [switch] $AllowBlank) {
    $shown = if ([string]::IsNullOrWhiteSpace($Default)) { '<blank>' } else { $Default }
    while ($true) {
        $v = Read-Host "$Prompt [$shown]"
        if ([string]::IsNullOrWhiteSpace($v)) { $v = $Default }
        if ([string]::IsNullOrWhiteSpace($v) -and -not $AllowBlank) {
            Write-Host '  this one is required'
            continue
        }
        return $v
    }
}

function Read-PathAnswer([string] $Prompt, [string] $Default, [switch] $AllowNone) {
    $shown = if ([string]::IsNullOrWhiteSpace($Default)) { '<blank>' } else { $Default }
    while ($true) {
        $v = Read-Host "$Prompt [$shown]  ('none' = not applicable)"
        if ([string]::IsNullOrWhiteSpace($v)) { $v = $Default }
        if ($v -match '^(none|-|skip)$') {
            if ($AllowNone) { return 'none' }
            Write-Host '  this one is required and cannot be none'
            continue
        }
        if ([string]::IsNullOrWhiteSpace($v)) {
            if ($AllowNone) { return 'none' }
            Write-Host '  this one is required'
            continue
        }
        $p = Expand-UserPath $v
        if (Test-Path -LiteralPath $p) {
            Write-Host "  [ok] $p"
            return $p
        }
        Write-Host "  [missing] $p"
        $choice = Read-Host '  [c]reate it, [k]eep anyway (recorded unverified), [r]etry, [s]kip'
        switch ($choice.Trim().ToLower()) {
            'c' {
                New-Item -ItemType Directory -Force -Path $p | Out-Null
                Write-Host "  [created] $p"
                return $p
            }
            'k' { return ($p + ' (unverified)') }
            's' { if ($AllowNone) { return 'none' } }
            default { }
        }
    }
}

function Read-YesNo([string] $Prompt, [bool] $DefaultYes) {
    $shown = if ($DefaultYes) { 'Y/n' } else { 'y/N' }
    while ($true) {
        $v = Read-Host "$Prompt [$shown]"
        if ([string]::IsNullOrWhiteSpace($v)) { return $DefaultYes }
        switch ($v.Trim().ToLower()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
        }
    }
}

function Set-CacheSubLayout($a, [string] $cacheRoot) {
    if (-not $cacheRoot -or $cacheRoot -eq 'none') {
        foreach ($k in @('DEP_CACHE_INDEX', 'PNPM_STORE', 'NPM_CACHE', 'PIP_CACHE', 'CARGO_HOME', 'ELECTRON_CACHE', 'ELECTRON_BUILDER_CACHE')) {
            $a[$k] = 'none'
        }
        return
    }
    $a['DEP_CACHE_INDEX']        = Join-Path $cacheRoot 'INDEX.md'
    $a['PNPM_STORE']             = Join-Path $cacheRoot 'pnpm-store'
    $a['NPM_CACHE']              = Join-Path $cacheRoot 'npm-cache'
    $a['PIP_CACHE']              = Join-Path $cacheRoot 'pip-cache'
    $a['CARGO_HOME']             = Join-Path $cacheRoot 'cargo'
    $a['ELECTRON_CACHE']         = Join-Path $cacheRoot 'electron\Cache'
    $a['ELECTRON_BUILDER_CACHE'] = Join-Path $cacheRoot 'electron-builder\Cache'
}

# ------------------------------------------------------------- interview ----

function Invoke-Interview($a) {
    Write-Host ''
    Write-Host '== Kalcirite rule text: machine boundary interview ==' -ForegroundColor Cyan
    Write-Host 'Each answer is written back into PROJECT-BOUNDARY.md and into the'
    Write-Host 'local-profile block of the installed SKILL.md.'
    Write-Host 'Enter accepts the default. "none" means "not applicable".'
    Write-Host ''

    # -- 1. dependency cache -------------------------------------------------
    Write-Host '1. The single dependency cache root' -ForegroundColor Yellow
    if (-not $a['DEP_CACHE']) { $a['DEP_CACHE'] = Get-ProbedCacheDefault }
    $a['DEP_CACHE'] = Read-PathAnswer '   DEP_CACHE (required)' $a['DEP_CACHE']

    # -- 2. cache sub-layout -------------------------------------------------
    if ($a['DEP_CACHE'] -eq 'none') {
        Set-CacheSubLayout $a 'none'
    }
    else {
        $defaults = New-DefaultAnswers
        Set-CacheSubLayout $defaults $a['DEP_CACHE']
        $shown = $defaults['PNPM_STORE']
        Write-Host "2. Cache sub-layout, e.g. $shown" -ForegroundColor Yellow
        if (Read-YesNo '   keep the conventional sub-layout' $true) {
            Set-CacheSubLayout $a $a['DEP_CACHE']
        }
        else {
            $a['DEP_CACHE_INDEX']        = Read-PathAnswer '   cache index file' $defaults['DEP_CACHE_INDEX'] -AllowNone
            $a['PNPM_STORE']             = Read-PathAnswer '   pnpm store' $defaults['PNPM_STORE'] -AllowNone
            $a['NPM_CACHE']              = Read-PathAnswer '   npm cache' $defaults['NPM_CACHE'] -AllowNone
            $a['PIP_CACHE']              = Read-PathAnswer '   pip cache' $defaults['PIP_CACHE'] -AllowNone
            $a['CARGO_HOME']             = Read-PathAnswer '   CARGO_HOME' $defaults['CARGO_HOME'] -AllowNone
            $a['ELECTRON_CACHE']         = Read-PathAnswer '   ELECTRON_CACHE' $defaults['ELECTRON_CACHE'] -AllowNone
            $a['ELECTRON_BUILDER_CACHE'] = Read-PathAnswer '   ELECTRON_BUILDER_CACHE' $defaults['ELECTRON_BUILDER_CACHE'] -AllowNone
        }
    }

    # -- 3. canonical UI source ---------------------------------------------
    Write-Host '3. Canonical UI source (design system / component engine)' -ForegroundColor Yellow
    $a['UI_SOURCE'] = Read-PathAnswer '   UI_SOURCE' $a['UI_SOURCE'] -AllowNone
    if ($a['UI_SOURCE'] -ne 'none') {
        if (-not $a['UI_VERSION']) { $a['UI_VERSION'] = Get-LatestVersionDirDefault $a['UI_SOURCE'] }
        $a['UI_VERSION'] = Read-TextAnswer '   UI_DEFAULT_VERSION (read its README + contract first)' $a['UI_VERSION'] -AllowBlank
        $a['UI_PREVIEW'] = Read-PathAnswer '   UI_PREVIEW (optional workbench)' $a['UI_PREVIEW'] -AllowNone
    }
    else {
        $a['UI_VERSION'] = ''
        $a['UI_PREVIEW'] = 'none'
        Write-Host '   -> recorded none: one UI source per project, styling must still be tokenised'
    }

    # -- 4. shared tool catalogue -------------------------------------------
    Write-Host '4. Shared tool / plugin catalogue' -ForegroundColor Yellow
    $a['TOOL_HOME'] = Read-PathAnswer '   TOOL_HOME' $a['TOOL_HOME'] -AllowNone
    if ($a['TOOL_HOME'] -ne 'none') {
        $a['TOOL_INDEX']    = Read-TextAnswer '   index file name'    (Join-Path $a['TOOL_HOME'] 'INDEX.md')
        $a['TOOL_REGISTRY'] = Read-TextAnswer '   registry file name' (Join-Path $a['TOOL_HOME'] 'registry.json')
        $a['TOOL_VALIDATOR'] = Read-TextAnswer '   validator entry point (blank = none)' $a['TOOL_VALIDATOR'] -AllowBlank
    }
    else {
        $a['TOOL_INDEX'] = ''; $a['TOOL_REGISTRY'] = ''; $a['TOOL_VALIDATOR'] = ''
        Write-Host '   -> recorded none: search the project own tools/ first, then build inside it'
    }

    # -- 5. layout names -----------------------------------------------------
    Write-Host '5. Project layout names' -ForegroundColor Yellow
    if (Read-YesNo '   keep the defaults (cxbuild/ temp/ verify-evidence/ docs/ dev-docs/)' $true) {
        $a['BUILD_ROOT'] = 'cxbuild/'; $a['TMP'] = 'temp/'; $a['EVIDENCE'] = 'verify-evidence/'
        $a['DOCS'] = 'docs/'; $a['DEV_DOCS'] = 'dev-docs/'
    }
    else {
        $a['BUILD_ROOT'] = Read-TextAnswer '   build output root' $a['BUILD_ROOT']
        $a['TMP']        = Read-TextAnswer '   scratch root'      $a['TMP']
        $a['EVIDENCE']   = Read-TextAnswer '   evidence root'     $a['EVIDENCE']
        $a['DOCS']       = Read-TextAnswer '   reader docs root'  $a['DOCS']
        $a['DEV_DOCS']   = Read-TextAnswer '   dev docs root'     $a['DEV_DOCS']
    }

    # -- 6. model routing ----------------------------------------------------
    Write-Host '6. Cost-tiered model routing' -ForegroundColor Yellow
    $a['ROUTE_PROVIDER'] = Read-TextAnswer '   authorised provider (blank = none)' $a['ROUTE_PROVIDER']
    if ([string]::IsNullOrWhiteSpace($a['ROUTE_PROVIDER'])) { $a['ROUTE_PROVIDER'] = 'none' }
    if ($a['ROUTE_PROVIDER'] -ne 'none') {
        $a['CHEAP_MODELS'] = Read-TextAnswer '   cheap model ids, comma separated (ids, not display names)' $a['CHEAP_MODELS']
        $a['ROUTE_TOOL']   = Read-TextAnswer '   route discovery tool' $a['ROUTE_TOOL']
    }
    else {
        $a['CHEAP_MODELS'] = ''
        Write-Host '   -> recorded none: delegation stays on the parent route'
    }

    # -- 6b. sub-agents and model selection (host-specific) -----------------
    Write-Host '6b. Sub-agents and model selection - host-specific, see boundary/DELEGATION.md' -ForegroundColor Yellow
    $a['HOST_AGENT'] = Read-TextAnswer '   host agent / harness and version (blank = unknown)' $a['HOST_AGENT'] -AllowBlank
    $a['DELEGATION_TOOLS'] = Read-TextAnswer '   delegation tools available, comma separated (none = no delegation)' $a['DELEGATION_TOOLS']
    if ([string]::IsNullOrWhiteSpace($a['DELEGATION_TOOLS'])) { $a['DELEGATION_TOOLS'] = 'none' }
    if ($a['DELEGATION_TOOLS'] -ne 'none') {
        if (Read-YesNo '   can a delegation name its own provider + model' $false) {
            $a['ROUTE_SELECTION_SUPPORTED'] = 'yes'
            $a['ROUTE_ENABLE_SETTING'] = Read-TextAnswer '   setting that enables route selection' $a['ROUTE_ENABLE_SETTING']
            $a['ROUTE_TAKES_EFFECT']   = Read-TextAnswer '   when does a change take effect (new session / restart / immediate)' $a['ROUTE_TAKES_EFFECT']
            $a['CONCURRENCY_LIMIT']    = Read-TextAnswer '   concurrency or budget limit (blank = none)' $a['CONCURRENCY_LIMIT'] -AllowBlank
        }
        else {
            $a['ROUTE_SELECTION_SUPPORTED'] = 'none'
            $a['ROUTE_ENABLE_SETTING'] = ''
            $a['ROUTE_TAKES_EFFECT']   = ''
            Write-Host '   -> recorded none: delegate on the inherited route and say so in the report'
        }
    }
    else {
        $a['ROUTE_SELECTION_SUPPORTED'] = 'none'
        $a['ROUTE_ENABLE_SETTING'] = ''
        $a['ROUTE_TAKES_EFFECT']   = ''
        $a['CONCURRENCY_LIMIT']    = ''
        Write-Host '   -> recorded none: no delegation; cost tiers apply to sessions only'
    }

    # -- 7. shell / environment ---------------------------------------------
    Write-Host '7. Environment facts' -ForegroundColor Yellow
    if (-not $a['SHELL_NOTE']) { $a['SHELL_NOTE'] = Get-ProbedShellNote }
    $a['SHELL_NOTE']   = Read-TextAnswer '   SHELL_NOTE (command-syntax constraints)' $a['SHELL_NOTE'] -AllowBlank
    $a['PROXY']        = Read-TextAnswer '   system proxy (blank = none)' $a['PROXY'] -AllowBlank
    $a['PORTS']        = Read-TextAnswer '   fixed ports (blank = none)' $a['PORTS'] -AllowBlank
    $a['NEVER_DELETE'] = Read-TextAnswer '   paths/data that must never be deleted (blank = none)' $a['NEVER_DELETE'] -AllowBlank

    return $a
}

# -------------------------------------------------------------- rendering ----

function Format-Cell([string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '_(blank - rules stop and report)_' }
    return $Value.Replace('|', '\|')
}

function New-BoundaryMarkdown($a, [string] $Stamp, [string] $Origin) {
    $tpl = @'
# PROJECT-BOUNDARY - machine boundary file

> Generated by `scripts/install-skill.ps1` on @STAMP@ (@ORIGIN@).
> This is the only place machine-specific facts live. The rule text beside this
> file stays environment-neutral and resolves values through its section 0.1 order:
> project root -> this skill's directory -> agent config root -> local profile.
> Change values here, never in the rule text. Blank means "no assumption": the
> rules stop and report rather than guess.

## 1. Single dependency cache

| Key | Value |
|---|---|
| `DEP_CACHE` | @DEP_CACHE@ |
| `DEP_CACHE_INDEX` | @DEP_CACHE_INDEX@ |
| `pnpm store` | @PNPM_STORE@ |
| `npm cache` | @NPM_CACHE@ |
| `pip cache` | @PIP_CACHE@ |
| `CARGO_HOME` | @CARGO_HOME@ |
| `ELECTRON_CACHE` | @ELECTRON_CACHE@ |
| `ELECTRON_BUILDER_CACHE` | @ELECTRON_BUILDER_CACHE@ |

## 2. Canonical UI source

| Key | Value |
|---|---|
| `UI_SOURCE` | @UI_SOURCE@ |
| `UI_PREVIEW` | @UI_PREVIEW@ |
| `UI_DEFAULT_VERSION` | @UI_VERSION@ |
| `UI_STYLING_RULE` | layout in project CSS; colour/state/motion from tokens and variants |

## 3. Shared tool / plugin catalogue

| Key | Value |
|---|---|
| `TOOL_HOME` | @TOOL_HOME@ |
| `TOOL_INDEX` | @TOOL_INDEX@ |
| `TOOL_REGISTRY` | @TOOL_REGISTRY@ |
| `TOOL_VALIDATOR` | @TOOL_VALIDATOR@ |

## 4. Project layout

| Key | Value |
|---|---|
| `BUILD_ROOT` | @BUILD_ROOT@ |
| `TMP` | @TMP@ |
| `EVIDENCE` | @EVIDENCE@ |
| `DOCS` | @DOCS@ |
| `DEV_DOCS` | @DEV_DOCS@ |
| `SRC` | src/ |

## 5. Cost-tiered model routing

| Key | Value |
|---|---|
| `ROUTE_PROVIDER` | @ROUTE_PROVIDER@ |
| `CHEAP_MODELS` | @CHEAP_MODELS@ |
| `ROUTE_TOOL` | @ROUTE_TOOL@ |
| strong route | parent session / agent default |

### 5.1 Sub-agents and model selection (host-specific)

| Key | Value |
|---|---|
| `HOST_AGENT` | @HOST_AGENT@ |
| `DELEGATION_TOOLS` | @DELEGATION_TOOLS@ |
| `ROUTE_SELECTION_SUPPORTED` | @ROUTE_SELECTION_SUPPORTED@ |
| `ROUTE_ENABLE_SETTING` | @ROUTE_ENABLE_SETTING@ |
| `ROUTE_TAKES_EFFECT` | @ROUTE_TAKES_EFFECT@ |
| `CONCURRENCY_LIMIT` | @CONCURRENCY_LIMIT@ |

Unless `ROUTE_SELECTION_SUPPORTED` is `yes`, model selection is unavailable: delegate on
the inherited route, never fabricate `provider` / `model` fields, and say so in the report.

## 6. Local environment facts (verify before use)

| Key | Value |
|---|---|
| `SHELL_NOTE` | @SHELL_NOTE@ |
| proxy | @PROXY@ |
| fixed ports | @PORTS@ |
| never delete | @NEVER_DELETE@ |

## 7. Collected answers (machine readable)

Keep this block: `install-skill.ps1 -FromBoundary <this file>` reads it back.

@ANSWERS_BEGIN@
```json
@ANSWERS_JSON@
```
@ANSWERS_END@

*Refresh with `install-skill.ps1 -Reconfigure`, or edit the values above by hand.*
'@

    $map = @{
        '@STAMP@'                  = $Stamp
        '@ORIGIN@'                 = $Origin
        '@ANSWERS_BEGIN@'          = $answersBegin
        '@ANSWERS_END@'            = $answersEnd
        '@ANSWERS_JSON@'           = ($a | ConvertTo-Json -Depth 3)
    }
    foreach ($k in $a.Keys) { $map['@' + $k + '@'] = (Format-Cell ([string]$a[$k])) }

    $text = $tpl
    foreach ($k in $map.Keys) { $text = $text.Replace($k, [string]$map[$k]) }
    return $text
}

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
    [void]$lines.Add("> Filled on $Stamp by ``install-skill.ps1``. Source of truth: ``$BoundaryPath`` - edit there, not here.")
    [void]$lines.Add('> These values are machine-specific. Keep the rest of this file environment-neutral.')
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

if (-not $Source) {
    $Source = Join-Path (Split-Path -Parent $PSScriptRoot) "skills\$skillName"
}
if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Source skill directory not found: $Source" }
if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) { throw "Source is not a skill (SKILL.md missing): $Source" }

$Target = [System.IO.Path]::GetFullPath($Target)
$dest           = Join-Path $Target $skillName
$skillMd        = Join-Path $dest 'SKILL.md'
$boundaryOut    = Join-Path $dest 'PROJECT-BOUNDARY.md'
$legacyBoundary = Join-Path $Target 'PROJECT-BOUNDARY.md'

# 1. resolve the answers -----------------------------------------------------
$answers = $null
$origin  = ''
if ($AnswerFile) {
    $answers = Get-AnswersFromPsd1 $AnswerFile
    $origin  = "answers: $AnswerFile"
}
elseif ($FromBoundary) {
    $answers = Get-AnswersFromBoundaryFile $FromBoundary
    if (-not $answers) { throw "No kalcirite:answers block found in: $FromBoundary" }
    $origin = "answers: $FromBoundary"
}
elseif (-not $Reconfigure) {
    foreach ($candidate in @($boundaryOut, $legacyBoundary)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $found = Get-AnswersFromBoundaryFile $candidate
            if ($found) { $answers = $found; $origin = "existing boundary: $candidate"; break }
        }
    }
    if (-not $answers -and (Test-Path -LiteralPath $boundaryOut -PathType Leaf)) {
        $origin = "existing hand-written boundary: $boundaryOut"
    }
}

$profile = New-DefaultAnswers
if ($answers) { foreach ($k in $answers.Keys) { $profile[$k] = $answers[$k] } }

if ($SkipInterview) {
    if (-not $answers -and -not $Reconfigure) {
        throw 'Nothing to install from: pass -AnswerFile or -FromBoundary, or drop -SkipInterview to run the interview.'
    }
    Write-Host "no prompts (-SkipInterview); answers from $origin"
}
elseif ($answers -and -not $Reconfigure) {
    Write-Host "keeping existing answers ($origin)"
    Write-Host 'run again with -Reconfigure to change them'
}
else {
    $profile = Invoke-Interview $profile
}

$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm')
if (-not $profile['GENERATED']) { $profile['GENERATED'] = $stamp }
elseif ($Reconfigure -or $answers) { $profile['GENERATED'] = $stamp }

if ([string]::IsNullOrWhiteSpace($profile['DEP_CACHE'])) {
    throw 'DEP_CACHE is empty: the dependency rule would have nothing to resolve. Re-run and answer question 1.'
}

# 2. install the rule text ---------------------------------------------------
$hadBoundary = Test-Path -LiteralPath $boundaryOut -PathType Leaf
$handWritten = $false
if ($hadBoundary -and -not (Get-AnswersFromBoundaryFile $boundaryOut)) { $handWritten = $true }
if ($handWritten -and -not $Force) {
    throw "Boundary file was hand-written, refusing to overwrite: $boundaryOut  (re-run with -Force)"
}

if ($PSCmdlet.ShouldProcess($dest, 'Install rule text')) {
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path (Join-Path $Source '*') -Destination $dest -Recurse -Force
    Write-Host "installed skill -> $skillMd"
}

# 3. write the answers back --------------------------------------------------
if ($PSCmdlet.ShouldProcess($boundaryOut, 'Write machine boundary file')) {
    if ($hadBoundary -and -not (Test-Path -LiteralPath ($boundaryOut + '.bak'))) {
        Copy-Item -LiteralPath $boundaryOut -Destination ($boundaryOut + '.bak') -Force
    }
    $originNote = if ($origin) { $origin } else { 'interview' }
    Write-Utf8 $boundaryOut (New-BoundaryMarkdown $profile $stamp $originNote)
    Write-Host "wrote boundary  -> $boundaryOut"
}

if ($PSCmdlet.ShouldProcess($skillMd, 'Fill the local profile block')) {
    Set-LocalProfileBlock $skillMd (New-LocalProfileBlock $profile $stamp $boundaryOut)
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
