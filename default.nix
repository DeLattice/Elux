{ pkgs ? import <nixpkgs> {} }:

let
  frontend = pkgs.mkYarnPackage {
    name = "frontend";
    src = ./frontend;
    packageJSON = ./frontend/package.json;
    yarnLock = ./frontend/yarn.lock;

    buildPhase = ''
      export HOME=$(mktemp -d)
      export NG_CLI_ANALYTICS=false

      cd deps/*
      ln -sf ../../node_modules node_modules
      export PATH=$PWD/node_modules/.bin:$PATH

      yarn --offline build
    '';

    installPhase = ''
      mkdir -p $out
      find . -path "*/dist/*" -type f -print0 | xargs -0 -I {} cp --parents {} $out
      cp -r deps/*/dist/* $out/
    '';

    distPhase = "true";
    doCheck = false;
  };

in
pkgs.rustPlatform.buildRustPackage {
  pname = "app-backend";
  version = "0.1.0";

  src = ./backend;

  cargoLock = {
    lockFile = ./backend/Cargo.lock;
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  postInstall = ''
    mkdir -p $out/share/www
    cp -r ${frontend}/* $out/share/www/
  '';
}
