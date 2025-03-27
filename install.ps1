# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Run this script as Administrator."
    exit
}

# Install CLI tools via winget
$wingetPackages = @(
    @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
    @{ Id = "Starship.Starship"; Name = "starship" },
    @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
    @{ Id = "sharkdp.bat"; Name = "bat" },
    @{ Id = "eza-community.eza"; Name = "eza" },
    @{ Id = "Git.Git"; Name = "git" },
    @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{ Id = "AutoHotkey.AutoHotkey"; Name = "AutoHotkey" },

    # Unix-style CLI tools
    @{ Id = "sharkdp.fd"; Name = "fd" },
    @{ Id = "junegunn.fzf"; Name = "fzf" },
    @{ Id = "uutils.coreutils"; Name = "coreutils (GNU clone)" },
    @{ Id = "mtoyoda.winless"; Name = "less" },
    @{ Id = "cyberbeing.moreutils"; Name = "moreutils" },
    @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep (rg)" }
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

Write-Host "`n✅ PowerShell 7, CLI tools, and modules installed successfully."
