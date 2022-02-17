{
  channels,
  inputs,
}:
channels.nixpkgs.devshell.mkShell {
  name = "devShell";
  packages = [];
  imports = [(channels.nixpkgs.devshell.importTOML ./devshell.toml)];
  commands = [];
}
