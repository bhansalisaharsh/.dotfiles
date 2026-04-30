use std/config dark-theme

$env.config.history.max_size = 9999
$env.config.history.sync_on_enter = true
$env.config.history.isolation = false
$env.config.completions.case_sensitive = false
$env.config.highlight_resolved_externals = true
$env.config.color_config = (dark-theme)

export-env {
    $env.config = (
        ($env.config? | default {})
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

if $nu.is-interactive and (($env.TERM? | default "") != "dumb") {
    if (has-cmd "starship") {
        $env.STARSHIP_SHELL = "nu"
        $env.STARSHIP_SESSION_KEY = (random chars -l 16)
        $env.PROMPT_MULTILINE_INDICATOR = (^starship prompt --continuation)
        $env.PROMPT_INDICATOR = ""
        $env.PROMPT_COMMAND = {||
            let cmd_duration = ($env.CMD_DURATION_MS? | default 0)
            let last_exit = ($env.LAST_EXIT_CODE? | default 0)
            ^starship prompt --cmd-duration $cmd_duration $"--status=($last_exit)" --terminal-width (term size).columns
        }
        $env.PROMPT_COMMAND_RIGHT = {||
            let cmd_duration = ($env.CMD_DURATION_MS? | default 0)
            let last_exit = ($env.LAST_EXIT_CODE? | default 0)
            ^starship prompt --right --cmd-duration $cmd_duration $"--status=($last_exit)" --terminal-width (term size).columns
        }
        $env.config.render_right_prompt_on_last_line = true
    }

    if (has-cmd "carapace") {
        $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
        $env.CARAPACE_MATCH = "1"

        let carapace_completer = {|spans: list<string>|
            let cmd = ($spans | first)
            let expanded_alias = (
                scope aliases
                | where name == $cmd
                | get 0?.expansion
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
            ($env.config.completions.external | default {})
            | upsert enable true
            | upsert max_results 100
            | upsert completer { if $in == null { $carapace_completer } else { $in } }
        )
    }
}
