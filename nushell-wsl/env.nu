def has-cmd [name: string] {
    (which $name | length) > 0
}

def normalize-atuin-hook [script: string] {
    let nu_version = (version)

    if ($nu_version.major > 0 or $nu_version.minor >= 112) {
        $script
        | str replace "job spawn -t atuin {" "job spawn {"
        | str replace "job spawn --tag atuin {" "job spawn {"
    } else {
        $script
    }
}

def write-hook [out: path, content: string] {
    let parent = ($out | path dirname)

    if not ($parent | path exists) {
        mkdir $parent
    }

    $content | save -f $out
}

def render-hook [cmd: string, ...args: string] {
    let result = (^$cmd ...$args | complete)

    if $result.exit_code != 0 {
        error make {
            msg: $"Failed to generate hook for ($cmd)"
            label: {
                text: ($result.stderr | str trim)
                span: (metadata $cmd).span
            }
        }
    }

    $result.stdout
}

let root = ($nu.env-path | path dirname)
let generated_dir = ($root | path join "profile" "generated")
let os_name = ($nu.os-info.name | str downcase)

if not ($generated_dir | path exists) {
    mkdir $generated_dir
}

if $os_name == "linux" {
    if not (has-cmd "atuin") {
        error make { msg: "atuin is required for the WSL Nushell profile." }
    }

    if not (has-cmd "pay-respects") {
        error make { msg: "pay-respects is required for the WSL Nushell profile." }
    }

    write-hook (
        $generated_dir | path join "atuin.nu"
    ) (normalize-atuin-hook (render-hook "atuin" "init" "nu"))

    write-hook (
        $generated_dir | path join "pay-respects.nu"
    ) (
        render-hook "pay-respects" "nushell" "--alias" "f"
    )
}
