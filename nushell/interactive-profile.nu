const profile_dir = ($nu.default-config-dir | path join "profile")

source ($profile_dir | path join "helpers.nu")
source ($profile_dir | path join "paths.nu")
source ($profile_dir | path join "pastebin.nu")
source ($profile_dir | path join "aliases.nu")
source ($profile_dir | path join "core.nu")
