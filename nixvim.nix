# Shared nixvim configuration. Imported two ways:
#   - home.nix (home-manager module) on desktops
#   - hosts/thinkpad/configuration.nix (NixOS module) — no home-manager there
# The importing side must also import the matching nixvim module
# (inputs.nixvim.homeModules.nixvim or inputs.nixvim.nixosModules.nixvim).
{ lib, ... }:

{
  programs.nixvim = {
    enable = true;
    vimAlias = true;
    viAlias = true;

    globals = {
      mapleader = " ";
    };

    opts = {
      number = true; # Show line numbers in the gutter
      relativenumber = false;
      tabstop = 2; # Set tab width to 2 spaces
      shiftwidth = 2; # Set indentation width to 2 spaces
      expandtab = true; # Convert tabs to spaces
      autoindent = true; # Automatically indent new lines based on previous line
      wrap = true; # Wrap text to the next line
      cursorline = true; # Highlight the line where the cursor is located
      ignorecase = true; # Make searches case-insensitive
      smartcase = true; # Override ignorecase if search contains uppercase letters
      undofile = true; # Persistent undo across sessions
      scrolloff = 8; # Keep 8 lines of context above/below cursor
      signcolumn = "yes"; # Prevent gutter from jumping when diagnostics appear
    };

    # Clipboard provider (wl-copy binary); the register wiring is conditional,
    # see extraConfigLua — on a bare TTY host wl-copy errors on every yank.
    clipboard.providers.wl-copy.enable = true;

    # Colour Shceme
    colorschemes.catppuccin.enable = true;

    # Auto-save/restore sessions per directory (needed for tmux-resurrect nvim strategy)
    plugins.auto-session.enable = true;

    # Transparent
    plugins.transparent = {
      enable = true;
      autoLoad = true;
    };
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "transparent.nvim"
      ];

    # Treesitter (syntax highlighting, indentation, text objects)
    plugins.treesitter = {
      enable = true;
      settings.highlight.enable = true;
      settings.indent.enable = true;
    };

    # Git signs in the gutter
    plugins.gitsigns = {
      enable = true;
      settings.current_line_blame = false;
    };

    # LSPs
    plugins.lsp = {
      enable = true;
      servers = {
        nil_ls = {
          enable = true;
          settings.formatting.command = [ "nixfmt" ]; # Ensure nil_ls uses nixfmt
        };
        rust_analyzer = {
          enable = true;
          settings.formatting.command = [ "rustfmt" ];
          installRustc = true;
          installCargo = true;
          installRustfmt = true;
        };
        gopls.enable = true;
        html.enable = true;
        pyright.enable = true;
        ols.enable = true;
        # British spelling + grammar for prose. harper-ls is a self-contained
        # Rust binary with a bundled dictionary, so no native-spell .spl download
        # into the read-only nix store (the usual NixOS spell-check headache).
        harper_ls = {
          enable = true;
          # Restrict to prose filetypes; harper lints code comments by default.
          filetypes = [
            "markdown"
            "text"
            "gitcommit"
          ];
          settings = {
            "harper-ls" = {
              # "British" is a real dialect, not just an en_GB wordlist —
              # it knows British grammar/style conventions.
              dialect = "British";
            };
          };
        };
      };
      keymaps = {
        lspBuf = {
          "gd" = "definition"; # Go to definition
          "K" = "hover"; # Show hover info
          "<leader>ca" = "code_action"; # Code actions
        };
      };
    };

    # Format on save
    plugins.conform-nvim = {
      enable = true;
      autoLoad = true;
      settings = {
        format_on_save = {
          timeout_ms = 500;
          lsp_format = "fallback";
        };
        formatters_by_ft = {
          nix = [ "nixfmt" ];
        };
      };
    };

    # Telescope
    plugins.telescope = {
      enable = true;
      autoLoad = true;

      keymaps = {
        "<leader>ff" = "find_files";
        "<leader>fg" = "live_grep";
      };
    };
    extraConfigLua = ''
      -- Sync yanks with the system clipboard only under Wayland; on a bare
      -- TTY (thinkpad) the wl-copy provider errors on every yank.
      if vim.env.WAYLAND_DISPLAY then
        vim.opt.clipboard = "unnamedplus"
      end

      require("telescope").setup({
        defaults = {
          file_ignore_patterns = {
            "flake.lock",
            "node_modules/",
            ".git/",
          },
          hidden = true, -- Respect .gitignore and .ignore files
        },
      })
    '';

    plugins.web-devicons = {
      enable = true;
      autoLoad = true;
    };

    # Completions
    plugins.cmp = {
      enable = true;
      autoLoad = true;
      autoEnableSources = true;
      settings = {
        mapping = {
          "<C-Down>" = "cmp.mapping.select_next_item()";
          "<C-Up>" = "cmp.mapping.select_prev_item()";
          "<Tab>" = "cmp.mapping.confirm({ select = true })";
          "<C-Space>" = "cmp.mapping.complete()";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "buffer"; }
          { name = "path"; }
          { name = "luasnip"; }
        ];
      };
    };
    plugins.cmp-nvim-lsp.enable = true;
    plugins.cmp-buffer.enable = true;
    plugins.cmp-path.enable = true;
    plugins.cmp_luasnip.enable = true;
    plugins.luasnip.enable = true;

    # Harpoon
    plugins.harpoon = {
      enable = true;
      autoLoad = true;
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>a";
        action.__raw = "function() require'harpoon':list():add() end";
      }
      {
        mode = "n";
        key = "<leader>h";
        action.__raw = "function() require'harpoon'.ui:toggle_quick_menu(require'harpoon':list()) end";
      }
      {
        mode = "n";
        key = "<leader>1";
        action.__raw = "function() require'harpoon':list():select(1) end";
      }
      {
        mode = "n";
        key = "<leader>2";
        action.__raw = "function() require'harpoon':list():select(2) end";
      }
      {
        mode = "n";
        key = "<leader>3";
        action.__raw = "function() require'harpoon':list():select(3) end";
      }
      {
        mode = "n";
        key = "<leader>4";
        action.__raw = "function() require'harpoon':list():select(4) end";
      }
      {
        mode = "n";
        key = "<leader>5";
        action.__raw = "function() require'harpoon':list():select(5) end";
      }
    ];
  };
}
