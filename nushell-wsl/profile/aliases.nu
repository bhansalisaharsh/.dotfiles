def gcsm [...rest: string] {
    ^git commit --signoff --message ($rest | str join " ")
}

def --wrapped rem [...rest: string] {
    if (has-cmd "rip") {
        ^rip -i ...$rest
    } else {
        ^rm -i ...$rest
    }
}

def --wrapped less [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "less") {
        ^less ...$args
    } else {
        ^more ...$args
    }
}

def --wrapped tree [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza --tree --icons=auto ...$args
    } else if (has-cmd "tree") {
        ^tree ...$args
    } else {
        print "eza or tree is not installed."
    }
}

def --wrapped lsx [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza --color=auto --icons=auto ...$args
    } else {
        ^ls --color=auto ...$args
    }
}

def --wrapped lss [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --icons=auto ...$args
    } else {
        ls -la ...$args
    }
}

def --wrapped nla [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (($args | length) == 0) {
        ls -a
    } else {
        ls -a ...$args
    }
}

def --wrapped nll [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (($args | length) == 0) {
        ls -la
    } else {
        ls -la ...$args
    }
}

def --wrapped la [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --git --icons=auto ...$args
    } else {
        ls -a ...$args
    }
}

def --wrapped ll [...rest: string] {
    let args = (expand-external-args ...$rest)

    if (has-cmd "eza") {
        ^eza -lahg --color=auto --icons=auto ...$args
    } else {
        ls -la ...$args
    }
}

def --env .. [] {
    cd ..
}

def --env .d [] {
    jump-or-warn (desktopstuff-dir)
}

def --env .Dk [] {
    jump-or-warn (desktop-dir)
}

def --env .Dw [] {
    jump-or-warn (downloads-dir)
}

def --env .Dp [] {
    jump-or-warn (downloads-packages-dir)
}

def --env ..d [] {
    jump-or-warn (dotfiles-dir)
}

def --env ..c [] {
    jump-or-warn (config-dir)
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

def --wrapped vdiff [...rest: string] {
    ^diff --color -EZy ...$rest
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
    ^grep -iE $pattern ...$rest
}

def --wrapped sptui [...rest: string] {
    if (has-cmd "spotifyd") and (has-cmd "spt") and (has-cmd "bash") {
        ^bash -lc 'spotifyd --no-daemon >/dev/null 2>&1 & disown; spt "$@"' _ ...$rest
    } else {
        print "spotifyd, spt, or bash is not installed."
    }
}

def powerhelp [topic?: string] {
    let custom_command_names = [
        gcsm rem less tree lsx lss
        nla nll la ll
        vdiff dsf weather assignProxy clrProxy myProxy
        clipC clipP xC xP wlC wlP wlCp wlPp
        pastebin pasteget pbenc sptui
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
alias ga = git add
alias gaa = git add .
alias gca = git commit --amend
alias grbi = git rebase --interactive
alias gd = git diff
alias gst = git status
alias gco = git checkout
alias gb = git branch
alias gm = git merge
alias glg = git log '--show-notes=*' --stat
alias glgp = git log '--show-notes=*' --stat --patch
alias glgg = git log '--show-notes=*' --stat --graph
alias grs = git restore
alias grst = git restore --staged
alias gsta = git stash
alias gstaa = git stash apply
alias gf = git fetch --verbose
alias gl = git pull --verbose
alias gp = git push --verbose
alias uncommit = git reset --soft HEAD~1
alias ln = ln -i
alias ip = ip -c
alias pkill = pkill -e
alias hibernate = sudo systemctl hibernate
alias pm-hib = sudo pm-hibernate
alias mkalldir = mkdir -v
alias md = mkdir -v
alias zed = zeditor
