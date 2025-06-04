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
      lib.mkLib = { pkgs, mirroritPackage ? inputs.self.packages."${system}".mirrorit }: let
        mkMirror = {
          name,
          repo_url,
          destination_path,
          enable ? true,
          timer ? true,
          ...
        }: {
          service = {
            "mirrorit-${name}" = {
              inherit enable;
              description = "mirroring service for ${repo_url}";

              requires = ["network.target"];

              script = ''
                ${pkgs.bash}/bin/bash ${mirroritPackage}/bin/mirrorit "${repo_url}" "${destination_path}"
              '';
            };
          };

          timer = {
            "mirrorit-${name}-timer" = {
              inherit enable;

              description = "trigger for mirroring service for ${repo_url}";
              timerConfig = {
                OnCalendar = "weekly";
                Unit = "mirrorit-${name}.service";
                RandomizedDelaySec = "1200";
              };

              requires = ["network.target"];
              wantedBy = ["timers.target"];
            };
          };
        };
      in
      {
        inherit
          mkMirror
          ;
      };

      packages = rec {
        default = mirrorit;

        mirrorit = pkgs.writeShellApplication {
          name = "mirrorit";
          text = builtins.readFile ./mirrorit;
        };
      };
    });
}
