{ pkgs, pathfinder-toolchain, ... }:
let
  rustToolchain =
    let
      toml = fromTOML (builtins.readFile pathfinder-toolchain);
      stable = pkgs.fenix.toolchainOf {
        channel = toml.toolchain.channel;
        sha256 = "sha256-SDu4snEWjuZU475PERvu+iO50Mi39KVjqCeJeNvpguU=";
      };
    in
    pkgs.fenix.combine [
      stable.cargo
      stable.rustc
      stable.rust-src
      stable.rust-std
      stable.clippy
      # Use nightly rustfmt for latest formatting features
      pkgs.fenix.latest.rustfmt
    ];

  # Cairo Native requires LLVM 19 (mlir-sys expects MLIR_SYS_190_PREFIX, llvm-sys v191.x)
  llvm = pkgs.llvmPackages_19;

  # NixOS splits LLVM into separate store paths, but cairo-native's crates expect
  # a single prefix. We wrap llvm-config to return combined LLVM+MLIR paths.
  cairoNativeLlvm =
    let
      includeDir = pkgs.symlinkJoin {
        name = "llvm-mlir-include";
        paths = [
          "${llvm.llvm.dev}/include"
          "${llvm.mlir.dev}/include"
        ];
      };
      libDir = pkgs.symlinkJoin {
        name = "llvm-mlir-lib";
        paths = [
          "${llvm.llvm.lib}/lib"
          "${llvm.mlir}/lib"
        ];
      };
    in
    pkgs.symlinkJoin {
      name = "cairo-native-llvm";
      paths = [
        llvm.llvm.dev
        llvm.mlir
        llvm.mlir.dev
      ];
      postBuild = ''
        rm $out/bin/llvm-config
        cat > $out/bin/llvm-config << 'EOF'
        #!/usr/bin/env bash
        for arg in "$@"; do
          case "$arg" in
            --includedir) echo "${includeDir}"; exit 0;;
            --libdir)     echo "${libDir}"; exit 0;;
          esac
        done
        exec ${llvm.llvm.dev}/bin/llvm-config "$@"
        EOF
        chmod +x $out/bin/llvm-config
      '';
    };
in
{
  devShells.default =
    with pkgs;
    mkShell {
      packages = [
        gnumake
        pkg-config
        protobuf
        openssl
        zstd
        libxml2

        rustToolchain
        cargo-edit
        just

        nodejs
      ]
      # required for cairo native compilation
      ++ [
        cairoNativeLlvm
        llvm.clangUseLLVM
        llvm.libclang
      ];

      # Fortify hardening breaks jemalloc compilation
      hardeningDisable = [ "fortify" ];
      # https://github.com/NixOS/nixpkgs/issues/370494#issuecomment-2625163369
      CFLAGS = "-DJEMALLOC_STRERROR_R_RETURNS_CHAR_WITH_GNU_SOURCE";
      # Required for bindgen to find libclang.so
      LIBCLANG_PATH = "${llvm.libclang.lib}/lib";
    };
}
