# Marv OS on Windows, through WSL2 (experimental).
#
#   irm https://raw.githubusercontent.com/Flologix/marv-os-releases/main/install-windows.ps1 | iex
#
# What it does: checks your Windows build, installs WSL2 with Ubuntu 24.04 if you
# have no Linux distribution yet, then runs the Marv OS Linux installer inside it.
# Marv OS opens as a window on your desktop through WSLg.

$ErrorActionPreference = 'Stop'

$Distro = 'Ubuntu-24.04'
$InstallUrl = 'https://raw.githubusercontent.com/Flologix/marv-os-releases/main/install.sh'

function Say($Message) { Write-Output $Message }

# 1. Windows 11, or Windows 10 21H2 (build 19044) and later, support WSL2 with WSLg.
$build = [System.Environment]::OSVersion.Version.Build
if ($build -lt 19044) {
    Say "Windows build $build is too old. Marv OS on Windows needs Windows 10 21H2 or later, or Windows 11."
    Say 'Update Windows, then run this again.'
    return
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Say 'wsl.exe was not found. Turn on "Windows Subsystem for Linux" in Windows Features, restart, and run this again.'
    return
}

# 2. Is there a distribution already? (wsl prints UTF-16, so strip the NUL characters.)
$installed = (& wsl.exe --list --quiet 2>$null) -join "`n"
$installed = $installed -replace "`0", ''
$hasDistro = $installed -match [regex]::Escape($Distro)
$hasAny = $installed.Trim().Length -gt 0 -and $LASTEXITCODE -eq 0

if (-not $hasDistro -and -not $hasAny) {
    Say "No Linux distribution found. Installing WSL2 with $Distro (this can take a few minutes)..."
    & wsl.exe --install -d $Distro
    Say ''
    Say 'WSL is installing. Windows may ask you to restart, and Ubuntu may ask you to pick a username'
    Say 'and password the first time it starts. When that is done, run this script again.'
    return
}

if (-not $hasDistro) {
    Say "You already have WSL, but not $Distro. Installing $Distro next to it..."
    & wsl.exe --install -d $Distro
    Say 'When it has finished (and you have set a username and password), run this script again.'
    return
}

# 3. Make sure WSL itself is current: older versions have no WSLg.
Say 'Updating WSL (needed for WSLg)...'
& wsl.exe --update | Out-Null

# 4. Run the Linux installer inside the distribution.
Say "Installing Marv OS inside $Distro. It will ask for your Ubuntu password to run apt."
& wsl.exe -d $Distro -- sh -c "curl -fsSL $InstallUrl | sh"
if ($LASTEXITCODE -ne 0) {
    Say 'The installer failed. The messages above say why. You can run it again at any time.'
    return
}

Say ''
Say 'Done. To start Marv OS:'
Say '  - open "Marv OS" from the Windows Start menu (WSLg adds it automatically), or'
Say "  - run:  wsl -d $Distro marv-desktop"
