# Start stopwatch
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# --- Basic environment ---
$MaximumHistoryCount = 32767
$env:GIT_ASK_YESNO = 'false'

# --- Terminal capability detection ---
$script:IsDumbTerminal = $env:TERM -eq 'dumb'
$script:IsInteractiveHost = $Host.Name -match 'ConsoleHost|Visual Studio Code Host'
$script:HasVT = $false

try {
    if ($Host.UI -and $Host.UI.SupportsVirtualTerminal) {
        $script:HasVT = $true
    }
}
catch {
    $script:HasVT = $false
}

# In automation / agentic / dumb terminals, skip prompt customization entirely.
# This avoids starship, zoxide, PSReadLine, and ANSI/control-sequence issues.
if ($script:IsDumbTerminal -or -not $script:IsInteractiveHost) {
    $sw.Stop()
    return
}

# --- Helper predicates ---
function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-ModuleAvailable {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue)
}

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

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        & $Name @Args
    }
    else {
        Write-Warning "'$Name' is not available."
    }
}

# Shim all deferred functions
foreach ($fn in @(
    'powerhelp', 'ga', 'gaa', 'gcsm', 'gca', 'grbi', 'gd', 'gst', 'gco', 'gb', 'gm',
    'glg', 'glgp', 'glgg', 'glog', 'grs', 'grst', 'gsta', 'gstaa', 'gf', 'gl', 'gp', 'uncommit',
    'pkill', 'less', 'tree', 'la', 'll', 'cat', 'k'
)) {
    Set-Item "function:\$fn" { param($args) Invoke-When-Available -Name $MyInvocation.MyCommand.Name -Args $args }
}

# --- 1. Immediate: prompt, navigation, predictor modules ---

# Starship prompt
if (Test-CommandExists 'starship') {
    try {
        if (-not (Test-Path function:\prompt -PathType Leaf -ErrorAction SilentlyContinue) -or
            ((Get-Content function:\prompt -ErrorAction Ignore) -notmatch 'starship')) {
            Invoke-Expression (& starship init powershell)
        }
    }
    catch {
        # Ignore prompt init failures in odd terminals
    }
}

# Zoxide init
$script:ZoxideLoaded = $false
if (Test-CommandExists 'zoxide') {
    try {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
        $script:ZoxideLoaded = [bool](Get-Command z -ErrorAction SilentlyContinue)
    }
    catch {
        $script:ZoxideLoaded = $false
    }
}

# Rebind cd and cdi only if zoxide actually loaded
if ($script:ZoxideLoaded) {
    if (Test-Path Function:\cd) { Remove-Item Function:\cd -Force -ErrorAction SilentlyContinue }
    if (Get-Alias cd -ErrorAction SilentlyContinue) { Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue }
    Set-Alias cd z -Force

    if (Test-Path Function:\cdi) { Remove-Item Function:\cdi -Force -ErrorAction SilentlyContinue }
    if (Get-Alias cdi -ErrorAction SilentlyContinue) { Remove-Item Alias:cdi -Force -ErrorAction SilentlyContinue }

    if (Get-Command zi -ErrorAction SilentlyContinue) {
        Set-Alias cdi zi -Force
    }
}

# Load PowerType and CompletionPredictor if available
if ((Test-ModuleAvailable 'PowerType') -and -not (Get-Module PowerType)) {
    try {
        Import-Module PowerType -Global -ErrorAction Stop
        if (Get-Command Enable-PowerType -ErrorAction SilentlyContinue) {
            Enable-PowerType
        }
    }
    catch {}
}

if ((Test-ModuleAvailable 'CompletionPredictor') -and -not (Get-Module CompletionPredictor)) {
    try {
        Import-Module CompletionPredictor -Global -ErrorAction Stop
    }
    catch {}
}

