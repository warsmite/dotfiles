{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hyprland.nix
    inputs.nixvim.homeModules.nixvim
  ];

  programs.home-manager.enable = true;

  home.username = "warsmite";
  home.homeDirectory = "/home/warsmite";

  # Packages
  home.packages = with pkgs; [
    # Apps
    #jellyfin-media-player # Jellyfin client
    spotify
    spotify-cli-linux
    qbittorrent
    mullvad-browser
    chromium
    signal-desktop
    telegram-desktop
    discord
    slack
    stripe-cli
    satisfactorymodmanager
    gh # Github cli
    lftp # sftp
    ffmpeg
    openssl
    xxd

    nerd-fonts.fira-code # Font

    openvpn
    nmap
    gobuster
    thc-hydra

    # Utils
    wget
    cdrkit
    ripgrep
    dnsutils # dig, nslookup
    whois
    traceroute
    tree
    jq
    unzip
    zip
    file
    lsof
    strace
    mullvad-vpn
    feh
    pamixer # Audio Mixer
    mpv # Video player
    btop
    acpi # Battery viewer
    cloc # Count lines of code
    glow # Terminal markdown reader
    ncdu # Disk usage analysis
    tt # Typespeed test
    evince # pdf reader
    fastfetch # New neofetch
    cpufetch
    qemu # VMs
    quickemu # VM tools
    inputs.nopswd.packages.${pkgs.stdenv.hostPlatform.system}.default # Password manager
    inputs.gjq.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Programming Languages, tools, etc
    sqlite
    reflex # Reload on change
    # Nix
    nixfmt # Extra formatter for nix, not included in nil_ls
    # Go
    go
    # JS/Node
    (lib.hiPrio nodejs_24)
    # Python
    python3
    # Odin
    odin

    opencode
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    playwright-mcp

    # Rust
    rustc
    cargo
    rustfmt

    gcc
  ];

  # Alacritty Terminal
  fonts.fontconfig.enable = true;
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.8;
        padding = {
          x = 10;
          y = 10;
        };
      };
      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "regular";
        };
      };
      scrolling = {
        history = 10000;
      };
    };
  };

  # Tmux
  programs.tmux = {
    enable = true;
    baseIndex = 1; # Make windows start at 1
    escapeTime = 0; # Make neovim snappier
    keyMode = "vi";
    mouse = true;

    plugins = [
      { plugin = inputs.minimal-tmux.packages.${pkgs.stdenv.hostPlatform.system}.default; }
      {
        plugin = pkgs.tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes 'ssh ".claude-unwrapped"'
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
      { plugin = pkgs.tmuxPlugins.yank; }
      {
        plugin = pkgs.tmuxPlugins.extrakto;
        extraConfig = ''
          set -g @extrakto_clip_tool 'wl-copy'
          set -g @extrakto_copy_key 'tab'
          set -g @extrakto_insert_key 'enter'
        '';
      }
      { plugin = pkgs.tmuxPlugins.open; }
    ];

    extraConfig = ''
      # Terminal & color
      set -g default-terminal "tmux-256color"
      set -sa terminal-features ',xterm-256color:RGB'

      # General
      set -g focus-events on
      set -g history-limit 50000
      set -g renumber-windows on

      # Pane borders (Catppuccin)
      set -g pane-border-style 'fg=#313244'
      set -g pane-active-border-style 'fg=#b4befe'

      # Copy mode highlight (Catppuccin)
      set -g mode-style 'fg=#cdd6f4,bg=#45475a'

      # Clipboard (Wayland)
      set -g @yank_selection_mouse 'clipboard'
      set -g @override_copy_command 'wl-copy'
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

      # M is ALT in this context
      # Manage Windows
      bind-key -n M-X kill-window

      ## Switch to specific window by number
      bind-key -n M-1 run-shell "tmux select-window -t :=1 || tmux new-window -t 1 -c ~"
      bind-key -n M-2 run-shell "tmux select-window -t :=2 || tmux new-window -t 2 -c ~"
      bind-key -n M-3 run-shell "tmux select-window -t :=3 || tmux new-window -t 3 -c ~"
      bind-key -n M-4 run-shell "tmux select-window -t :=4 || tmux new-window -t 4 -c ~"
      bind-key -n M-5 run-shell "tmux select-window -t :=5 || tmux new-window -t 5 -c ~"
      bind-key -n M-6 run-shell "tmux select-window -t :=6 || tmux new-window -t 6 -c ~"
      bind-key -n M-7 run-shell "tmux select-window -t :=7 || tmux new-window -t 7 -c ~"
      bind-key -n M-8 run-shell "tmux select-window -t :=8 || tmux new-window -t 8 -c ~"
      bind-key -n M-9 run-shell "tmux select-window -t :=9 || tmux new-window -t 9 -c ~"
      bind-key -n M-0 run-shell "tmux select-window -t :=10 || tmux new-window -t 10 -c ~"

      # Pane Management
      bind-key -n M-x kill-pane
      ## Pane Splitting
      bind-key -n M-h split-window -h -c "#{pane_current_path}"
      bind-key -n M-v split-window -v -c "#{pane_current_path}"

      ## Navigate panes
      bind-key -n M-Left select-pane -L
      bind-key -n M-Right select-pane -R
      bind-key -n M-Up select-pane -U
      bind-key -n M-Down select-pane -D

      ## Resize panes
      bind-key -n -r M-S-Left resize-pane -L 5
      bind-key -n -r M-S-Right resize-pane -R 5
      bind-key -n -r M-S-Up resize-pane -U 5
      bind-key -n -r M-S-Down resize-pane -D 5

      ## Swap panes
      bind-key -n M-'{' swap-pane -U
      bind-key -n M-'}' swap-pane -D

      ## Zoom pane (toggle fullscreen)
      bind-key -n M-z resize-pane -Z
    '';
  };

  # Cursor
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # SSH
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
      };
      "github.com" = {
        hostname = "github.com";
        identitiesOnly = true;
      };
      "localhost" = {
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
    };
  };
  services.ssh-agent.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings.user.name = "warsmite";
    settings.user.email = "warsmite@proton.me";
    settings.push.autoSetupRemote = true;
    settings.init.defaultBranch = "master";
  };

  # Bash
  programs.bash = {
    enable = true;
    shellAliases = {
      gs = "git status";
      gp = "git push";
      gl = "git log --oneline";
      sandbox = "ssh -t grumpy 'sudo machinectl shell warsmite@claude-sandbox'";
      claude = "mullvad-exclude claude";
    };
    initExtra = ''
      # Auto-start Tmux if not already in a session
      if [ -z "$TMUX" ]; then
        tmux attach -t default || tmux new -s default
      fi
    '';
  };

  # fzf (Ctrl-R for history, Ctrl-T for file finder)
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "rg --files --hidden --glob '!.git'";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # Brave Browser
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      # Vimium
      {
        id = "dbepggeogbaibhgnhhndojpepiihcmeb";
      }
      # Video Speed Controller
      {
        id = "nffaoalbilbmmfgbnbgppjihopabppdk";
      }
      # Remove Youtube Shorts
      {
        id = "mgngbgbhliflggkamjnpdmegbkidiapm";
      }
      # Sponsor Block
      {
        id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      }
      # Return Youtube Dislikes
      { id = "gebbhagfogifgggkldgodflihgfeippi"; }
    ];
  };

  # Neovim Editor
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

    # Clipboard
    clipboard.register = "unnamedplus";
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

  home.stateVersion = "25.05";
}
