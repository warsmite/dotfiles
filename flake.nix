{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nopswd.url = "github:warsmite/nopswd";
    gjq.url = "github:warsmite/gjq";
    gamejanitor.url = "github:warsmite/GameJanitor";

    # DayZ Epoch server for grumpy. Local path input while the repo only lives
    # on this machine (switch to github:warsmite/dzepoch if pushed) — path
    # inputs are pinned in flake.lock, so run `nix flake update dzepoch` here
    # after changing ~/dev/dzepoch, then rebuild.
    dzepoch.url = "path:/home/warsmite/dev/dzepoch";

    claude-code.url = "github:sadjow/claude-code-nix";

    # Pinned to a release tag — upstream calls Nix a best-effort Tier 2 platform
    # and main can break the flake at any time. Tags switched from vYYYY.M.D to
    # v0.x.y after v2026.9.24. Bump deliberately: `nix flake update` alone does
    # not move a tag pin.
    hermes-agent.url = "github:NousResearch/hermes-agent/v0.22.5";

    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      pkgs-unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      # User machines
      nixosConfigurations.chuwi = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./hosts/chuwi/configuration.nix
          inputs.home-manager.nixosModules.home-manager
        ];
      };

      nixosConfigurations.ace = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./hosts/ace/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          inputs.chaotic.nixosModules.default
        ];
      };

      nixosConfigurations.thinkpad = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./hosts/thinkpad/configuration.nix
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
          inputs.home-manager.nixosModules.home-manager
        ];
      };

      # Servers
      nixosConfigurations.dopey = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/dopey/configuration.nix ];
      };

      nixosConfigurations.sleepy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/sleepy/configuration.nix ];
      };

      nixosConfigurations.doc = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/doc/configuration.nix ];
      };

      nixosConfigurations.grumpy = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [ ./hosts/grumpy/configuration.nix ];
      };
    };
}
