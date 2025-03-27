winget install git.git
winget install zig.zig
winget install neovim.neovim

# required
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak

# optional but recommended
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak

git clone https://github.com/LazyVim/starter $env:LOCALAPPDATA\nvim

Remove-Item $env:LOCALAPPDATA\nvim\.git -Recurse -Force

Write-Host "Copy .dotfiles/nvim/lua/plugins/theme.lua to $env:LOCALAPPDATA/nvim/lua/plugins/theme.lua"
