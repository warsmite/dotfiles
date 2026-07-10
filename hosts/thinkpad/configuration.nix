{ pkgs, ... }:

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

  # SSH
  services.openssh.enable = true;
  # TEMP: password auth enabled to transfer keys to a fresh install.
  # Flip to false once ~/.ssh/authorized_keys is in place.
  services.openssh.settings.PasswordAuthentication = true;

  # Remote rebuilds
  security.sudo.wheelNeedsPassword = false;

  # Bluetooth (bluetoothctl — no GUI applet)
  hardware.bluetooth.enable = true;

  # Terminal-only writing machine: no compositor, no home-manager.
  # These are stock, unconfigured — the nixvim/tmux setup lives in home.nix
  # and is not pulled in here.
  environment.systemPackages = with pkgs; [
    neovim
    tmux
  ];

  system.stateVersion = "25.11";
}
