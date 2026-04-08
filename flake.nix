{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    pathfinder-toolchain.url = "file+https://raw.githubusercontent.com/equilibriumco/pathfinder/refs/heads/main/rust-toolchain.toml";
    pathfinder-toolchain.flake = false;
  };

  outputs =
    inputs@{
      fenix,
      flake-parts,
      nixpkgs,
      pathfinder-toolchain,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-linux"
      ];
      perSystem =
        { system, ... }:
        {
          _module.args = {
            inherit pathfinder-toolchain;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ fenix.overlays.default ];
            };
          };

          imports = [
            ./devshells.nix
          ];
        };
    };
}
