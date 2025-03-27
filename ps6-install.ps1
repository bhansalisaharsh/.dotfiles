# PowerShell 5.1/6 Installer Script
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Run this script as Administrator."
    Exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not available. Please install it."
    Exit 1
}

# Winget Packages
$wingetApps = @(
    "Starship.Starship", "eza-community.eza", "sharkdp.bat", "sharkdp.fd",
    "ajeetdsouza.zoxide", "junegunn.fzf", "BurntSushi.ripgrep.MSVC",
    "Git.Git", "Microsoft.WindowsTerminal", "Microsoft.PowerShell",
    "Microsoft.PowerToys", "AutoHotkey.AutoHotkey", "tldr-pages.tlrc",
    "GitHub.cli"
)

$upgradeWinget = @()

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

# PowerShell Modules
$psModules = @("PSReadLine", "PSFzf")
$upgradeModules = @()

Write-Host "`nInstalling PowerShell modules (current shell)..."
foreach ($mod in $psModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
        Write-Host "Installed module: $mod"
    }
    else {
        Write-Host "Already exists: $mod"
        $upgradeModules += @{ Name = $mod; Context = "current" }
    }
}

if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Host "`nInstalling modules in PowerShell 7 context..."
    foreach ($mod in $psModules + "CompletionPredictor") {
        $check = "if (-not (Get-Module -ListAvailable -Name $mod)) { Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber }"
        pwsh -NoLogo -NoProfile -Command $check
        if ($LASTEXITCODE -eq 1) {
            $upgradeModules += @{ Name = $mod; Context = "pwsh" }
        }
    }
}
else {
    Write-Warning "PowerShell 7 not found. Skipping PS7 module install."
}

# Upgrade Winget
Write-Host "`nWinget packages that can be upgraded:"
$upgradeWinget | ForEach-Object { Write-Host " - $_" }
$response = Read-Host "Do you want to upgrade all winget packages? (y/N)"
if ($response -match '^(y|yes)$') {
    winget upgrade --all --accept-package-agreements --accept-source-agreements
}
else {
    Write-Host "Skipped winget upgrades."
}

# Function: Update module safely
function Update-Safely($modName) {
    try {
        if (Get-Module $modName) {
            Remove-Module $modName -Force -ErrorAction Stop
        }
        Update-Module -Name $modName -Force -ErrorAction Stop
        Import-Module $modName -ErrorAction Stop
        Write-Host "Updated and reloaded module: $modName"
    }
    catch {
        Write-Warning "Could not update ${modName} $($_.Exception.Message)"
    }
}

# Upgrade Modules
if ($upgradeModules.Count -gt 0) {
    Write-Host "`nModules that can be upgraded:"
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
Update-Module -Name '$($mod.Name)' -Force
Import-Module '$($mod.Name)'
"@
            pwsh -NoLogo -NoProfile -Command $cmd
        }
    }
    else {
        Write-Host "Skipped PowerShell module upgrades."
    }
}
