def --wrapped pastebin [...rest: string] {
    let git_bash = (git-bash-path)
    let script_path = (zsh-pastebin-script-path)

    if ($git_bash == null or $script_path == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $script_path)
    ^$git_bash -lc 'source "$1"; shift; pastebin "$@"' _ $script ...$rest
}

def --wrapped pasteget [...rest: string] {
    let git_bash = (git-bash-path)
    let script_path = (zsh-pastebin-script-path)

    if ($git_bash == null or $script_path == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $script_path)
    ^$git_bash -lc 'source "$1"; shift; pasteget "$@"' _ $script ...$rest
}

def --wrapped pbenc [...rest: string] {
    let git_bash = (git-bash-path)
    let script_path = (zsh-pastebin-script-path)

    if ($git_bash == null or $script_path == null) {
        print "Git Bash or zsh-pastebin.zsh is not available."
        return
    }

    let script = (to-bash-path $script_path)
    ^$git_bash $script ...$rest
}
