# Neovim Setup (Omarchy)

LazyVim distro with Lazy.nvim plugin manager, integrated with omarchy theming.

## Location

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lazy-lock.json              # Plugin lock
├── lazyvim.json                # LazyVim metadata
├── stylua.toml                 # Lua formatter (2-space, 120 col)
├── lua/
│   ├── config/
│   │   ├── autocmds.lua        # Delegates to LazyVim defaults
│   │   ├── keymaps.lua         # Delegates to LazyVim defaults
│   │   ├── lazy.lua            # Lazy.nvim bootstrap
│   │   └── options.lua         # Custom options
│   └── plugins/
│       ├── all-themes.lua      # 14 themes (lazy-loaded)
│       ├── theme.lua           # Symlink → omarchy theme
│       ├── omarchy-theme-hotreload.lua
│       ├── disable-news-alert.lua
│       ├── snacks-animated-scrolling-off.lua
│       ├── noice-fix.lua
│       └── example.lua
└── plugin/after/
    └── transparency.lua        # 45 transparent highlight groups
```

## Omarchy Integration

Theme symlink enables hot-reload when omarchy theme changes:

```
lua/plugins/theme.lua → ~/.config/omarchy/current/theme/neovim.lua
```

`omarchy-theme-hotreload.lua` watches `LazyReload` event, clears highlights, reapplies theme + transparency.

## Plugins (46)

### Core
- **blink.cmp** - completion
- **flash.nvim** - motion
- **mini.ai/pairs/icons** - mini modules
- **which-key.nvim** - keybinding helper
- **todo-comments.nvim** - TODO highlighting
- **grug-far.nvim** - find/replace

### UI
- **bufferline.nvim** - tabs
- **lualine.nvim** - statusline
- **neo-tree.nvim** - file tree
- **snacks.nvim** - UI utils (scrolling disabled)
- **trouble.nvim** - diagnostics

### Language
- **nvim-lspconfig** + **mason.nvim** - LSP
- **nvim-treesitter** - syntax
- **conform.nvim** - formatting (prettier)
- **nvim-lint** - linting
- **lazydev.nvim** - Neovim API dev

### Git
- **gitsigns.nvim** - gutter signs

### Themes (14, lazy-loaded)
tokyonight, gruvbox, kanagawa, rose-pine, nord, everforest, catppuccin, bamboo, aether, ethereal, hackerman, flexoki, monokai-pro, matteblack

**Current:** tokyonight-night

## Customizations

| Setting | Value |
|---------|-------|
| Relative line numbers | disabled |
| Noice.nvim | disabled (treesitter compat) |
| Scroll animations | disabled |
| News/alerts | suppressed |
| Transparency | 45+ highlight groups |

## LSP

Configured via `.neoconf.json`:
- neodev enabled
- lua_ls for Neovim API development
