def has-cmd [name: string] {
    (which $name | length) > 0
}

def expand-external-args [...rest: string] {
    let home = (
        ($env | get -i USERPROFILE)
        | default (($env | get -i HOME) | default $nu.home-path)
    )

    $rest | each {|arg|
        if $arg == "~" {
            $home
        } else if (($arg | str starts-with "~/") or ($arg | str starts-with "~\\")) {
            $home | path join ($arg | str substring 2..)
        } else {
            $arg
        }
    }
}

def --wrapped ga [...rest: string] {
    ^git add ...$rest
}

def gaa [] {
    ^git add .
}

def gcsm [...rest: string] {
    ^git commit --signoff --message ($rest | str join " ")
}

def --wrapped gca [...rest: string] {
    if (($rest | length) == 0) {
        ^git commit --amend
    } else {
        ^git commit --amend ...$rest
    }
}

def --wrapped grbi [...rest: string] {
    ^git rebase --interactive ...$rest
}

def --wrapped gd [...rest: string] {
    ^git diff ...$rest
}

def --wrapped gst [...rest: string] {
    ^git status ...$rest
}

def --wrapped gco [...rest: string] {
    ^git checkout ...$rest
}

def --wrapped gb [...rest: string] {
    ^git branch ...$rest
}

def --wrapped gm [...rest: string] {
    ^git merge ...$rest
}

def --wrapped glg [...rest: string] {
    ^git log '--show-notes=*' --stat ...$rest
}

def --wrapped glgp [...rest: string] {
    ^git log '--show-notes=*' --stat --patch ...$rest
}

def --wrapped glgg [...rest: string] {
    ^git log '--show-notes=*' --stat --graph ...$rest
}

def --wrapped grs [...rest: string] {
    ^git restore ...$rest
}

def --wrapped grst [...rest: string] {
    ^git restore --staged ...$rest
}

def gsta [] {
    ^git stash
}

def --wrapped gstaa [...rest: string] {
    ^git stash apply ...$rest
}

def --wrapped gf [...rest: string] {
    ^git fetch --verbose ...$rest
}

def --wrapped gl [...rest: string] {
    if (($rest | length) == 0) {
        ^git pull --verbose
    } else if (($rest | length) == 1) {
        ^git pull --verbose ...$rest
    } else {
        ^git pull --verbose -- ...$rest
    }
}

def --wrapped gp [...rest: string] {
    if (($rest | length) == 0) {
        ^git push --verbose
    } else if (($rest | length) == 1) {
        ^git push --verbose ...$rest
    } else {
        ^git push --verbose ...$rest
    }
}

def uncommit [] {
    ^git reset --soft HEAD~1
}

def pkill [pattern: string] {
    let match = (
        ps
        | where {|row| $row.name =~ $pattern }
        | get -i 0
    )

    if ($match == null) {
        print "No matching process found."
    } else {
        ^taskkill /f /pid ($match.pid | into string)
    }
}

def --wrapped less [...rest: string] {
    let args = (expand-external-args ...$rest)
    ^more ...$args
}

def --wrapped tree [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza --tree ...$args
    } else {
        ^tree ...$args
    }
}

def --wrapped la [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color ...$args
    } else {
        ls -la ...$rest
    }
}

def --wrapped ll [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color ...$args
    } else {
        ls -la ...$rest
    }
}

def powerhelp [topic?: string] {
    let custom_command_names = [
        ga gaa gcsm gca grbi gd gst gco gb gm
        glg glgp glgg grs grst gsta gstaa gf gl gp
        uncommit pkill less tree la ll cat
    ]

    match ($topic | default "") {
        "alias" => {
            print "\nAliases:\n"
            scope aliases
            | sort-by name
            | select name expansion
            | each {|row| print $"($row.name) -> ($row.expansion)" }

            print "\nCustom Commands:\n"
            $custom_command_names
            | each {|name|
                {
                    name: $name
                    definition: (view source $name | lines | str join " ")
                }
            }
            | table
        }
        "keys" => {
            print "\nDefault Key Bindings:\n"
            keybindings default
            | select mode modifier code event
            | table

            print "\nCustom Key Bindings:\n"
            ($env.config.keybindings | default [])
            | select name modifier keycode mode event
            | table
        }
        _ => {
            print "Usage:"
            print "  powerhelp alias   # Show aliases and custom commands"
            print "  powerhelp keys    # Show keyboard shortcuts"
        }
    }
}

