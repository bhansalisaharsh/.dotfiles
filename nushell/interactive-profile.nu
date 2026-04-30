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

def --env add-path-if-exists [candidate?: string] {
    if ($candidate != null and $candidate != "" and ($candidate | path exists)) {
        $env.Path = ($env.Path | prepend $candidate | uniq)
    }
}

def jump-or-warn [target?: string] {
    if ($target == null or $target == "") {
        print "Shortcut target does not exist on this machine."
    } else if not ($target | path exists) {
        print $"Shortcut target does not exist: ($target)"
    } else {
        cd $target
    }
}

def to-bash-path [value: string] {
    $value | str replace --all '\' '/'
}

let user_home = (($env | get -i USERPROFILE) | default $nu.home-path)
let one_drive_home = ($user_home | path join "OneDrive - Bain")
let desktop_dir = (
    if (($one_drive_home | path join "Desktop") | path exists) {
        $one_drive_home | path join "Desktop"
    } else if (($user_home | path join "Desktop") | path exists) {
        $user_home | path join "Desktop"
    } else {
        null
    }
)
let downloads_dir = (
    if (($user_home | path join "Downloads") | path exists) {
        $user_home | path join "Downloads"
    } else {
        null
    }
)
let dotfiles_dir = (
    if (($user_home | path join ".backups" ".dotfiles") | path exists) {
        $user_home | path join ".backups" ".dotfiles"
    } else if (($user_home | path join ".dotfiles") | path exists) {
        $user_home | path join ".dotfiles"
    } else {
        null
    }
)
let config_dir = (
    if (($user_home | path join ".config") | path exists) {
        $user_home | path join ".config"
    } else {
        null
    }
)
let desktopstuff_dir = (
    if ($desktop_dir != null and (($desktop_dir | path join ".desktopstuff") | path exists)) {
        $desktop_dir | path join ".desktopstuff"
    } else {
        $desktop_dir
    }
)
let downloads_packages_dir = (
    if ($downloads_dir != null and (($downloads_dir | path join "packages") | path exists)) {
        $downloads_dir | path join "packages"
    } else {
        $downloads_dir
    }
)
let git_bash = (
    if ('C:\Program Files\Git\bin\bash.exe' | path exists) {
        'C:\Program Files\Git\bin\bash.exe'
    } else if ('C:\Program Files\Git\usr\bin\bash.exe' | path exists) {
        'C:\Program Files\Git\usr\bin\bash.exe'
    } else {
        null
    }
)
let zsh_pastebin_script = (
    if (($user_home | path join ".nix-dots" "configs" "zsh" "ohmyzsh-custom" "zsh-pastebin.zsh") | path exists) {
        $user_home | path join ".nix-dots" "configs" "zsh" "ohmyzsh-custom" "zsh-pastebin.zsh"
    } else {
        null
    }
)

$env.config.history.max_size = 32767
$env.config.history.sync_on_enter = true
$env.config.history.isolation = false
$env.config.completions.case_sensitive = false

if ($config_dir != null) {
    $env.XDG_CONFIG_HOME = $config_dir
}

$env.ZELLIJ_AUTO_ATTACH = "true"
$env.ZELLIJ_AUTO_EXIT = "true"

if (has-cmd "nvim") {
    $env.VISUAL = "nvim"
    $env.EDITOR = "nvim"
}

if (has-cmd "go") {
    let go_path = (which go | get -i 0.path)
    let goroot = (
        if $go_path != null {
            $go_path | path dirname | path dirname
        } else {
            null
        }
    )
    let gopath = (
        (($env | get -i GOPATH)
        | default ($user_home | path join "go"))
    )

    if ($goroot != null and $goroot != "") {
        $env.GOROOT = $goroot
    }

    if ($gopath != null and $gopath != "") {
        $env.GOPATH = $gopath
        $env.GO_BIN = ($gopath | path join "bin")
        add-path-if-exists ($gopath | path join "bin")
    }
}

add-path-if-exists ($user_home | path join "bin")
add-path-if-exists ($user_home | path join ".local" "bin")
add-path-if-exists ($user_home | path join ".cargo" "bin")
add-path-if-exists ($user_home | path join ".bun" "bin")
add-path-if-exists ($user_home | path join ".spicetify")

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
        ^eza --tree --icons=auto ...$args
    } else {
        ^tree ...$args
    }
}

def --wrapped lsx [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza --color=auto --icons=auto ...$args
    } else {
        ^ls ...$args
    }
}

def --wrapped lss [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --icons=auto ...$args
    } else {
        ls -la ...$rest
    }
}

def --wrapped la [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --git --icons=auto ...$args
    } else {
        ls -la ...$rest
    }
}

def --wrapped ll [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --icons=auto ...$args
    } else {
        ls -la ...$rest
    }
}

