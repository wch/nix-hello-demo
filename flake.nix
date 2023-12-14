{
  description = "Hello program";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11"; };

  outputs = { self, nixpkgs }:
    let
      allSystems =
        [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];

      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs allSystems (system:
          f rec {
            pkgs = import nixpkgs { inherit system; };
            inherit system;
          });

    in {
      packages = forEachSupportedSystem ({ pkgs, system, ... }: {

        default = pkgs.stdenv.mkDerivation {
          name = "hello";

          src = self;

          buildInputs = with pkgs; [ gcc ];

          buildPhase = ''
            cc -o hello hello.c
          '';

          # The store path to "which" is baked into src/library/base/R/unix/system.unix.R,
          # but Nix cannot detect it as a run-time dependency because the installed file
          # is compiled and compressed, which hides the store path.
          installPhase = ''
            mkdir -p $out/bin
            cp hello $out/bin
          '';

        };
      });

      apps = forEachSupportedSystem ({ system, ... }: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/hello";
        };
      });

      devShells = forEachSupportedSystem ({ pkgs, system, ... }: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];

          packages = with pkgs; [ git ];

          shellHook = ''
            echo "Hello world shell"
          '';
        };
      });
    };
}