alias g = git
alias grep = rg
alias ls = eza
alias cat = bat

export-env {
    $env.config = (
        ($env | get -i config)
        | default {}
        | upsert hooks { default {} }
        | upsert hooks.env_change { default {} }
        | upsert hooks.env_change.PWD { default [] }
    )

    let zoxide_hooked = (
        $env.config.hooks.env_change.PWD
        | any { try { get __zoxide_hook } catch { false } }
    )

    if not $zoxide_hooked {
        $env.config.hooks.env_change.PWD = (
            $env.config.hooks.env_change.PWD
            | append {
                __zoxide_hook: true
                code: {|_, dir|
                    if (has-cmd "zoxide") {
                        ^zoxide add -- $dir
                    }
                }
            }
        )
    }
}

def --env --wrapped __zoxide_z [...rest: string] {
    if not (has-cmd "zoxide") {
        print "zoxide is not installed."
        return
    }

    let path = match $rest {
        [] => { "~" }
        [ "-" ] => { "-" }
        [ $arg ] if (($arg | path expand | path type) == "dir") => { $arg }
        _ => {
            ^zoxide query --exclude $env.PWD -- ...$rest
            | str trim -r -c "\n"
        }
    }

    cd $path
}

def --env --wrapped __zoxide_zi [...rest: string] {
    if not (has-cmd "zoxide") {
        print "zoxide is not installed."
        return
    }

    cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

alias z = __zoxide_z
alias zi = __zoxide_zi
alias cd = z
alias cdi = zi

if $nu.is-interactive and ((($env | get -i TERM) | default "") != "dumb") {
    if (has-cmd "starship") {
        $env.STARSHIP_SHELL = "nu"
        $env.STARSHIP_SESSION_KEY = (random chars -l 16)
        $env.PROMPT_MULTILINE_INDICATOR = (^starship prompt --continuation)
        $env.PROMPT_INDICATOR = ""
        $env.PROMPT_COMMAND = {||
            let cmd_duration = (($env | get -i CMD_DURATION_MS) | default 0)
            let last_exit = (($env | get -i LAST_EXIT_CODE) | default 0)
            ^starship prompt --cmd-duration $cmd_duration $"--status=($last_exit)" --terminal-width (term size).columns
        }
        $env.PROMPT_COMMAND_RIGHT = {||
            let cmd_duration = (($env | get -i CMD_DURATION_MS) | default 0)
            let last_exit = (($env | get -i LAST_EXIT_CODE) | default 0)
            ^starship prompt --right --cmd-duration $cmd_duration $"--status=($last_exit)" --terminal-width (term size).columns
        }
        $env.config.render_right_prompt_on_last_line = true
    }

    if (has-cmd "carapace") {
        $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,powershell"
        $env.CARAPACE_MATCH = "1"

        let carapace_bin = ($env.APPDATA | path join "carapace" "bin")
        if ($carapace_bin | path exists) {
            $env.Path = ($env.Path | prepend $carapace_bin | uniq)
        }

        let carapace_completer = {|spans: list<string>|
            let cmd = ($spans | first)
            let expanded_alias = (
                scope aliases
                | where name == $cmd
                | get -i 0.expansion
            )

            let spans = (
                if $expanded_alias != null {
                    $spans
                    | skip 1
                    | prepend ($expanded_alias | split row " " | take 1 | str replace --regex '\.exe$' "")
                } else {
                    $spans
                    | skip 1
                    | prepend ($cmd | str replace --regex '\.exe$' "")
                }
            )

            let command = ($spans | first)
            ^carapace $command nushell ...$spans | from json
        }

        $env.config.completions.external = (
            $env.config.completions.external
            | default {}
            | upsert enable true
            | upsert max_results 100
            | upsert completer { if $in == null { $carapace_completer } else { $in } }
        )
    }
}
