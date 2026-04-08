# nix-pathfinder

Nix flake dev environment for [pathfinder](https://github.com/equilibriumco/pathfinder).

Provides: Rust toolchain (via fenix, matching pathfinder's `rust-toolchain.toml`), LLVM 19 for cairo-native, and build dependencies.

## Setup

In the pathfinder repo root:

```sh
echo 'use flake "github:zvolin/pathfinder-flake"' > .envrc && direnv allow
```

Requires [nix](https://nixos.org/) and [nix-direnv](https://github.com/nix-community/nix-direnv).
