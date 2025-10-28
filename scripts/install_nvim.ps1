
# install_nvim.ps1

$apps = @(
    @{ Id = "Git.Git";       Name = "Git" },
    @{ Id = "Zig.Zig";       Name = "Zig" },
    @{ Id = "Neovim.Neovim"; Name = "Neovim" }
)

$toInstall = @()
$toUpgrade = @()

# Step 1: Determine which packages need install or upgrade
foreach ($app in $apps) {
    $found = winget list --id $app.Id 2>$null | Select-String $app.Id
    if ($found) {
        $toUpgrade += $app
    } else {
        $toInstall += $app
    }
}

# Step 2: Install missing packages
foreach ($app in $toInstall) {
    Write-Host "Installing $($app.Name)..."
    winget install --id $app.Id --silent
}

# Step 3: Prompt once for upgrading already-installed packages
if ($toUpgrade.Count -gt 0) {
    Write-Host "`nThe following packages are already installed:"
    foreach ($app in $toUpgrade) {
        Write-Host " - $($app.Name)"
    }

    $response = Read-Host "`nDo you want to upgrade these packages? (y/N)"
    if ($response -match '^[Yy]$') {
        foreach ($app in $toUpgrade) {
            Write-Host "Upgrading $($app.Name)..."
            winget upgrade --id $app.Id --silent
        }
    } else {
        Write-Host "Skipped upgrades."
    }
}

# Step 4: Backup existing configs
$nvimPath = Join-Path $env:LOCALAPPDATA "nvim"
$nvimDataPath = Join-Path $env:LOCALAPPDATA "nvim-data"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

if (Test-Path $nvimPath) {
    $backupPath = "$nvimPath.bak_$timestamp"
    $confirm = Read-Host "`nFound existing 'nvim'. Move to backup at '$backupPath'? (y/N)"
    if ($confirm -match '^[Yy]$') {
        Move-Item $nvimPath $backupPath
        Write-Host "Backed up nvim config to $backupPath."
    } else {
        Write-Host "Skipped nvim config backup."
    }
}

if (Test-Path $nvimDataPath) {
    $backupDataPath = "$nvimDataPath.bak_$timestamp"
    $confirm = Read-Host "Found existing 'nvim-data'. Move to backup at '$backupDataPath'? (y/N)"
    if ($confirm -match '^[Yy]$') {
        Move-Item $nvimDataPath $backupDataPath
        Write-Host "Backed up nvim-data to $backupDataPath."
    } else {
        Write-Host "Skipped nvim-data backup."
    }
}

# Step 5: Clone LazyVim starter
$confirm = Read-Host "`nClone LazyVim starter into '$nvimPath'? This will overwrite existing content. (y/N)"
if ($confirm -match '^[Yy]$') {
    git clone https://github.com/LazyVim/starter $nvimPath
    Write-Host "Cloned LazyVim starter."

    $gitDir = Join-Path $nvimPath ".git"
    if (Test-Path $gitDir) {
        $confirmRemove = Read-Host "Remove '$gitDir' to clean up the clone? (y/N)"
        if ($confirmRemove -match '^[Yy]$') {
            Remove-Item $gitDir -Recurse -Force
            Write-Host "Removed .git directory."
        } else {
            Write-Host "Skipped .git removal."
        }
    }
} else {
    Write-Host "Skipped LazyVim clone."
}

# Step 6: Theme copy reminder
Write-Host "`n[Reminder]"
Write-Host "If you have a theme config in your current directory (e.g. ./nvim/lua/plugins/theme.lua), you can copy it using:"
Write-Host "`nCopy-Item `"$((Get-Location).Path)\nvim\lua\plugins\theme.lua`" `"$nvimPath\lua\plugins\theme.lua`""
Write-Host "`nOR in bash/git-bash:"
Write-Host "cp \$(pwd)\nvim\lua\plugins\theme.lua `"\$nvimPath\lua\plugins\theme.lua`""
