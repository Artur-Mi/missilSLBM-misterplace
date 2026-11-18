<#
.SYNOPSIS
  Deploys this mod to the Space Engineers local Mods folder as its dev or final version.

.DESCRIPTION
  dev   - Links %APPDATA%\SpaceEngineers\Mods\<dev folder> to this repo's Mod\ folder (a junction),
          so edits are live the next time a world loads. Writes the dev modinfo.sbmi into Mod\.
  final - Requires a clean git working tree. Copies a snapshot of Mod\ into
          %APPDATA%\SpaceEngineers\Mods\<final folder>, writes the final modinfo.sbmi and tags the
          commit as release/<timestamp>.

  Any existing non-link folder at the destination is moved to
  %APPDATA%\SpaceEngineers\ModBackups\ first, never deleted.
  Publishing itself is done from the game (Mods screen -> Publish), which reads modinfo.sbmi.

.EXAMPLE
  .\deploy.ps1 dev
  .\deploy.ps1 final -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('dev', 'final')]
    [string]$Target,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$modSrc = Join-Path $repo 'Mod'
$config = Get-Content (Join-Path $repo 'deploy.json') -Raw | ConvertFrom-Json
$t = $config.targets.$Target
if ($null -eq $t) { throw "No '$Target' target in deploy.json" }

$modsDir = Join-Path $env:APPDATA 'SpaceEngineers\Mods'
$backupDir = Join-Path $env:APPDATA 'SpaceEngineers\ModBackups'
$dest = Join-Path $modsDir $t.folder

function Step([string]$msg) { if ($DryRun) { Write-Host "[dry-run] $msg" } else { Write-Host $msg } }

function Write-ModInfo([string]$dir) {
    $path = Join-Path $dir 'modinfo.sbmi'
    $hasId = $t.workshopId -and ([int64]$t.workshopId -ne 0)

    if (-not $hasId) {
        # Target not published yet. Never reuse another target's Workshop ID (a publish would overwrite
        # that item). If the game already wrote an ID of its own here (after the first publish), keep it.
        $otherIds = @($config.targets.PSObject.Properties | Where-Object { $_.Name -ne $Target } |
            ForEach-Object { "$($_.Value.workshopId)" } | Where-Object { $_ -and $_ -ne '0' })
        if (Test-Path -LiteralPath $path) {
            $text = Get-Content -LiteralPath $path -Raw
            $found = [regex]::Matches($text, '<Id>(\d+)</Id>') | ForEach-Object { $_.Groups[1].Value }
            $foreign = @($found | Where-Object { $otherIds -contains $_ })
            if ($found.Count -gt 0 -and $foreign.Count -eq 0) {
                Write-Host "Keeping existing $path (Workshop ID $($found -join ', ')). Record it as workshopId in deploy.json."
                return
            }
        }
    }

    $idXml = ''
    if ($hasId) {
        $idXml = @"

  <WorkshopIds>
    <WorkshopId>
      <Id>$($t.workshopId)</Id>
      <ServiceName>Steam</ServiceName>
    </WorkshopId>
  </WorkshopIds>
"@
    }
    $xml = @"
<?xml version="1.0"?>
<MyObjectBuilder_ModInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SteamIDOwner>$($config.steamIdOwner)</SteamIDOwner>
  <WorkshopId>0</WorkshopId>$idXml
</MyObjectBuilder_ModInfo>
"@
    $label = if ($hasId) { "Workshop ID $($t.workshopId)" } else { 'not published yet: the first Publish creates the item' }
    Step "Write $path ($label)"
    if (-not $DryRun) { [IO.File]::WriteAllText($path, $xml, (New-Object Text.UTF8Encoding $false)) }
}

function Test-IsLink([string]$path) {
    $item = Get-Item -LiteralPath $path -Force
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

# Removes only the link itself, never the folder it points to.
function Remove-Link([string]$path) {
    Step "Remove link $path"
    if (-not $DryRun) { [IO.Directory]::Delete($path, $false) }
}

function Backup-Folder([string]$path) {
    $name = '{0}-{1}' -f (Split-Path $path -Leaf), (Get-Date -Format 'yyyyMMdd-HHmmss')
    $to = Join-Path $backupDir $name
    Step "Back up $path -> $to"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force $backupDir | Out-Null
        Move-Item -LiteralPath $path -Destination $to
    }
}

if (-not (Test-Path $modsDir)) { throw "Mods folder not found: $modsDir" }

if ($Target -eq 'dev') {
    if (Test-Path -LiteralPath $dest) {
        if (Test-IsLink $dest) {
            $current = (Get-Item -LiteralPath $dest -Force).Target
            if ($current -and ((Resolve-Path $current).Path -eq (Resolve-Path $modSrc).Path)) {
                Write-Host "Link already in place: $dest -> $modSrc"
            } else {
                Remove-Link $dest
            }
        } else {
            Backup-Folder $dest
        }
    }
    if (-not (Test-Path -LiteralPath $dest) -or $DryRun) {
        Step "Link $dest -> $modSrc"
        if (-not $DryRun) { New-Item -ItemType Junction -Path $dest -Target $modSrc | Out-Null }
    }
    Write-ModInfo $modSrc
    Write-Host "Dev deploy ready. Load a world with '$($t.folder)' enabled; never together with the final version."
    return
}

# --- final ---
Push-Location $repo
try {
    $dirty = git status --porcelain
    if ($LASTEXITCODE -ne 0) { throw 'git status failed' }
    if ($dirty) { throw "Working tree has uncommitted changes. Commit them before a final deploy:`n$($dirty -join "`n")" }
    $commit = (git rev-parse --short HEAD).Trim()
} finally { Pop-Location }

if (Test-Path -LiteralPath $dest) {
    if (Test-IsLink $dest) { Remove-Link $dest } else { Backup-Folder $dest }
}
Step "Copy $modSrc -> $dest (commit $commit)"
if (-not $DryRun) {
    Copy-Item -LiteralPath $modSrc -Destination $dest -Recurse
    $stale = Join-Path $dest 'modinfo.sbmi'
    if (Test-Path $stale) { Remove-Item $stale }
}
Write-ModInfo $dest

$tag = 'release/' + (Get-Date -Format 'yyyy-MM-dd_HHmm')
Step "Tag $commit as $tag"
if (-not $DryRun) {
    Push-Location $repo
    try { git tag $tag; if ($LASTEXITCODE -ne 0) { throw 'git tag failed' } } finally { Pop-Location }
}
Write-Host "Final deploy ready at $dest. Publish it from the game's Mods screen."
