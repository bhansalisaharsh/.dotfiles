return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            transparent = true,
            style = "moon",
            -- styles = {
            --     sidebars = "transparent",
            --     floats = "transparent",
            -- },
        },
    },

    {
        "catppuccin/nvim",
        lazy = true,
        name = "catppuccin",
        opts = {
            flavor = "mocha",
            transparent_background = true,
            dim_inactive = {
                enabled = false, -- dims the background color of inactive window
                shade = "dark",
                percentage = 0.00, -- percentage of the shade to apply to the inactive window
            },
            -- custom_highlights = function(colors)
            --     return {
            --         NormalFloat = { bg = nil, fg = colors.text },
            --         Normal = { bg = nil , fg = colors.base },
            --     }
            -- end,
            lsp_styles = {
                underlines = {
                    errors = { "undercurl" },
                    hints = { "undercurl" },
                    warnings = { "undercurl" },
                    information = { "undercurl" },
                },
            },
            integrations = {
                aerial = true,
                alpha = true,
                bufferline = true,
                cmp = true,
                dashboard = true,
                flash = true,
                fzf = true,
                grug_far = true,
                gitsigns = true,
                headlines = true,
                illuminate = true,
                indent_blankline = { enabled = true },
                leap = true,
                lsp_trouble = true,
                mason = true,
                markdown = true,
                mini = true,
                navic = { enabled = true, custom_bg = "lualine" },
                neotest = true,
                neotree = true,
                noice = true,
                notify = true,
                semantic_tokens = true,
                snacks = true,
                telescope = true,
                treesitter = true,
                treesitter_context = true,
                which_key = true,
            },
        },
        specs = {
            {
                "akinsho/bufferline.nvim",
                optional = true,
                opts = function(_, opts)
                    if (vim.g.colors_name or ""):find("catppuccin") then
                        opts.highlights = require("catppuccin.special.bufferline").get_theme()
                    end
                end,
            },
        },
    },

    {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
            if (vim.g.colors_name or ""):find("catppuccin") then
                opts.highlights = require("catppuccin.special.bufferline").get_theme()
            end
        end,
    },

    -- Configure LazyVim to load catppuccin
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        },
    },
}
