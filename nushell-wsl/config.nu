# WSL Nushell profile ported from ~/.nix-dots/configs/zsh

let startup_time = (date now)

$env.GIT_ASK_YESNO = "false"

$env.config.history.max_size = 9999
$env.config.history.sync_on_enter = true
$env.config.history.file_format = "plaintext"
$env.config.edit_mode = "emacs"
$env.config.show_banner = false

source ./interactive-profile.nu

if $nu.is-interactive and (($env.TERM? | default "") != "dumb") {
    print $"Nushell prompt ready in ((date now) - $startup_time)\n"
}
