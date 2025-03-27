# Start stopwatch (optional)
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# --- 1. Immediate Prompt Initialization (starship + zoxide) ---

# Load Starship prompt if not already active
if (-not (Test-Path function:\prompt -PathType Leaf -ErrorAction SilentlyContinue) -or
    ((Get-Content function:\prompt -ErrorAction Ignore) -notmatch 'starship')) {
    Invoke-Expression (&starship init powershell)
}

# Load zoxide so 'z' and 'zi' work instantly
if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Rebind cd and cdi to z and zi for smart jumps
if (Test-Path Function:\cd) { Remove-Item Function:\cd -Force }
if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force }
Set-Alias cd z -Force

if (Test-Path Function:\cdi) { Remove-Item Function:\cdi -Force }
if (Get-Alias cdi -ErrorAction SilentlyContinue) { Remove-Item Alias:cdi -Force }
Set-Alias cdi zi -Force

# Basic PSReadLine setup for smoother typing
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineOption -EditMode Windows

# --- 2. Clear Previous Idle Setup (idempotent reload) ---

Get-EventSubscriber -SourceIdentifier PowerShell.OnIdle -ErrorAction SilentlyContinue |
ForEach-Object { Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force }

Remove-Variable -Name __initQueue -Scope Global -ErrorAction Ignore

# --- 3. Deferred Initialization Tasks (lazy load) ---

$global:__initQueue = [System.Collections.Queue]::Synchronized([System.Collections.Queue]::new())

# Lazy-load modules
$__initQueue.Enqueue({
        Import-Module -Name PSFzf -Global -ErrorAction SilentlyContinue
        Import-Module -Name PowerType -Global -ErrorAction SilentlyContinue
        Import-Module -Name CompletionPredictor -Global -ErrorAction SilentlyContinue
    })

# Define aliases and functions
$__initQueue.Enqueue({
        New-Module -ScriptBlock {
            # Git aliases
            Set-Alias g git
            function ga { git add @args }
            function gaa { git add . }
            function gcsm { git commit --signoff --message "$args" }
            function gca { git commit --amend }
            function grbi { git rebase --interactive @args }
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

            # Utilities
            function pkill {
                taskkill -f -im $(ps | rg "$args" | ForEach-Object { $_ -replace '^\s*\d+\s+', '' } | Select-Object -First 1).Trim()
            }

            # Custom less
            Remove-Item "Alias:less" -Force -ErrorAction SilentlyContinue
            function less { Get-Content @args | more }

            # Custom tree
            Remove-Item "Alias:tree" -Force -ErrorAction SilentlyContinue
            function tree { eza --tree @args }

            # Shortcuts
            Set-Alias ls eza -Force
            function la { eza -lahg --color }
            Set-Alias grep rg -Force
            function cat { bat @args }
        } | Import-Module -Global
    })

# Final tweaks after modules are available
$__initQueue.Enqueue({
        if (Get-Command Enable-PowerType -ErrorAction SilentlyContinue) {
            Enable-PowerType
        }

        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
        }

        # Optional: PSReadLine enhancements
        Set-PSReadLineKeyHandler -Key Tab -Function Complete
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
    })

# --- 4. Register Idle Handler to Process Deferred Queue ---

Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -SupportEvent -Action {
    if ($global:__initQueue.Count -gt 0) {
        & $global:__initQueue.Dequeue()
    }
    else {
        Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force
        Remove-Variable -Name __initQueue -Scope Global -Force
    }
}

# --- 5. (Optional) Display load time ---
$sw.Stop()
Write-Host "✅ PowerShell prompt ready in $($sw.Elapsed.TotalSeconds) seconds`n"