def --wrapped hibernate [...rest: string] {
    ^shutdown /h ...$rest
}

def --wrapped pm-hib [...rest: string] {
    ^shutdown /h ...$rest
}

def --env .. [] {
    cd ..
}

def --env .d [] {
    jump-or-warn $desktopstuff_dir
}

def --env .Dk [] {
    jump-or-warn $desktop_dir
}

def --env .Dw [] {
    jump-or-warn $downloads_dir
}

def --env .Dp [] {
    jump-or-warn $downloads_packages_dir
}

def --env ..d [] {
    jump-or-warn $dotfiles_dir
}

def --env ..c [] {
    jump-or-warn $config_dir
}

def --env up2 [] {
    cd ../..
}

def --env up3 [] {
    cd ../../..
}

def --env up4 [] {
    cd ../../../..
}

def --wrapped mkalldir [...rest: path] {
    mkdir -v ...$rest
}

def --wrapped md [...rest: path] {
    mkdir -v ...$rest
}

def --wrapped vdiff [...rest: string] {
    if (has-cmd "diff") {
        ^diff --color -EZy ...$rest
    } else {
        print "diff is not installed."
    }
}

def --wrapped dsf [...rest: string] {
    if (has-cmd "diff-so-fancy") {
        ^diff -u ...$rest | ^diff-so-fancy
    } else {
        print "diff-so-fancy is not installed."
    }
}

def --wrapped weather [...rest: string] {
    if (($rest | length) == 0) {
        ^curl wttr.in
    } else {
        ^curl $"wttr.in/($rest | str join ' ')"
    }
}

def egrep [pattern: string, ...rest: string] {
    ^rg -i -e $pattern ...$rest
}

def export-aliases [outfile: path = "aliases.nu"] {
    scope aliases
    | sort-by name
    | each {|row| $"alias ($row.name) = ($row.expansion)" }
    | str join "\n"
    | save -f $outfile
}

def clipC [] {
    let data = if (($in | describe) == "nothing") {
        ""
    } else {
        $in | to text
    }

    $data | ^clip
}

def clipP [] {
    ^powershell -NoProfile -Command Get-Clipboard
}

alias xC = clipC
alias xP = clipP
alias wlC = clipC
alias wlP = clipP
alias wlCp = clipC
alias wlPp = clipP

def --env assignProxy [proxy: string, no_proxy?: string] {
    [
        http_proxy
        ftp_proxy
        https_proxy
        all_proxy
        HTTP_PROXY
        HTTPS_PROXY
        FTP_PROXY
        ALL_PROXY
    ] | each {|name|
        load-env { $name: $proxy }
    }

    if ($no_proxy != null and $no_proxy != "") {
        load-env {
            no_proxy: $no_proxy
            NO_PROXY: $no_proxy
        }
    }
}

def --env clrProxy [] {
    [
        http_proxy
        ftp_proxy
        https_proxy
        all_proxy
        HTTP_PROXY
        HTTPS_PROXY
        FTP_PROXY
        ALL_PROXY
        no_proxy
        NO_PROXY
    ] | each {|name|
        try { hide-env $name }
    }
}

def --env myProxy [] {
    let user = (input "Usr: ")
    let pass = (input --suppress-output "Password: ")
    print ""

    if ($user == "" or $pass == "") {
        print "Aborted."
        return
    }

    let proxy_value = $"http://($user):($pass)@ProxyServerAddress:Port"
    let no_proxy_value = "localhost,127.0.0.1,LocalAddress,LocalDomain.com"
    assignProxy $proxy_value $no_proxy_value
}

def --wrapped pastebin [...rest: string] {
    if ($git_bash == null or $zsh_pastebin_script == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $zsh_pastebin_script)
    ^$git_bash -lc 'source "$1"; shift; pastebin "$@"' _ $script ...$rest
}

def --wrapped pasteget [...rest: string] {
    if ($git_bash == null or $zsh_pastebin_script == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $zsh_pastebin_script)
    ^$git_bash -lc 'source "$1"; shift; pasteget "$@"' _ $script ...$rest
}

def --wrapped pbenc [...rest: string] {
    if ($git_bash == null or $zsh_pastebin_script == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $zsh_pastebin_script)
    ^$git_bash $script ...$rest
}

def powerhelp [topic?: string] {
    let custom_command_names = [
        ga gaa gcsm gca grbi gd gst gco gb gm
        glg glgp glgg grs grst gsta gstaa gf gl gp
        uncommit pkill less tree lsx lss la ll
        hibernate pm-hib mkalldir md vdiff dsf weather
        assignProxy clrProxy myProxy pastebin pasteget pbenc cat
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
alias ls = eza --color=auto --icons=auto
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
