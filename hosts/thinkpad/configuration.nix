{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
    # Full nixvim setup without home-manager (nixvim's NixOS module)
    inputs.nixvim.nixosModules.nixvim
    ../../nixvim.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "thinkpad";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; # Faster boot
  services.mullvad-vpn.enable = true;

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Remote rebuilds
  security.sudo.wheelNeedsPassword = false;

  # Bluetooth unused on this TTY writing machine — off to save power.
  hardware.bluetooth.enable = false;

  # Console readability (bare TTY): a larger font for the 1366x768 panel and
  # a 16-colour Catppuccin Mocha palette, so themes render through crisp,
  # high-contrast colours instead of the muddy kernel default. Index 0 is the
  # dark base (background), 7/15 are light text (foreground).
  console = {
    earlySetup = true;
    font = "ter-v24n";
    packages = [ pkgs.terminus_font ];
    colors = [
      "1e1e2e" "f38ba8" "a6e3a1" "f9e2af" "89b4fa" "f5c2e7" "94e2d5" "bac2de"
      "585b70" "f38ba8" "a6e3a1" "f9e2af" "89b4fa" "f5c2e7" "94e2d5" "a6adc8"
    ];
  };

  # The Linux console is 16-colour only. Force nvim to render Catppuccin
  # through the palette above instead of dithering 24-bit down to mud.
  # Scoped to this host — the graphical hosts share nixvim.nix and keep truecolor.
  programs.nixvim.opts.termguicolors = false;

  # NMI watchdog is useless here and just adds timer wakeups.
  boot.kernel.sysctl."kernel.nmi_watchdog" = 0;

  # Power management (laptop). Battery is worn (~46% of design capacity),
  # so cap charge at 80% to slow further wear. Only BAT1 exists on this unit.
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;

      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_BAT = 1;
      PCIE_ASPM_ON_BAT = "powersupersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };

  # On the Linux console, Alt+Left/Right are kernel VT-switch shortcuts
  # (Decr_Console/Incr_Console) — they never reach tmux. Remap alt and
  # shift+alt arrows to xterm-style escape sequences so tmux sees M-arrows.
  # Ctrl+Alt+Fn still switches VTs.
  systemd.services.console-alt-arrows = {
    description = "Remap console Alt+arrows from VT switching to tmux-readable escape sequences";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-vconsole-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kbd}/bin/loadkeys ${pkgs.writeText "alt-arrows.map" ''
        alt keycode 103 = F100
        alt keycode 105 = F101
        alt keycode 106 = F102
        alt keycode 108 = F103
        shift alt keycode 103 = F104
        shift alt keycode 105 = F105
        shift alt keycode 106 = F106
        shift alt keycode 108 = F107
        string F100 = "\033[1;3A"
        string F101 = "\033[1;3D"
        string F102 = "\033[1;3C"
        string F103 = "\033[1;3B"
        string F104 = "\033[1;4A"
        string F105 = "\033[1;4D"
        string F106 = "\033[1;4C"
        string F107 = "\033[1;4B"
      ''}";
    };
  };

  # Git identity (home-manager's job on the other machines)
  programs.git.config = {
    user.name = "warsmite";
    user.email = "warsmite@proton.me";
    push.autoSetupRemote = true;
    init.defaultBranch = "master";
  };

  environment.systemPackages = [
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "25.11";
}
