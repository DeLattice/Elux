{ pkgs ? import <nixpkgs> {} }:

let
  # 1. Yarn dependencies
  frontendDeps = pkgs.yarn2nix.mkYarnDeps {
    src = ./frontend;
  };

  # 2. Frontend build
  frontend = pkgs.stdenv.mkDerivation {
    name = "frontend-build";
    src = ./frontend;

    nativeBuildInputs = [ pkgs.nodejs pkgs.yarn ];

    buildPhase = ''
      export PATH=${frontendDeps}/bin:$PATH
      echo "🏗️ Building Angular frontend..."
      yarn run build --output-path=dist/frontend/browser --configuration=production
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/frontend/browser/* $out/
    '';
  };

  # 3. Backend (Rust)
  backend = pkgs.rustPlatform.buildRustPackage {
    pname = "backend";
    version = "1.0.0";

    src = ./backend;

    cargoLock = {
      lockFile = ./backend/Cargo.lock;
    };

    cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    preBuild = ''
      echo "🚚 Copying frontend assets..."
      mkdir -p static
      cp -r ${frontend}/* static/
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp target/release/backend $out/bin/
    '';
  };
in
{
  frontend = frontend;
  backend = backend;
  defaultPackage = backend;
}
