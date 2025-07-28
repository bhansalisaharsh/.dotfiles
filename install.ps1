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
  "Starship.Starship", "eza-community.eza", "sharkdp.bat", "sharkdp.fd",
  "ajeetdsouza.zoxide", "junegunn.fzf", "BurntSushi.ripgrep.MSVC",
  "Git.Git", "Microsoft.WindowsTerminal", "Microsoft.PowerShell",
  "Microsoft.PowerToys", "AutoHotkey.AutoHotkey", "tldr-pages.tlrc",
  "GitHub.cli", "rsteube.Carapace", "Volta.Volta", "Nushell.Nushell", "Python.Python.3.9", "Python.Python.3.10", "Python.Python.3.11", "Python.Python.3.12", "Python.Python.3.13", "Microsoft.VisualStudioCode"
)

$psModules = @("PSReadLine", "PSFzf", "CompletionPredictor", "PowerType", "DisplayConfig")
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
