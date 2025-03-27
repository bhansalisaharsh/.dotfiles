# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Run this script as Administrator."
    exit
}

function Is-WingetPackageInstalled($id) {
    $installed = winget list --id $id 2>$null
    return ($installed -match $id)
}

$wingetPackages = @(
    @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
    @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
    @{ Id = "Starship.Starship"; Name = "starship" },
    @{ Id = "NerdFonts.JetBrainsMono.NF"; Name = "JetBrains Mono Nerd Font" },
    @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
    @{ Id = "sharkdp.bat"; Name = "bat" },
    @{ Id = "eza-community.eza"; Name = "eza" },
    @{ Id = "Git.Git"; Name = "git" },
    @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{ Id = "AutoHotkey.AutoHotkey"; Name = "AutoHotkey" },
    @{ Id = "sharkdp.fd"; Name = "fd" },
    @{ Id = "junegunn.fzf"; Name = "fzf" },
    @{ Id = "uutils.coreutils"; Name = "coreutils" },
    @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
    @{ Id = "tldr-pages.tlrc"; Name = "tldr" },
    @{ Id = "GitHub.cli"; Name = "gh" }
)

$upgradeWinget = @()

Write-Host "`n🔍 Checking winget packages..."
foreach ($pkg in $wingetPackages) {
    if (Is-WingetPackageInstalled $pkg.Id) {
        Write-Host "✅ $($pkg.Name) is already installed."
        $upgradeWinget += $pkg
    }
    else {
        Write-Host "⬇️  Installing $($pkg.Name)..."
        winget install --id $($pkg.Id) --source winget --accept-package-agreements --accept-source-agreements --silent
    }
}

# -----------------------------
# PowerShell Module Install
# -----------------------------
$psModules = @("PSReadLine", "PSFzf", "CompletionPredictor")
$upgradeModules = @()

function Install-Or-Flag-Module($modName, $context) {
    $installed = Get-Module -ListAvailable -Name $modName
    if ($installed) {
        Write-Host "✅ $modName module is already installed in $context context."
        $upgradeModules += [PSCustomObject]@{ Name = $modName; Context = $context }
    }
    else {
        Install-Module -Name $modName -Scope CurrentUser -Force -AllowClobber
        Write-Host "✅ Installed module $modName in $context context."
    }
}

Write-Host "`n🔍 Installing PowerShell modules in current shell..."
foreach ($mod in $psModules) {
    Install-Or-Flag-Module $mod "current"
}

Write-Host "`n🔍 Installing PowerShell modules in PowerShell 7 context..."
foreach ($mod in $psModules) {
    $checkCmd = "if (Get-Module -ListAvailable -Name $mod) { exit 1 } else { Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber; exit 0 }"
    try {
        pwsh -NoLogo -NoProfile -Command $checkCmd
        if ($LASTEXITCODE -eq 1) {
            $upgradeModules += [PSCustomObject]@{ Name = $mod; Context = "pwsh" }
            Write-Host "✅ $mod already installed in pwsh context."
        }
        else {
            Write-Host "✅ Installed $mod in pwsh context."
        }
    }
    catch {
        Write-Warning "⚠️  Could not verify/install $mod in PowerShell 7. Is 'pwsh' in your PATH?"
    }
}

# -----------------------------
# Prompt to Upgrade All
# -----------------------------
Write-Host "`n📝 Review upgradeable items..."

if ($upgradeWinget.Count -gt 0) {
    Write-Host "📦 Winget packages with updates available:"
    $upgradeWinget | ForEach-Object { Write-Host " - $($_.Name)" }
}

if ($upgradeModules.Count -gt 0) {
    Write-Host "📦 PowerShell modules with existing installations:"
    $upgradeModules | ForEach-Object { Write-Host " - $($_.Name) ($($_.Context))" }
}

if ($upgradeWinget.Count -gt 0 -or $upgradeModules.Count -gt 0) {
    $response = Read-Host "`n⚠️  Do you want to upgrade all the above packages/modules? (y/n)"
    if ($response -match '^(y|yes)$') {
        Write-Host "`n🔁 Upgrading winget packages..."
        foreach ($pkg in $upgradeWinget) {
            winget upgrade --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent
        }

        Write-Host "`n🔁 Upgrading PowerShell modules (current context)..."
        foreach ($mod in $upgradeModules | Where-Object { $_.Context -eq "current" }) {
            Update-Module -Name $mod.Name -Force
        }

        Write-Host "`n🔁 Upgrading PowerShell modules (pwsh context)..."
        foreach ($mod in $upgradeModules | Where-Object { $_.Context -eq "pwsh" }) {
            $upgradeCmd = "Update-Module -Name $($mod.Name) -Force"
            pwsh -NoLogo -NoProfile -Command $upgradeCmd
        }

        Write-Host "`n✅ All selected packages/modules have been upgraded."
    }
    else {
        Write-Host "`n⏭️  Skipping upgrades as per your choice."
    }
}
else {
    Write-Host "`n✅ No upgrades needed — everything is up to date."
}
