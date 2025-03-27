# init starship and zoxide
Invoke-Expression (&starship init powershell)
Invoke-Expression (&zoxide init powershell | Out-String)

# init PSReadline, PowerType, and PSFzf
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# Set-PSReadLineOption -Colors @{ InlinePrediction = '#875f5f'}
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord

Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider ‘Ctrl+f’ -PSReadLineChordReverseHistory ‘Ctrl+r’

# Import-Module PowerType
# Enable-PowerType
Import-Module -Name CompletionPredictor

# # enable thefuck
# $env:PYTHONIOENCODING="utf-8"
# iex "$(thefuck — alias)"

# set ls -> eza and cd -> z aliases
Set-Alias lsx Get-ChildItem -Force
Remove-Item Alias:ls -Force
Set-Alias ls eza -Force
function la {eza -lahg --color}
Set-Alias cdx Set-Location -Force
Remove-Item Alias:cd -Force
Set-Alias cd z -Force
Set-Alias catx Get-Content -Force
Remove-Item Alias:cat -Force
function cat {bat @args}
Set-Alias grep rg -Force

# git aliases
Set-Alias g git
function ga {git add @args}
function gaa {git add .}
function gcsm {git commit --signoff --message "$args"}
function gca {git commit --amend}
function grbi {git rebase --interactive $args}
function gd {git diff $args}
function gst {git status $args}
function gco {git checkout $args}
function gb {git branch $args}
function gm {git merge $args}
function glg {git log --show-notes="*" --stat $args}
function glgp {git log --show-notes="*" --stat --patch $args}
function glgg {git log --show-notes="*" --stat --graph $args}
function grs {git restore $args}
function grst {git restore --staged $args}
function gsta {git stash}
function gstaa {git stash apply}
function gf {git fetch --verbose}
# function gpl {git pull --verbose origin $(git branch --show-current)}
# function gpu {git push --verbose}
function gpl {
    if ($args.Count -eq 0) {
        git pull --verbose
    } elseif ($args.Count -eq 1) {
        git pull --verbose $args
    } else {
        git pull --verbose -- @args
    }
}
function gpu {
    if ($args.Count -eq 0) {
        git push --verbose
    } elseif ($args.Count -eq 1) {
        git push --verbose $args
    } else {
        git push --verbose -- @args
    }
}
# function gsta {
#     if ($args.Count -eq 0) {
#         git stash
#     } elseif ($args.Count -eq 1) {
#         git stash $args
#     } else {
#         git stash -- @args
#     }
# }
# function gstaa {
#     if ($args.Count -eq 0) {
#         git stash apply
#     } elseif ($args.Count -eq 1) {
#         git stash apply $args
#     } else {
#         git stash apply -- @args
#     }
# }



function pkill { taskkill -f -im $(ps | grep "$args" | cut -b 42-49 | head -n 1).Trim() }
