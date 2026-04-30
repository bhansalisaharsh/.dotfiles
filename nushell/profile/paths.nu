def user-home [] {
    (($env | get -i USERPROFILE) | default (($env | get -i HOME) | default $nu.home-path))
}

def one-drive-home [] {
    user-home | path join "OneDrive - Bain"
}

def desktop-dir [] {
    let one_drive_desktop = (one-drive-home | path join "Desktop")
    let local_desktop = (user-home | path join "Desktop")

    if ($one_drive_desktop | path exists) {
        $one_drive_desktop
    } else if ($local_desktop | path exists) {
        $local_desktop
    } else {
        null
    }
}

def downloads-dir [] {
    let dir = (user-home | path join "Downloads")

    if ($dir | path exists) { $dir } else { null }
}

def dotfiles-dir [] {
    let backup_dir = (user-home | path join ".backups" ".dotfiles")
    let direct_dir = (user-home | path join ".dotfiles")

    if ($backup_dir | path exists) {
        $backup_dir
    } else if ($direct_dir | path exists) {
        $direct_dir
    } else {
        null
    }
}

def config-dir [] {
    let dir = (user-home | path join ".config")

    if ($dir | path exists) { $dir } else { null }
}

def desktopstuff-dir [] {
    let dir = (desktop-dir)

    if ($dir != null and (($dir | path join ".desktopstuff") | path exists)) {
        $dir | path join ".desktopstuff"
    } else {
        $dir
    }
}

def downloads-packages-dir [] {
    let dir = (downloads-dir)

    if ($dir != null and (($dir | path join "packages") | path exists)) {
        $dir | path join "packages"
    } else {
        $dir
    }
}

def git-bash-path [] {
    if ('C:\Program Files\Git\bin\bash.exe' | path exists) {
        'C:\Program Files\Git\bin\bash.exe'
    } else if ('C:\Program Files\Git\usr\bin\bash.exe' | path exists) {
        'C:\Program Files\Git\usr\bin\bash.exe'
    } else {
        null
    }
}

def zsh-pastebin-script-path [] {
    let script = (user-home | path join ".nix-dots" "configs" "zsh" "ohmyzsh-custom" "zsh-pastebin.zsh")

    if ($script | path exists) { $script } else { null }
}

if ((config-dir) != null) {
    $env.XDG_CONFIG_HOME = (config-dir)
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
    let gopath = (($env | get -i GOPATH) | default ((user-home) | path join "go"))

    if ($goroot != null and $goroot != "") {
        $env.GOROOT = $goroot
    }

    if ($gopath != null and $gopath != "") {
        $env.GOPATH = $gopath
        $env.GO_BIN = ($gopath | path join "bin")
        add-path-if-exists ($gopath | path join "bin")
    }
}

add-path-if-exists ((user-home) | path join "bin")
add-path-if-exists ((user-home) | path join ".local" "bin")
add-path-if-exists ((user-home) | path join ".cargo" "bin")
add-path-if-exists ((user-home) | path join ".bun" "bin")
add-path-if-exists ((user-home) | path join ".spicetify")
