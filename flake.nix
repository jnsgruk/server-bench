{
  description = "web server benchmarking flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    jnsgruk-go-old.url = "github:jnsgruk/jnsgr.uk/25a0f26e7e5a6a351d485e719abec9947d02d944";
    jnsgruk-go.url = "github:jnsgruk/jnsgr.uk/d6f0ec667dcf9950e21fbd3d9241779d56a0b9c0";
    jnsgruk-rust.url = "github:jnsgruk/servy/b237c9d01054ba236fce59dc87de484b3c6429ee";
  };

  outputs =
    {
      self,
      nixpkgs,
      jnsgruk-go,
      jnsgruk-go-old,
      jnsgruk-rust,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs)
            buildGoModule
            cariddi
            coreutils-full
            curl
            faketty
            fetchFromGitHub
            jq
            k6
            lib
            makeWrapper
            nodejs
            pnpm
            sshpass
            stdenv
            ;
        in
        {
          # A virtual machine for load testing the server builds
          benchvm = self.nixosConfigurations.${system}.benchvm.config.system.build.vm;

          # Helper script for running commands inside the test VM when it's running on a host.
          benchvm-exec = pkgs.writeShellApplication {
            name = "benchvm-exec";
            runtimeInputs = [ sshpass ];
            text = builtins.readFile ./scripts/benchvm-exec;
          };

          # Helper script for running commands inside the test VM when it's running on a host.
          benchvm-test = pkgs.writeShellApplication {
            name = "benchvm-test";
            runtimeInputs = [
              self.packages.${system}.benchvm-exec
              sshpass
            ];
            text = builtins.readFile ./scripts/benchvm-test;
          };

          # A wrapper around K6 for load testing my server.
          k6test = stdenv.mkDerivation {
            name = "k6test";
            src = ./.;

            buildInputs = [ makeWrapper ];

            installPhase = ''
              install -Dm 0755 scripts/k6test $out/bin/k6test
              install -Dm 0755 scripts/script.js $out/share/k6test/script.js

              wrapProgram $out/bin/k6test \
                --set K6TEST_SCRIPT "$out/share/k6test/script.js" \
                --prefix PATH : ${
                  lib.makeBinPath ([
                    k6
                    coreutils-full
                    cariddi
                    jq
                    curl
                  ])
                }
            '';

            meta.mainProgram = "k6test";
          };

          # A continuous profiling tool.
          parca = pkgs.callPackage ./parca/parca.nix {
            inherit
              buildGoModule
              faketty
              fetchFromGitHub
              lib
              nodejs
              pnpm
              stdenv
              ;
          };
        }
      );

      # A minimal NixOS virtual machine which used for testing craft applications.
      nixosConfigurations = forAllSystems (system: {
        benchvm = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit self system;
            jnsgruk-go-old = jnsgruk-go-old.packages.${system}.jnsgruk;
            jnsgruk-go = jnsgruk-go.packages.${system}.jnsgruk;
            jnsgruk-rust = jnsgruk-rust.packages.${system}.jnsgruk;
            k6test = self.packages.${system}.k6test;
          };
          modules = [ ./vm.nix ];
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "jnsgruk-server-bench";
            NIX_CONFIG = "experimental-features = nix-command flakes";
            buildInputs =
              (with pkgs; [
                cariddi
                curl
                jq
                k6
              ])
              ++ (with self.packages.${system}; [
                benchvm
                benchvm-exec
                benchvm-test
                k6test
                parca
              ]);
          };
        }
      );
    };
}
