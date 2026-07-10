{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hyprland.nix
    ./nixvim.nix
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

  home.stateVersion = "25.05";
}
