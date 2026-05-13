# PowerShell Installer Script

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  Write-Warning "Run this script as Administrator."
  exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue))
{
  Write-Error "Winget is not installed or not in PATH."
  exit 1
}

# --- Config ---
$wingetApps = @(
  "Python.Python.3.9", "Python.Python.3.10", "Python.Python.3.11",
  "Python.Python.3.12", "Python.Python.3.13", "Python.Python.3.14", "Python.Launcher"
  "Microsoft.VisualStudioCode", "Microsoft.WindowsTerminal", "Microsoft.PowerShell",
  "Git.Git", "GitHub.GitLFS", "GitHub.cli", "Microsoft.PowerToys", "jj-vcs.jj", "AutoHotkey.AutoHotkey",
  "Starship.Starship", "eza-community.eza", "sharkdp.bat", "sharkdp.fd", "GoLang.Go",
  "ajeetdsouza.zoxide", "junegunn.fzf", "tldr-pages.tlrc", "Rustlang.Rustup", "LLVM.clangd",
  "Volta.Volta", "astral-sh.uv", "BurntSushi.ripgrep.MSVC", "LLVM.LLVM", "7zip.7zip",
  "rsteube.Carapace", "Bruno.Bruno", "Microsoft.AzureCLI", "Microsoft.SQLServerManagementStudio",
  "Zellij.Zellij", "Oven-sh.Bun", "uutils.coreutils", "Amazon.AWSCLI", "Amazon.SSMAgent", "GnuWin32.Tree",
  "GnuWin32.Make", "GnuWin32.Grep", "GnuWin32.DiffUtils", "GnuWin32.FindUtils", "GnuWin32.Which", 
  "zig.zig", "Kitware.CMake", "EclipseAdoptium.Temurin.21.JDK", "Microsoft.Azd", "MSYS2.MSYS2",
  "Docker.DockerCLI", "Docker.DockerCompose", "Fastfetch-cli.Fastfetch", "KDE.Filelight", "Nushell.Nushell",
  "Neovim.Neovim", "Helix.Helix", "Ninja-build.Ninja", "Postman.Postman", "SQLite.SQLite" #, "9PFXXSHC64H3" # Raycast
)

$psModules = @("PSReadLine", "PSFzf", "CompletionPredictor", "PowerType", "DisplayConfig", "CommandNotFound")
$upgradeWinget = @()
$upgradeModules = @()

# --- Winget Install ---
Write-Host "`nChecking winget packages..."
foreach ($id in $wingetApps)
{
  $result = winget list --id $id -e
  if ($result -match $id)
  {
    Write-Host "Already installed: $id"
    $upgradeWinget += $id
  } else
  {
    Write-Host "Installing: $id"
    winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
  }
}

# --- Install PowerShell modules in current shell ---
Write-Host "`nInstalling PowerShell modules (current shell)..."
foreach ($mod in $psModules)
{
  if (-not (Get-Module -ListAvailable -Name $mod))
  {
    Install-Module -Name $mod -Force -AllowClobber
    Write-Host "Installed: $mod"
  } else
  {
    Write-Host "Already exists: $mod"
    $upgradeModules += @{ Name = $mod; Context = "current" }
  }
}

# --- Install modules in pwsh ---
if (Get-Command pwsh -ErrorAction SilentlyContinue)
{
  Write-Host "`nInstalling modules in PowerShell 7 context..."
  foreach ($mod in $psModules)
  {
    $check = "if (-not (Get-Module -ListAvailable -Name $mod)) { Install-Module -Name $mod -Force -AllowClobber }"
    pwsh -NoLogo -NoProfile -Command $check
    if ($LASTEXITCODE -eq 1)
    {
      $upgradeModules += @{ Name = $mod; Context = "pwsh" }
    }
  }
} else
{
  Write-Host "PowerShell 7 (pwsh) not found. Skipping pwsh module installs."
}

# --- Install modules in powershell.exe ---
if (Get-Command powershell.exe -ErrorAction SilentlyContinue)
{
  Write-Host "`nInstalling modules in Windows PowerShell context..."
  foreach ($mod in @("PSReadLine", "PSFzf", "PowerType"))
  {
    $cmd = "if (-not (Get-Module -ListAvailable -Name $mod)) { Install-Module -Name $mod -Force -AllowClobber }"
    powershell.exe -NoLogo -NoProfile -Command $cmd
    if ($LASTEXITCODE -eq 1)
    {
      $upgradeModules += @{ Name = $mod; Context = "powershell" }
    }
  }
} else
{
  Write-Host "Windows PowerShell not found. Skipping legacy shell module installs."
}

Write-Host "For better shell compltetion using 'microsoft/inshellisense', please run the following command in your shell:"
Write-Host "npm install -g @microsoft/inshellisense"

Write-Host "`nInstallation and upgrade process completed."
