# Start timer to measure profile load time
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# --- Starship prompt (always load) ---
Invoke-Expression (&starship init powershell)

# --- Zoxide (always load early for cd/zi replacement) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (&zoxide init powershell | Out-String)

    # Rebind cd and cdi to zoxide
    if (Test-Path Function:\cd) { Remove-Item Function:\cd -Force }
    if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force }
    Set-Alias cd z -Force

    if (Test-Path Function:\cdi) { Remove-Item Function:\cdi -Force }
    if (Get-Alias cdi -ErrorAction SilentlyContinue) { Remove-Item Alias:cdi -Force }
    Set-Alias cdi zi -Force
}

# --- PSReadLine (safe to load eagerly) ---
if (-not (Get-Module PSReadLine)) {
    Import-Module PSReadLine
}
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord

# --- PSFzf Lazy Load ---
function fzfInit {
    if (-not (Get-Module PSFzf)) {
        Import-Module PSFzf
    }
}
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
Set-Alias fzfi fzfInit

# --- PowerType Lazy Load ---
function enableLazyPowerType {
    if (-not (Get-Module PowerType)) {
        Import-Module PowerType
        Enable-PowerType
    }
}
Set-Alias pt enableLazyPowerType

# --- CompletionPredictor Lazy Load ---
function loadCompletionPredictor {
    if (-not (Get-Module CompletionPredictor)) {
        Import-Module -Name CompletionPredictor
    }
}
Set-Alias lcp loadCompletionPredictor

# --- Aliases ---
Set-Alias lsx Get-ChildItem -Force
if (Get-Alias ls -ErrorAction SilentlyContinue) { Remove-Item Alias:ls -Force }
Set-Alias ls eza -Force

function la { eza -lahg --color }

Set-Alias cdx Set-Location -Force
Set-Alias catx Get-Content -Force
if (Get-Alias cat -ErrorAction SilentlyContinue) { Remove-Item Alias:cat -Force }
function cat { bat @args }

Remove-Item "Alias:less" -Force -ErrorAction SilentlyContinue
# Remove-Item "Function:less" -Force -ErrorAction SilentlyContinue
function less { Get-Content @args | more }

Remove-Item "Alias:tree" -Force -ErrorAction SilentlyContinue
# Remove-Item "Function:tree" -Force -ErrorAction SilentlyContinue
function tree { eza --tree @args }

Set-Alias grep rg -Force

# --- Git Aliases (Global, always available) ---
Set-Alias g git
function ga { git add @args }
function gaa { git add . }
function gcsm { git commit --signoff --message "$args" }
function gca { git commit --amend }
function grbi { git rebase --interactive $args }
function gd { git diff @args }
function gst { git status @args }
function gco { git checkout @args }
function gb { git branch @args }
function gm { git merge @args }
function glg { git log --show-notes="*" --stat @args }
function glgp { git log --show-notes="*" --stat --patch @args }
function glgg { git log --show-notes="*" --stat --graph @args }
function grs { git restore @args }
function grst { git restore --staged @args }
function gsta { git stash }
function gstaa { git stash apply }
function gf { git fetch --verbose }
function gpl {
    if ($args.Count -eq 0) { git pull --verbose }
    elseif ($args.Count -eq 1) { git pull --verbose $args }
    else { git pull --verbose -- @args }
}
function gpu {
    if ($args.Count -eq 0) { git push --verbose }
    elseif ($args.Count -eq 1) { git push --verbose $args }
    else { git push --verbose -- @args }
}

# --- Utility ---
function pkill {
    taskkill -f -im $(ps | rg "$args" | cut -b 42-49 | head -n 1).Trim()
}

# --- Show load time ---
$sw.Stop()
Write-Host "✅ PowerShell profile loaded in $($sw.Elapsed.TotalSeconds) seconds`n"