# PSReadLine config only in VT-capable terminals
if ($script:HasVT -and (Test-ModuleAvailable 'PSReadLine')) {
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
        Set-PSReadLineOption -PredictionViewStyle InlineView
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd

        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord "Ctrl+'" -Function ForwardChar

        Set-PSReadLineOption -Colors @{ Selection = "`e[7m" }
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine

        if (Test-CommandExists 'carapace') {
            $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense,powershell'
            $env:CARAPACE_MATCH = '1'

            try {
                carapace _carapace | Out-String | Invoke-Expression
            }
            catch {}
        }

        function Register-CarapaceCompletion {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory, Position = 0)]
                [string[]] $AliasNames,

                [Parameter(Mandatory, Position = 1)]
                [string]   $Executable
            )

            if (-not $script:HasVT) { return }
            if (-not (Get-Variable _carapace_lazy -Scope Script -ErrorAction SilentlyContinue) -and
                -not (Get-Variable _carapace_lazy -Scope Global -ErrorAction SilentlyContinue)) {
                return
            }

            $names = @($AliasNames) + $Executable
            Register-ArgumentCompleter -Native -CommandName $names -ScriptBlock $_carapace_lazy
        }
    }
    catch {
        # Ignore PSReadLine config errors in constrained terminals
    }
}

# --- 2. Cleanup previous lazy loader ---
Get-EventSubscriber -SourceIdentifier PowerShell.OnIdle -ErrorAction SilentlyContinue |
    ForEach-Object { Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force }

Remove-Variable -Name __initQueue -Scope Global -ErrorAction Ignore

# --- 3. Setup lazy-load task queue ---
$global:__initQueue = [System.Collections.Queue]::Synchronized([System.Collections.Queue]::new())

# Deferred: modules
$__initQueue.Enqueue({
    if (Test-ModuleAvailable 'PSFzf') {
        try { Import-Module -Name PSFzf -Global -ErrorAction Stop } catch {}
    }

    if (Test-ModuleAvailable 'Microsoft.WinGet.CommandNotFound') {
        try { Import-Module -Name Microsoft.WinGet.CommandNotFound -ErrorAction Stop } catch {}
    }
})

