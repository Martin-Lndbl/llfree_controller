{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    unstablepkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstablepkgs,
      flake-utils,
      ...
    }@inputs:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unstable = unstablepkgs.legacyPackages.${system};
        flakepkgs = self.packages.${system};
        buildDeps =
          pkgs:
          (with pkgs; [
            pkg-config
            gnumake
            flex
            bison
            git
            wget
            libuuid
            gcc
            qemu_full
            cmake
            unzip
            clang
            openssl
            ncurses
            bridge-utils
            python3
            python3Packages.numpy
            python3Packages.matplotlib
            python3Packages.scipy
            gnuplot
            llvmPackages_15.bintools
            perl
            doxygen
            gzip
            ncurses
            ncurses.dev
            gdb
          ]);
        make-disk-image = import (./nix/make-disk-image.nix);
      in
      {
        packages = {
          guest-image = make-disk-image {
            config = self.nixosConfigurations.guest.config;
            inherit (pkgs) lib;
            inherit pkgs;
            format = "qcow2";
          };

          linux-firmware-pinned = (
            pkgs.linux-firmware.overrideAttrs (
              old: new: {
                src = fetchGit {
                  url = "git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
                  ref = "main";
                  rev = "8a2d811764e7fcc9e2862549f91487770b70563b";
                };
                version = "8a2d81";
                outputHash = "sha256-dVvfwgto9Pgpkukf/IoJ298MUYzcsV1G/0jTxVcdFGw=";
              }
            )
          );
        };

        devShells = {
          default = pkgs.mkShell {
            name = "devShell";
            buildInputs = (buildDeps pkgs);
          };
          devShells.fhs =
            (pkgs.buildFHSEnv {
              name = "devShell";
              targetPkgs = pkgs: ((buildDeps pkgs));
              runScript = "bash";
            }).env;
        };

      }
    ))
    // {
      nixosConfigurations =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          flakepkgs = self.packages.x86_64-linux;
        in
        {
          guest = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (import ./nix/guest-config.nix {
                inherit pkgs;
                inherit (pkgs) lib;
                inherit flakepkgs;
              })
              ./nix/nixos-generators-qcow.nix
            ];
          };
        };
    };
}
