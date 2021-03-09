{ pkgs ? import <nixpkgs> { } }:
# gr.nix file in your depot folder
with pkgs;
let
  src = fetchTarball {
    url = https://gr-framework.org/downloads/gr-0.53.0-Debian-x86_64.tar.gz;
    sha256 = "0i9b875d02rkw1qgn2vgq4mwyg0fzklbgfj4yhxg0grj44sjk2ha";
  };

in
runCommand "gr-0.53.0" { inherit src; } ''
  mkdir -p $out
  cp -r $src/. $out
''
