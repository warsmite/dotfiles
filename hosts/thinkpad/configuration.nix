{ inputs, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
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

  # Bluetooth unused for now — off to save power.
  hardware.bluetooth.enable = false;

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Login greeter (no autologin — require authentication at boot)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd hyprland";
      user = "greeter";
    };
  };

  # Suspend-then-hibernate on lid close: instant resume for short breaks, zero
  # drain after that. Plain suspend flattens the worn battery (~21Wh left) in
  # a couple of days.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30min
  '';

  # Swap partition from hardware-configuration.nix (7.5G vs 7.7G RAM — enough,
  # the hibernate image is compressed and capped well below total RAM).
  boot.resumeDevice = "/dev/disk/by-uuid/c553be6c-93aa-41ca-8f65-35470e79932b";

  # NMI watchdog is useless here and just adds timer wakeups.
  boot.kernel.sysctl."kernel.nmi_watchdog" = 0;

  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_BAT = 1;
      PCIE_ASPM_ON_BAT = "powersupersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs pkgs-unstable; };

    users = {
      "warsmite" =
        { ... }:
        {
          imports = [
            ./home.nix
            ../../home.nix
          ];
        };
    };
  };

  system.stateVersion = "25.11";
}
