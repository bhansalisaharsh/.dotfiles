# Start stopwatch
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# --- Set Environent Variables ---
$MaximumHistoryCount = 32767

# --- Lazy-load shims for deferred functions ---
function Invoke-When-Available {
    param(
        [string]$Name,
        [string]$Type = "Function",
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Args
    )
    while (-not (Get-Command $Name -CommandType $Type -ErrorAction SilentlyContinue)) {
        if ($global:__initQueue -and $global:__initQueue.Count -gt 0) {
            & $global:__initQueue.Dequeue()
        }
        else {
            break
        }
    }
    if ($Type -eq "Function") {
        Remove-Item "function:\$Name" -ErrorAction SilentlyContinue
    }
    elseif ($Type -eq "Alias") {
        Remove-Item "alias:\$Name" -ErrorAction SilentlyContinue
    }
    & $Name @Args
}

# Shim all deferred functions
foreach ($fn in @(
        'powerhelp', 'ga', 'gaa', 'gcsm', 'gca', 'grbi', 'gd', 'gst', 'gco', 'gb', 'gm',
        'glg', 'glgp', 'glgg', 'grs', 'grst', 'gsta', 'gstaa', 'gf', 'gpl', 'gpu',
        'pkill', 'less', 'tree', 'la', 'll', 'cat'
    )) {
    Set-Item "function:\$fn" { param($args) Invoke-When-Available -Name $MyInvocation.MyCommand.Name -Args $args }
}

# --- 1. Immediate: Prompt, Navigation, CompletionPredictor, PowerType ---

# Starship prompt
if (-not (Test-Path function:\prompt -PathType Leaf -ErrorAction SilentlyContinue) -or
    ((Get-Content function:\prompt -ErrorAction Ignore) -notmatch 'starship')) {
    Invoke-Expression (&starship init powershell)
}

# Zoxide init
if (-not (Get-Command z -ErrorAction SilentlyContinue)) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Rebind cd and cdi to z/zi
if (Test-Path Function:\cd) { Remove-Item Function:\cd -Force }
if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force }
Set-Alias cd z -Force

if (Test-Path Function:\cdi) { Remove-Item Function:\cdi -Force }
if (Get-Alias cdi -ErrorAction SilentlyContinue) { Remove-Item Alias:cdi -Force }
Set-Alias cdi zi -Force

# # Load PowerType and CompletionPredictor immediately
# if (-not (Get-Module PowerType)) {
#     Import-Module PowerType -Global
#     Enable-PowerType
# }
# if (-not (Get-Module CompletionPredictor)) {
#     Import-Module CompletionPredictor -Global
# }

# PSReadLine config
if ($Host.UI.SupportsVirtualTerminal) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Set-PSReadLineKeyHandler -Key Tab -Function Complete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord

    # $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
    $env:CARAPACE_MATCH = 1
    Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    carapace _carapace | Out-String | Invoke-Expression
} else {
}

# --- 2. Cleanup Previous Lazy Loader ---
Get-EventSubscriber -SourceIdentifier PowerShell.OnIdle -ErrorAction SilentlyContinue |
ForEach-Object { Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force }

Remove-Variable -Name __initQueue -Scope Global -ErrorAction Ignore

# --- 3. Setup Lazy-Load Task Queue ---
$global:__initQueue = [System.Collections.Queue]::Synchronized([System.Collections.Queue]::new())

# Deferred: Modules
$__initQueue.Enqueue({
        Import-Module -Name PSFzf -Global -ErrorAction SilentlyContinue
    })

