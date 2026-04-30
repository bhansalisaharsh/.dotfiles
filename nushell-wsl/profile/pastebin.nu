def --wrapped pastebin [...rest: string] {
    let script_path = (zsh-pastebin-script-path)
    let args = (expand-external-args ...$rest)

    if not (has-cmd "bash") {
        print "bash is not installed."
        return
    }

    if ($script_path == null) {
        print "zsh-pastebin.zsh is not available."
        return
    }

    ^bash -lc 'source "$1"; shift; pastebin "$@"' _ $script_path ...$args
}

def --wrapped pasteget [...rest: string] {
    let script_path = (zsh-pastebin-script-path)
    let args = (expand-external-args ...$rest)

    if not (has-cmd "bash") {
        print "bash is not installed."
        return
    }

    if ($script_path == null) {
        print "zsh-pastebin.zsh is not available."
        return
    }

    ^bash -lc 'source "$1"; shift; pasteget "$@"' _ $script_path ...$args
}

def --wrapped pbenc [...rest: string] {
    let script_path = (zsh-pastebin-script-path)
    let args = (expand-external-args ...$rest)

    if not (has-cmd "bash") {
        print "bash is not installed."
        return
    }

    if ($script_path == null) {
        print "zsh-pastebin.zsh is not available."
        return
    }

    ^bash $script_path ...$args
}
