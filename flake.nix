{
  description = "A utility to mirror git repositories";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = let
          selfOverlay = _: _: { } // inputs.self.packages."${system}";
        in [ selfOverlay ];
      };
    in
    {
      packages = {
        mirrorit = pkgs.writeShellApplication {
          name = "mirrorit";
          text = builtins.readFile ./mirrorit;
        };
      };
    });
}