# Deferred: aliases, utils, help
$__initQueue.Enqueue({
    New-Module -ScriptBlock {
        function Test-LocalCommandExists {
            param([Parameter(Mandatory)][string]$Name)
            return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
        }

        # Git aliases
        if (Test-LocalCommandExists 'git') {
            Set-Alias g git -Force

            function ga { git add @args }
            function gaa { git add . }
            function gcsm { git commit --signoff --message "$args" }

            function gca {
                if ($args.Count -eq 0) { git commit --amend }
                elseif ($args.Count -eq 1) { git commit --amend $args }
                else { git commit --amend @args }
            }

            function grbi { git rebase --interactive @args }
            function gd { git diff @args }
            function gst { git status @args }
            function gco { git checkout @args }
            function gb { git branch @args }
            function gm { git merge @args }
            function glg { git log --show-notes="*" --stat @args }
            function glgp { git log --show-notes="*" --stat --patch @args }
            function glgg { git log --show-notes="*" --stat --graph @args }
            function glog { git log --oneline --show-notes="*" --graph @args }
            function grs { git restore @args }
            function grst { git restore --staged @args }
            function gsta { git stash }
            function gstaa { git stash apply }
            function gf { git fetch --verbose }

            function gl {
                if ($args.Count -eq 0) { git pull --verbose }
                elseif ($args.Count -eq 1) { git pull --verbose $args }
                else { git pull --verbose -- @args }
            }

            Remove-Item "Alias:gp" -Force -ErrorAction SilentlyContinue
            Remove-Item "Function:gp" -Force -ErrorAction SilentlyContinue
            Remove-Item "Cmdlet:gp" -Force -ErrorAction SilentlyContinue

            function gp {
                if ($args.Count -eq 0) { git push --verbose }
                elseif ($args.Count -eq 1) { git push --verbose $args }
                else { git push --verbose @args }
            }

            function uncommit { git reset --soft HEAD~1 }
        }

        # Utils
        function pkill {
            if (-not (Test-LocalCommandExists 'rg')) {
                Write-Warning "ripgrep (rg) is not installed."
                return
            }

            $pidMatch = ps | rg @args | ForEach-Object {
                $_ -replace '.*?(\d{4,7}).*', '$1'
            } | Select-Object -First 1

            if ($pidMatch) {
                taskkill -f -pid $pidMatch.Trim()
            }
            else {
                Write-Warning "No matching process found."
            }
        }

        Remove-Item "Alias:less" -Force -ErrorAction SilentlyContinue
        function less { Get-Content @args | more }

        Remove-Item "Alias:tree" -Force -ErrorAction SilentlyContinue
        function tree {
            if (Test-LocalCommandExists 'eza') {
                eza --icons --tree @args
            }
            else {
                cmd /c tree
            }
        }

        if (Test-LocalCommandExists 'eza') {
            Set-Alias ls eza -Force
            function la { eza -lahg --color --icons @args }
            function ll { eza -lahg --color --icons @args }
        }
        else {
            function la { Get-ChildItem -Force @args }
            function ll { Get-ChildItem -Force @args }
        }

        if (Test-LocalCommandExists 'bat') {
            Set-Alias cat bat -Force
        }
        else {
            function cat { Get-Content @args }
        }

        Remove-Item "Alias:grep" -Force -ErrorAction SilentlyContinue
        Remove-Item "Function:grep" -Force -ErrorAction SilentlyContinue
        Remove-Item "Cmdlet:grep" -Force -ErrorAction SilentlyContinue

        if (Test-LocalCommandExists 'rg') {
            Set-Alias grep rg -Force
        }

        Set-Alias k kubectl -Force

        # Unified help command
        function powerhelp {
            param (
                [Parameter(Position = 0)]
                [string]$Topic
            )

            switch ($Topic) {
                "alias" {
                    Write-Host "`nAliases:`n" -ForegroundColor Cyan
                    Get-Alias | Sort-Object Name | Format-Table Name, Definition

                    Write-Host "`nCustom Functions:`n" -ForegroundColor Cyan
                    Get-Command -CommandType Function |
                        Where-Object {
                            $_.Name -in @(
                                'ga', 'gaa', 'gcsm', 'gca', 'grbi', 'gd', 'gst', 'gco', 'gb', 'gm',
                                'glg', 'glgp', 'glgg', 'glog', 'grs', 'grst', 'gsta', 'gstaa', 'gf', 'gl', 'gp',
                                'pkill', 'less', 'tree', 'la', 'll', 'cat', 'k'
                            )
                        } |
                        Sort-Object Name |
                        Select-Object Name, @{Label = "Definition"; Expression = { $_.Definition -replace '\s+', ' ' } } |
                        Format-Table -AutoSize
                }

                "keys" {
                    if (-not (Get-Command Get-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {
                        Write-Host "PSReadLine is not available in this terminal." -ForegroundColor Yellow
                        return
                    }

                    Write-Host "`nPowerShell Default Key Bindings:`n" -ForegroundColor Cyan

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
                            "{0,-15} -> {1,-30}" -f $_.Key, $_.Function
                        }

                    Write-Host "`nCustom Key Bindings:`n" -ForegroundColor Cyan

                    Get-PSReadLineKeyHandler |
                        Where-Object { $_.Function -notin $defaultKeys } |
                        Sort-Object Key |
                        ForEach-Object {
                            "{0,-15} -> {1,-30}" -f $_.Key, $_.Function
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

# Deferred: keybindings
$__initQueue.Enqueue({
    if (-not $script:HasVT) { return }
    if (-not (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) { return }

    try {
        Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
        Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine
        Set-PSReadLineKeyHandler -Key Ctrl+p -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key Ctrl+n -Function HistorySearchForward
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
    }
    catch {}
})

# Deferred: ripgrep completions
$__initQueue.Enqueue({
    if (Test-CommandExists 'rg') {
        try {
            iex (& { (rg --generate=complete-powershell | Out-String) })
        }
        catch {}
    }
})

# Final config tweaks
$__initQueue.Enqueue({
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        try {
            Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
        }
        catch {}
    }
})

# --- 4. Idle event loader ---
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -SupportEvent -Action {
    if ($global:__initQueue.Count -gt 0) {
        & $global:__initQueue.Dequeue()
    }
    else {
        Unregister-Event -SourceIdentifier PowerShell.OnIdle -Force
        Remove-Variable -Name __initQueue -Scope Global -Force -ErrorAction SilentlyContinue
    }
} | Out-Null

# --- 5. Print load time ---
$sw.Stop()
Write-Host "PowerShell prompt ready in $($sw.Elapsed.TotalSeconds) seconds`n"

