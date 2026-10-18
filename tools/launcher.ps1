# Quakescent launcher (Windows).  Quakescent.bat runs this.
#
# First run: offers to download FTEQW, converts your Descent files into an
# asset pack, then starts the game.  -descent2 (Quakescent2.bat) plays in
# Descent II mode.  Other arguments are passed to FTEQW (e.g.
# .\Quakescent.bat +map e1m1 +skill 2).

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # much faster Invoke-WebRequest
$Root = Split-Path -Parent $PSScriptRoot
$Data = Join-Path $Root 'data'
$Game = Join-Path $Root 'quakescent'
$FteVersion = '2026-07-13'
$FteUrl = "https://fastdl.idtech.space/bin/fteqw-win-x86_64-$FteVersion.zip"

function Fail($msg) {
    Write-Host ""
    Write-Host $msg -ForegroundColor Red
    exit 1
}

function Find-Python {
    if (Get-Command py -ErrorAction SilentlyContinue) { return @('py', '-3') }
    if (Get-Command python -ErrorAction SilentlyContinue) { return ,@('python') }   # , keeps it an array
    return $null
}

# --- FTEQW ------------------------------------------------------------------
$Fte = $env:FTEQW
if (-not $Fte) { $Fte = Join-Path $Root 'fte\fteqw64.exe' }
if (-not (Test-Path $Fte)) {
    Write-Host "FTEQW was not found in $Root\fte\."
    $answer = Read-Host "Download FTEQW ($FteVersion) from fteqw.org now? [Y/n]"
    if ($answer -match '^[nN]') {
        Fail "Get FTEQW from https://www.fteqw.org/ and unzip it into $Root\fte\ (or set FTEQW to fteqw64.exe)."
    }
    $zip = Join-Path $env:TEMP "fteqw-$FteVersion.zip"
    Write-Host "Downloading FTEQW..."
    Invoke-WebRequest $FteUrl -OutFile $zip
    $dest = Join-Path $Root 'fte'
    Expand-Archive $zip -DestinationPath $dest -Force
    Remove-Item $zip
    if (-not (Test-Path $Fte)) {
        # The zip has a top-level folder.
        $exe = Get-ChildItem $dest -Recurse -Filter fteqw64.exe | Select-Object -First 1
        if (-not $exe) { Fail "fteqw64.exe wasn't in the download." }
        Get-ChildItem $exe.DirectoryName | Move-Item -Destination $dest -Force
    }
    Write-Host "FTEQW installed." -ForegroundColor Green
}

# --- The mod ----------------------------------------------------------------
$Progs = Join-Path $Game 'progs.dat'
if (Test-Path (Join-Path $Root 'qc')) {
    # A source checkout: rebuild the mod when any of its files changed.
    $newest = Get-ChildItem (Join-Path $Root 'qc'), (Join-Path $Root 'csqc'), (Join-Path $Root 'mod') -Recurse -File |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not (Test-Path $Progs) -or $newest.LastWriteTime -gt (Get-Item $Progs).LastWriteTime) {
        # FTE's QuakeC compiler.  Fetched here rather than by build.py:
        # Python's certificate checks can fail where Windows' succeed.
        $Qcc = Join-Path $Root 'tools\fteqcc64.exe'
        if (-not $env:FTEQCC -and -not (Test-Path $Qcc) -and -not (Get-Command fteqcc64.exe -ErrorAction SilentlyContinue)) {
            Write-Host "Downloading fteqcc (FTE's QuakeC compiler)..."
            $zip = Join-Path $env:TEMP "fteqcc-$FteVersion.zip"
            Invoke-WebRequest "https://fastdl.idtech.space/bin/fteqcc-win-x86_64-$FteVersion.zip" -OutFile $zip
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $z = [System.IO.Compression.ZipFile]::OpenRead($zip)
            try {
                $entry = $z.Entries | Where-Object { $_.Name -eq 'fteqcc64.exe' } | Select-Object -First 1
                if (-not $entry) { Fail "fteqcc64.exe wasn't in the download." }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $Qcc, $true)
            } finally { $z.Dispose() }
            Remove-Item $zip
        }
        $py = Find-Python
        if (-not $py) { Fail "Python 3 is needed to build the mod from source (https://www.python.org/downloads/)." }
        & $py[0] $py[1..9] (Join-Path $Root 'tools\build.py')
        if ($LASTEXITCODE) { Fail "Building the mod failed." }
    }
}
if (-not (Test-Path $Progs)) { Fail "quakescent\progs.dat is missing; re-download the release." }

