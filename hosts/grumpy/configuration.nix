{
  inputs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
    #inputs.gamejanitor.nixosModules.default
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "grumpy";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 27000;
      to = 27999;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 27000;
      to = 27999;
    }
  ];

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Remote rebuilds
  security.sudo.wheelNeedsPassword = false;

  #services.gamejanitor = {
  #  enable = true;
  #  controller = false;
  #  worker = true;
  #  bindAddress = "0.0.0.0";
  #  containerRuntime = "docker";
  #  grpcPort = 9090;
  #  controllerAddress = "192.168.1.102:9090";
  #  workerTokenFile = "/etc/gamejanitor/worker-token";
  #  settings = {
  #    port_range_start = 29000;
  #    port_range_end = 29999;
  #  };
  #  openFirewall = true;
  #};

  # Minecraft server
  # Declarative mode is required for the NixOS-managed whitelist and
  # serverProperties below to take effect.
  services.minecraft-server = {
    enable = true;
    eula = true; # Accepts Mojang's EULA (https://aka.ms/MinecraftEULA)
    declarative = true;
    openFirewall = true; # Opens TCP 25565 (server-port below)

    # stable 25.11 only packages 1.21.10; pull the latest release from
    # nixpkgs-unstable (wired in via specialArgs in flake.nix).
    package = pkgs-unstable.minecraft-server;

    serverProperties = {
      server-port = 25565;
      white-list = true; # Whitelist is enforced; only listed players may join
      difficulty = "hard";
      gamemode = "survival";
      motd = "grumpy";
      view-distance = 32; # Maximum the server allows; values above 32 are clamped
      pause-when-empty-seconds = -1; # Never pause ticking when the server is empty
    };

    # Map of Minecraft username -> account UUID. Both declarative mode and
    # white-list=true above are required for this to be enforced.
    whitelist = {
      timpertinent = "a1606c1f-5445-45c7-8f55-7f0d743514d8";
    };

    # Default heap is 2G (-Xmx2048M -Xms2048M); override here if needed.
    # jvmOpts = "-Xmx4096M -Xms4096M";
  };

  # User
  users.users.warsmite = {
    isNormalUser = true;
    home = "/home/warsmite";
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.05";
}
