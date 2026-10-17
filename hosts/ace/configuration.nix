{
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
  ];

  # temp
  nixpkgs.config.permittedInsecurePackages = [
    "docker-28.5.2"
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "amdgpu.cwsr_enable=0" # Workaround for MES hang on Strix Point
    "amdgpu.mes_log_enable=1" # Enable MES logging for GPU crash diagnosis
    "mitigations=off" # Disable CPU security mitigations for performance
  ];
  boot.kernelPackages = pkgs.linuxPackages_cachyos; # CachyOS kernel for gaming
  hardware.firmware = [ pkgs.linux-firmware ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  fonts.packages = [ pkgs.noto-fonts-cjk-sans ];

  # Networking
  networking.hostName = "ace";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; # Faster boot
  services.mullvad-vpn.enable = true;
  networking.wg-quick.interfaces.gjb = {
    configFile = "/etc/wireguard/gjb.conf";
    autostart = true;
  };
  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Prevent suspend so SSH stays reachable
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  networking.firewall.allowedTCPPorts = [
    22
    25565
    27015
    28015
    28017
    7777
    8080
    9898
  ];
  networking.firewall.allowedUDPPorts = [
    25565
    27015
    28015
    28017
    7777
  ];

  # Second SSD
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/0c83a41b-ebd6-4ad5-ae8f-f6007a671a93";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=5s"
    ];
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Login greeter (no autologin — require authentication at boot)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd hyprland";
      user = "greeter";
    };
  };

  # Virtualisation
  virtualisation.docker.enable = true;
  users.users.warsmite.extraGroups = [
    "wheel"
    "docker"
    "kvm"
  ];

  # Postgres
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "gamejanitor" ];
    ensureUsers = [
      { name = "warsmite"; }
    ];
    initialScript = pkgs.writeText "pg-init" ''
      ALTER DATABASE gamejanitor OWNER TO warsmite;
    '';
  };

  # llama.cpp server (Vulkan, OpenAI-compatible API on port 8081)
  # Place GGUF files in /data/models/, symlink active model to default.gguf
  systemd.services.llama-server = {
    description = "llama.cpp inference server (Vulkan)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      HOME = "/var/lib/llama-server"; # Vulkan shader cache needs a writable home
    };

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";
      DynamicUser = true;
      StateDirectory = "llama-server";
      ReadOnlyPaths = [ "/data/models" ];
      ExecStart = ''
        ${pkgs-unstable.llama-cpp-vulkan}/bin/llama-server \
          --model /data/models/default.gguf \
          --host 0.0.0.0 \
          --port 8081 \
          --gpu-layers 99 \
          --ctx-size 32768 \
          --flash-attn on
      '';
    };
  };

  # Games
  ## Star Citizen
  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "fs.file-max" = 524288;
    "vm.swappiness" = 10; # Prefer RAM over swap
    "vm.vfs_cache_pressure" = 50; # Keep file cache longer
  };

  # zram (compressed RAM swap - faster than disk)
  zramSwap = {
    enable = true;
    memoryPercent = 50; # Use up to 50% of RAM for zram
    algorithm = "zstd";
  };

  # I/O scheduler for NVMe
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="kyber"
  '';

  # TDP cap via ryzenadj — prevents thermal runaway on the F7A's cooling.
  # Observed: stock BIOS lets cores hit 94.4°C (Tjmax=95). These limits
  # pull sustained power back enough to keep core_max under ~85°C.
  # Tune with: sudo ryzenadj --info (read current), then adjust values below.
  systemd.services.ryzenadj-tdp-cap = {
    description = "Apply ryzenadj TDP limits for thermal stability";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=40000 --fast-limit=50000 --slow-limit=42000 --tctl-temp=85";
    };
  };

  environment.systemPackages = with pkgs; [
    # Star Citizen
    inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.rsi-launcher

    # Minecraft
    openjdk25
    prismlauncher # Unofficial Minecraft Launcher

    ryzenadj # Manual TDP tuning: sudo ryzenadj --info
    amdgpu_top
    wlr-randr
    mangohud
    lsof

    rocmPackages_6.rocm-runtime
    rocmPackages_6.rocm-smi
    rocmPackages_6.rocminfo
    pkgs-unstable.llama-cpp-vulkan

    (writeShellScriptBin "llama-switch" ''
      set -euo pipefail
      MODEL_DIR="/data/models"
      if [ -z "''${1:-}" ]; then
        echo "Available models:"
        ls -1 "$MODEL_DIR"/*.gguf 2>/dev/null | xargs -I{} basename {}
        echo ""
        echo "Usage: llama-switch <model.gguf>"
        exit 1
      fi
      if [ ! -f "$MODEL_DIR/$1" ]; then
        echo "Error: $MODEL_DIR/$1 not found"
        exit 1
      fi
      ln -sf "$MODEL_DIR/$1" "$MODEL_DIR/default.gguf"
      sudo systemctl restart llama-server
      echo "Switched to $1"
    '')

    # Game streaming client (Windows PC runs Sunshine as host)
    moonlight-qt

    # GeForce NOW launcher that keeps the stream outside the Mullvad tunnel.
    # Used by the com.nvidia.geforcenow desktop entry in hosts/ace/home.nix —
    # changing the name here requires updating that entry's exec.
    (writeShellScriptBin "geforcenow-excluded" ''
      set -euo pipefail

      APP_ID="com.nvidia.geforcenow"
      SCOPE_GLOB="/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/app.slice/app-flatpak-$APP_ID-*.scope"
      POLL_SECONDS=2
      STARTUP_TIMEOUT_SECONDS=30

      log() {
        printf '[geforcenow-exclude] %s\n' "$*" >&2
      }

      # Prefixing this with mullvad-exclude does not work. flatpak hands the app
      # off to the systemd user session, which puts it in its own
      # app-flatpak-*.scope and resets net_cls to /, discarding the
      # mullvad-exclusions membership mullvad-exclude set on the launcher. So
      # launch normally and re-apply the exclusion per-PID after the handoff.
      flatpak run --branch=master --arch=x86_64 --command=GeForceNOW "$APP_ID" &
      launcher_pid=$!
      log "launched flatpak (pid $launcher_pid), waiting for app scope"

      excluded_pids=" "
      scope_seen=0
      waited_seconds=0

      while true; do
        # SCOPE_GLOB is deliberately unquoted — the scope name ends in a
        # systemd-assigned number that has to glob.
        scope_pids="$(cat $SCOPE_GLOB/cgroup.procs 2>/dev/null || true)"

        if [ -z "$scope_pids" ]; then
          if [ "$scope_seen" -eq 1 ]; then
            log "app scope is gone, GeForce NOW has exited"
            exit 0
          fi

          waited_seconds=$((waited_seconds + POLL_SECONDS))
          if [ "$waited_seconds" -ge "$STARTUP_TIMEOUT_SECONDS" ]; then
            log "ERROR: no app scope after $STARTUP_TIMEOUT_SECONDS seconds - traffic is NOT excluded from the VPN"
            exit 1
          fi
        else
          scope_seen=1

          # CEF spawns helper processes throughout startup, so keep sweeping the
          # scope rather than excluding once. PIDs forked after their parent is
          # excluded inherit the cgroup, but the early ones race the handoff.
          for pid in $scope_pids; do
            case "$excluded_pids" in
              *" $pid "*) continue ;;
            esac

            if mullvad split-tunnel add "$pid" > /dev/null; then
              excluded_pids="$excluded_pids$pid "
              log "excluded pid $pid from the tunnel"
            else
              log "WARNING: failed to exclude pid $pid from the tunnel"
            fi
          done
        fi

        sleep "$POLL_SECONDS"
      done
    '')

    # Monero
    monero-gui

    quickemu
    bubblewrap

    # Gamejanitor CLI
    inputs.gamejanitor.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Extend sudo password cache to 1 hour
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=60
  '';

  ## Steam
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  ## GeForce NOW
  # NVIDIA ships the native Linux client only as a Flatpak from their own repo
  # (not on Flathub, not in nixpkgs), so Flatpak is enabled solely for this.
  # Flathub is still required for the runtimes the app pulls in. One-time setup:
  #   flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
  #   flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #   flatpak install --user GeForceNOW com.nvidia.geforcenow
  # services.flatpak asserts on xdg.portal.enable, which programs.hyprland
  # above already sets — no separate portal config needed here.
  services.flatpak.enable = true;

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

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

  system.stateVersion = "25.05";
}
