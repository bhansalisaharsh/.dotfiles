# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Run this script as Administrator."
    exit
}

# Install CLI tools via winget
$wingetPackages = @(
    @{ Id = "Starship.Starship"; Name = "starship" },
    @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
    @{ Id = "sharkdp.bat"; Name = "bat" },
    @{ Id = "eza-community.eza"; Name = "eza" },
    @{ Id = "nvbn.thefuck"; Name = "thefuck" },
    @{ Id = "Git.Git"; Name = "git" },
    @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{ Id = "AutoHotkey.AutoHotkey"; Name = "AutoHotkey" }
)

foreach ($pkg in $wingetPackages) {
    Write-Host "Installing $($pkg.Name)..."
    winget install --id $($pkg.Id) --source winget --accept-package-agreements --accept-source-agreements --silent
}

# Install PowerShell modules
$psModules = @(
    @{ Name = "PSReadLine"; Scope = "CurrentUser" },
    @{ Name = "PSFzf"; Scope = "CurrentUser" },
    @{ Name = "CompletionPredictor"; Scope = "CurrentUser" }
)

foreach ($mod in $psModules) {
    Write-Host "Installing module $($mod.Name)..."
    Install-Module -Name $mod.Name -Scope $mod.Scope -Force -AllowClobber
}

Write-Host "`n✅ All dependencies installed successfully."