# Deferred: Aliases, Utils, Help
$__initQueue.Enqueue({
        New-Module -ScriptBlock {
            # Git Aliases
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

            # Utils
            function pkill {
                taskkill -f -im $(ps | rg "$args" | ForEach-Object { $_ -replace '^\s*\d+\s+', '' } | Select-Object -First 1).Trim()
            }

            Remove-Item "Alias:less" -Force -ErrorAction SilentlyContinue
            function less { Get-Content @args | more }

            Remove-Item "Alias:tree" -Force -ErrorAction SilentlyContinue
            function tree { eza --tree @args }

            Set-Alias ls eza -Force
            function la { eza -lahg --color @args }
            function ll { eza -lahg --color @args }
            Set-Alias cat bat -Force

            Remove-Item "Alias:grep" -Force -ErrorAction SilentlyContinue
            Remove-Item "Function:grep" -Force -ErrorAction SilentlyContinue
            Remove-Item "Cmdlet:grep" -Force -ErrorAction SilentlyContinue
            Set-Alias grep rg -Force

            # Unified Help Command
            function powerhelp {
                param (
                    [Parameter(Position = 0)][string]$Topic
                )
                switch ($Topic) {
                    "alias" {
                        Write-Host "`n🔗 Aliases:`n" -ForegroundColor Cyan
                        Get-Alias | Sort-Object Name | Format-Table Name, Definition

                        Write-Host "`n⚙️  Custom Functions:`n" -ForegroundColor Cyan
                        Get-Command -CommandType Function |
                        Where-Object {
                            $_.Name -in @(
                                'ga', 'gaa', 'gcsm', 'gca', 'grbi', 'gd', 'gst', 'gco', 'gb', 'gm',
                                'glg', 'glgp', 'glgg', 'grs', 'grst', 'gsta', 'gstaa', 'gf', 'gpl', 'gpu',
                                'pkill', 'less', 'tree', 'la', 'cat'
                            )
                        } |
                        Sort-Object Name |
                        Select-Object Name, @{Label = "Definition"; Expression = { $_.Definition -replace '\s+', ' ' } } |
                        Format-Table -AutoSize
                    }

                    "keys" {
                        Write-Host "`n⌨️  PowerShell Default Key Bindings:`n" -ForegroundColor Cyan

                        $defaultKeys = @(
                            'AcceptLine', 'BackwardChar', 'ForwardChar',
                            'BeginningOfLine', 'EndOfLine', 'ClearScreen',
                            'DeleteChar', 'BackwardDeleteChar',
                            'HistorySearchBackward', 'HistorySearchForward',
                            'YankLastArg'
                        )

                        Get-PSReadLineKeyHandler |
                        Where-Object { $_.Function -in $defaultKeys } |
                        Sort-Object Key |
                        ForEach-Object {
                            "{0,-15} → {1,-30} {2}" -f $_.Key, $_.Function, ""
                        }

                        Write-Host "`n🧠 Custom Key Bindings:`n" -ForegroundColor Cyan

                        Get-PSReadLineKeyHandler |
                        Where-Object { $_.Function -notin $defaultKeys } |
                        Sort-Object Key |
                        ForEach-Object {
                            "{0,-15} → {1,-30} {2}" -f $_.Key, $_.Function, ""
                        }
                    }

                    default {
                        Write-Host "Usage:" -ForegroundColor Yellow
                        Write-Host "  powerhelp alias   # Show aliases and custom functions"
                        Write-Host "  powerhelp keys    # Show keyboard shortcuts and movement keys"
                    }
                }
            }
        } | Import-Module -Global
    })

# Deferred: Keybindings (Unix-like + safe extras)
$__initQueue.Enqueue({
        Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
        Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine
        Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord
        Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
        Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteWord
        Set-PSReadLineKeyHandler -Key Alt+w -Function CopyWord
        Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
        Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
        Set-PSReadLineKeyHandler -Key Ctrl+y -Function Yank

        Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
        Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
        Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord
        Set-PSReadLineKeyHandler -Key Ctrl+h -Function BackwardDeleteChar
        Set-PSReadLineKeyHandler -Key Ctrl+Delete -Function KillWord
    })

# Deferred: ripgrep completions
$__initQueue.Enqueue({
        try {
            iex (& { (rg --generate=complete-powershell | Out-String) })
        }
        catch {
            Write-Warning "Failed to load ripgrep completions."
        }
    })

# Final config tweaks
$__initQueue.Enqueue({
        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
        }
    })

# --- 4. Idle Event Loader ---
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -SupportEvent -Action {
    if ($global:__initQueue.Count -gt 0) {
        & $global:__initQueue.Dequeue()
    }
    else {
        Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force
        Remove-Variable -Name __initQueue -Scope Global -Force
    }
}

# --- 5. Print load time ---
$sw.Stop()
Write-Host "✅ PowerShell prompt ready in $($sw.Elapsed.TotalSeconds) seconds`n"
