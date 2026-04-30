def has-cmd [name: string] {
    (which $name | length) > 0
}

def user-home [] {
    let home = ($env.HOME? | default "")
    let userprofile = ($env.USERPROFILE? | default "")

    if $home != "" {
        $home
    } else if $userprofile != "" {
        $userprofile
    } else {
        "~" | path expand
    }
}

def expand-external-args [...rest: string] {
    let home = (user-home)

    if (($rest | length) == 0) {
        return []
    }

    $rest | each {|arg|
        if $arg == "~" {
            $home
        } else if ($arg | str starts-with "~/") {
            $home | path join ($arg | str substring 2..)
        } else {
            $arg
        }
    }
}

def --env add-path-if-exists [candidate?: string] {
    if ($candidate != null and $candidate != "" and ($candidate | path exists)) {
        $env.PATH = (
            ($env.PATH? | default [])
            | prepend $candidate
            | uniq
        )
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

def export-aliases [outfile: path = "aliases.nu"] {
    scope aliases
    | sort-by name
    | each {|row| $"alias ($row.name) = ($row.expansion)" }
    | str join "\n"
    | save -f $outfile
}

def clipboard-text [] {
    if (($in | describe) == "nothing") {
        ""
    } else {
        $in | to text
    }
}

def clipC [] {
    let data = ($in | clipboard-text)

    if (has-cmd "wl-copy") {
        $data | ^wl-copy
    } else if (has-cmd "xclip") {
        $data | ^xclip -sel clip
    } else if (has-cmd "xsel") {
        $data | ^xsel -ib
    } else if (has-cmd "clip.exe") {
        $data | ^clip.exe
    } else {
        print "No clipboard writer found."
    }
}

def clipP [] {
    if (has-cmd "wl-paste") {
        ^wl-paste
    } else if (has-cmd "xclip") {
        ^xclip -sel clip -o
    } else if (has-cmd "xsel") {
        ^xsel -ob
    } else if (has-cmd "powershell.exe") {
        ^powershell.exe -NoProfile -Command Get-Clipboard
    } else {
        print "No clipboard reader found."
    }
}

def xC [] {
    let data = ($in | clipboard-text)

    if (has-cmd "xsel") {
        $data | ^xsel -ib
    } else {
        print "xsel is not installed."
    }
}

def xP [] {
    if (has-cmd "xsel") {
        ^xsel -ob
    } else {
        print "xsel is not installed."
    }
}

def wlC [] {
    let data = ($in | clipboard-text)

    if (has-cmd "wl-copy") {
        $data | ^wl-copy
    } else {
        print "wl-copy is not installed."
    }
}

def wlP [] {
    if (has-cmd "wl-paste") {
        ^wl-paste
    } else {
        print "wl-paste is not installed."
    }
}

def wlCp [] {
    let data = ($in | clipboard-text)

    if (has-cmd "wl-copy") {
        $data | ^wl-copy -p
    } else {
        print "wl-copy is not installed."
    }
}

def wlPp [] {
    if (has-cmd "wl-paste") {
        ^wl-paste -p
    } else {
        print "wl-paste is not installed."
    }
}

def cliphist-remove [] {
    if (has-cmd "cliphist") and (has-cmd "rofi") and (has-cmd "bash") {
        ^bash -lc 'cliphist list | rofi -dmenu -no-custom -p "[Enter] repeat; [ESC] exit" | cliphist delete'
    } else {
        print "cliphist, rofi, or bash is not installed."
    }
}

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
