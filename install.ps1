# PowerShell Installer Script

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Run this script as Administrator."
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not installed or not in PATH."
    exit 1
}

# --- Config ---
$wingetApps = @(
    "Starship.Starship", "eza-community.eza", "sharkdp.bat", "sharkdp.fd",
    "ajeetdsouza.zoxide", "junegunn.fzf", "BurntSushi.ripgrep.MSVC",
    "Git.Git", "Microsoft.WindowsTerminal", "Microsoft.PowerShell",
    "Microsoft.PowerToys", "AutoHotkey.AutoHotkey", "tldr-pages.tlrc",
    "GitHub.cli", "rsteube.Carapace"
)

$psModules = @("PSReadLine", "PSFzf", "CompletionPredictor", "PowerType")
$upgradeWinget = @()
$upgradeModules = @()

# --- Winget Install ---
Write-Host "`nChecking winget packages..."
foreach ($id in $wingetApps) {
    $result = winget list --id $id -e
    if ($result -match $id) {
        Write-Host "Already installed: $id"
        $upgradeWinget += $id
    }
    else {
        Write-Host "Installing: $id"
        winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
    }
}

# --- Install PowerShell modules in current shell ---
Write-Host "`nInstalling PowerShell modules (current shell)..."
foreach ($mod in $psModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module -Name $mod -Force -AllowClobber
        Write-Host "Installed: $mod"
    }
    else {
        Write-Host "Already exists: $mod"
        $upgradeModules += @{ Name = $mod; Context = "current" }
    }
}

# --- Install modules in pwsh ---
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Host "`nInstalling modules in PowerShell 7 context..."
    foreach ($mod in $psModules) {
        $check = "if (-not (Get-Module -ListAvailable -Name $mod)) { Install-Module -Name $mod -Force -AllowClobber }"
        pwsh -NoLogo -NoProfile -Command $check
        if ($LASTEXITCODE -eq 1) {
            $upgradeModules += @{ Name = $mod; Context = "pwsh" }
        }
    }
}
else {
    Write-Host "PowerShell 7 (pwsh) not found. Skipping pwsh module installs."
}

# --- Install modules in powershell.exe ---
if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
    Write-Host "`nInstalling modules in Windows PowerShell context..."
    foreach ($mod in @("PSReadLine", "PSFzf", "PowerType")) {
        $cmd = "if (-not (Get-Module -ListAvailable -Name $mod)) { Install-Module -Name $mod -Force -AllowClobber }"
        powershell.exe -NoLogo -NoProfile -Command $cmd
        if ($LASTEXITCODE -eq 1) {
            $upgradeModules += @{ Name = $mod; Context = "powershell" }
        }
    }
}
else {
    Write-Host "Windows PowerShell not found. Skipping legacy shell module installs."
}

# --- Winget Upgrade ---
Write-Host "`nWinget packages that can be upgraded:"
$upgradeWinget | ForEach-Object { Write-Host " - $_" }
$response = Read-Host "Do you want to upgrade all winget packages? (y/N)"
if ($response -match '^(y|yes)$') {
    winget upgrade --all --accept-package-agreements --accept-source-agreements
}
else {
    Write-Host "Skipped winget upgrades."
}

# --- Safe module update helpers ---
function Reinstall-Module {
    param($modName)
    try {
        Uninstall-Module -Name $modName -Force -ErrorAction SilentlyContinue
        Install-Module -Name $modName -Force -AllowClobber
        Write-Host "Reinstalled module: ${modName}"
    }
    catch {
        Write-Warning "Could not reinstall ${modName}: $($_.Exception.Message)"
    }
}

function Update-Safely($modName) {
    try {
        if (Get-Module $modName) {
            Remove-Module $modName -Force -ErrorAction Stop
        }
        Update-Module -Name $modName -Force -ErrorAction Stop
        Import-Module $modName -ErrorAction Stop
        Write-Host "Updated and reloaded module: ${modName}"
    }
    catch {
        if ($_.Exception.Message -like '*was not installed by using Install-Module*') {
            Write-Warning "Module ${modName} cannot be updated; attempting reinstall..."
            Reinstall-Module $modName
        }
        else {
            Write-Warning "Could not update ${modName}: $($_.Exception.Message)"
        }
    }
}

# --- Upgrade PowerShell modules ---
if ($upgradeModules.Count -gt 0) {
    Write-Host "`nPowerShell modules that can be upgraded:"
    foreach ($mod in $upgradeModules) {
        Write-Host " - $($mod.Name) [$($mod.Context)]"
    }

    $response2 = Read-Host "Do you want to upgrade all PowerShell modules? (y/N)"
    if ($response2 -match '^(y|yes)$') {
        foreach ($mod in $upgradeModules | Where-Object { $_.Context -eq "current" }) {
            Update-Safely $mod.Name
        }

        foreach ($mod in $upgradeModules | Where-Object { $_.Context -eq "pwsh" }) {
            $cmd = @"
if (Get-Module '$($mod.Name)') { Remove-Module '$($mod.Name)' -Force }
try {
    Update-Module -Name '$($mod.Name)' -Force
    Import-Module '$($mod.Name)'
} catch {
    Uninstall-Module '$($mod.Name)' -Force -ErrorAction SilentlyContinue
    Install-Module '$($mod.Name)' -Force -AllowClobber
}
"@
            pwsh -NoLogo -NoProfile -Command $cmd
        }

        foreach ($mod in $upgradeModules | Where-Object { $_.Context -eq "powershell" }) {
            $cmd = @"
if (Get-Module '$($mod.Name)') { Remove-Module '$($mod.Name)' -Force }
try {
    Update-Module -Name '$($mod.Name)' -Force
    Import-Module '$($mod.Name)'
} catch {
    Uninstall-Module '$($mod.Name)' -Force -ErrorAction SilentlyContinue
    Install-Module '$($mod.Name)' -Force -AllowClobber
}
"@
            powershell.exe -NoLogo -NoProfile -Command $cmd
        }
    }
    else {
        Write-Host "Skipped module upgrades."
    }
}
