{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    cinc-workstation.url = "https://downloads.cinc.sh/files/stable/cinc-workstation/24.8.1068/debian/12/cinc-workstation_24.8.1068-1_amd64.deb";
    cinc-workstation.flake = false;
  };

  outputs = { flake-parts, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  debug = true;
    systems = [ "x86_64-linux" ];
    perSystem = { systen, config, self', inputs', pkgs, lib, ... }: {
      packages = rec {
        cinc-workstation-sources = pkgs.stdenv.mkDerivation {
          name = "cinc-workstation";
          src = inputs.cinc-workstation;
          dpkg = pkgs.dpkg;
          rpath = lib.makeLibraryPath [ pkgs.libxcrypt-legacy ];
          builder = ./builder.sh;
        };
        cinc-workstation-run = pkgs.buildFHSEnv {
          name = "cinc-workstation-run";
          targetPkgs = pkgs: with pkgs; [ coreutils glibc cinc-workstation-sources ];
          extraBuildCommands = ''
            mkdir -p $out/opt
            ln -s ${cinc-workstation-sources}/cinc-workstation $out/opt/cinc-workstation
          '';
          runScript = "$out/opt/cinc-workstation/bin/cw-wrapper";
        };
        cinc-workstation = pkgs.stdenv.mkDerivation {
          name = "cinc";
          src = cinc-workstation-sources;
          buildInputs = [ cinc-workstation-run ];
          installPhase = ''
            mkdir -p $out/bin
            for bin in $src/cinc-workstation/bin/*; do
              echo -e "#!/usr/bin/env bash\n$buildInputs/bin/cinc-workstation-run $(basename $bin) \"\$@\"" > $out/bin/$(basename $bin)
              chmod +x $out/bin/$(basename $bin)
            done
          '';
        };
      };
    };
  };
}
