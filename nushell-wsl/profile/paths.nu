def desktop-dir [] {
    let dir = (user-home | path join "Desktop")

    if ($dir | path exists) { $dir } else { null }
}

def downloads-dir [] {
    let dir = (user-home | path join "Downloads")

    if ($dir | path exists) { $dir } else { null }
}

def dotfiles-dir [] {
    let direct_dir = (user-home | path join ".dotfiles")
    let backup_dir = (user-home | path join ".backups" ".dotfiles")

    if ($direct_dir | path exists) {
        $direct_dir
    } else if ($backup_dir | path exists) {
        $backup_dir
    } else {
        $direct_dir
    }
}

def config-dir [] {
    user-home | path join ".config"
}

def desktopstuff-dir [] {
    let base = (desktop-dir)

    if ($base != null and (($base | path join ".desktopstuff") | path exists)) {
        $base | path join ".desktopstuff"
    } else {
        $base
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

def zsh-pastebin-script-path [] {
    let script = (user-home | path join ".nix-dots" "configs" "zsh" "ohmyzsh-custom" "zsh-pastebin.zsh")

    if ($script | path exists) { $script } else { null }
}

$env.XDG_CONFIG_HOME = (config-dir)
$env.ZELLIJ_AUTO_ATTACH = "true"
$env.ZELLIJ_AUTO_EXIT = "true"
$env.VISUAL = "nvim"
$env.EDITOR = "nvim"

let is_linux = (($nu.os-info.name | str downcase) == "linux")

if (has-cmd "wslview") {
    $env.BROWSER = "wslview"
}

let gopath = ($env.GOPATH? | default ((user-home) | path join "go"))
$env.GOPATH = $gopath
$env.GO_BIN = ($gopath | path join "bin")
add-path-if-exists ($gopath | path join "bin")

if $is_linux and (has-cmd "go") {
    let goroot = (^go env GOROOT | str trim)

    if ($goroot != "") {
        $env.GOROOT = $goroot
    }
}

add-path-if-exists ((user-home) | path join "bin")
add-path-if-exists ((user-home) | path join ".local" "bin")
add-path-if-exists ((user-home) | path join ".cargo" "bin")
add-path-if-exists ((user-home) | path join ".volta" "bin")
add-path-if-exists ((user-home) | path join ".cache" ".bun" "bin")
add-path-if-exists ((user-home) | path join ".spicetify")
add-path-if-exists (config-dir)
