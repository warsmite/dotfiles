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

  # Bluetooth (bluetoothctl — no GUI applet)
  hardware.bluetooth.enable = true;

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