# --- Quake's data -------------------------------------------------------------
if (-not (Test-Path (Join-Path $Root 'id1\pak0.pak'))) {
    Fail ("Copy PAK0.PAK (and PAK1.PAK) from the id1 folder of your Quake into $Root\id1\.`n" +
          "For the 2021 re-release (Steam, GOG) copy rerelease\id1\pak0.pak.")
}

# --- Descent's data -------------------------------------------------------------
# Descent 1 by default; "-descent2" (Quakescent2.bat) plays in Descent II
# mode, as does having only Descent II's files.  Each game's pack lives in
# its own folder (descent1\, descent2\), which FTE loads under the mod.
$D2 = $false
$FteArgs = @()
foreach ($a in $args) {
    if ($a -ieq '-descent2' -or $a -ieq '--descent2') { $D2 = $true }
    else { $FteArgs += $a }
}
function Have($name) { Test-Path (Join-Path $Data $name) }
$D1Files = (Have 'DESCENT.HOG') -and (Have 'DESCENT.PIG')
$D2Files = (Have 'DESCENT2.HOG') -and (Have 'DESCENT2.HAM') -and (Have 'GROUPA.PIG') -and
           ((Have 'DESCENT2.S22') -or (Have 'DESCENT2.S11'))
if (-not $D2 -and -not $D1Files -and $D2Files) { $D2 = $true }

if ($D2) {
    $PackDir = 'descent2'
    $ConvArgs = @('--descent2', $Data)
    $Missing = if ($D2Files) { $null } else { "Copy DESCENT2.HOG, DESCENT2.HAM, GROUPA.PIG and DESCENT2.S22 from your copy of Descent II into $Data\ and run this again." }
} else {
    $PackDir = 'descent1'
    $ConvArgs = @($Data)
    $Missing = if ($D1Files) { $null } else { "Copy DESCENT.HOG and DESCENT.PIG from your copy of Descent 1 into $Data\ and run this again." }
}
$PackPath = Join-Path $Root $PackDir
if (-not (Test-Path $PackPath)) { New-Item -ItemType Directory $PackPath | Out-Null }
$Assets = Join-Path $PackPath 'qs_descent_assets.pk3'
$ConvExe = Join-Path $Root 'tools\qsconvert.exe'
$ConvPy = Join-Path $Root 'tools\qsconvert.py'
$converter = if (Test-Path $ConvExe) { Get-Item $ConvExe } else { Get-Item $ConvPy }
# Reconvert when the converter or data\ickface.png changes.
$IckFace = Join-Path $Data 'ickface.png'
$stale = -not (Test-Path $Assets)
if (-not $stale) {
    $built = (Get-Item $Assets).LastWriteTime
    $stale = $converter.LastWriteTime -gt $built -or ((Test-Path $IckFace) -and (Get-Item $IckFace).LastWriteTime -gt $built)
}
if ($stale) {
    if ($Missing) { Fail $Missing }
    Write-Host "Converting your Descent data..."
    if ($converter.Extension -eq '.exe') {
        & $ConvExe @ConvArgs -o $Assets
    } else {
        $py = Find-Python
        if (-not $py) { Fail "Python 3 is needed to convert the Descent data (https://www.python.org/downloads/)." }
        & $py[0] $py[1..9] $ConvPy @ConvArgs -o $Assets
    }
    if ($LASTEXITCODE) { Fail "Converting the Descent data failed (see above)." }
}

# --- Play -------------------------------------------------------------------
# FTE asks on first run whether to use its online package source; answer
# "no" for it (it can be switched on from the Updates menu).
$Installed = Join-Path $Root 'installed.lst'
if (-not (Test-Path $Installed)) {
    Set-Content -Path $Installed -Encoding ASCII -Value @(
        'version 2',
        'source "https://fte.triptohell.info/downloadables.php?game=Q1" "disabled"')
}

& $Fte -basedir $Root -nohome -game $PackDir -game quakescent @FteArgs
