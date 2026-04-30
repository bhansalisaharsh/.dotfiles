def has-cmd [name: string] {
    (which $name | length) > 0
}

def expand-external-args [...rest: string] {
    let home = (
        ($env | get -i USERPROFILE)
        | default (($env | get -i HOME) | default $nu.home-path)
    )

    if (($rest | length) == 0) {
        return []
    }

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
