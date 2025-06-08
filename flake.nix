{
  description = "A utility to mirror git repositories";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system: {
      lib.mkLib = { pkgs, mirroritPackage ? inputs.self.packages."${system}".mirrorit }: let
        mkMirror = {
          name,
          repo_url,
          destination_path,
          enable ? true,
          extraServiceAttrs ? {},
          timer ? true,
          extraTimerAttrs ? {},
          ...
        }: {
          systemd.services."mirrorit-${name}" = pkgs.lib.attrsets.recursiveUpdate {
            inherit enable;
            description = "mirroring service for ${repo_url}";

            requires = ["network.target"];

            script = ''
              ${pkgs.lib.getExe pkgs.bash} ${mirroritPackage}/bin/mirrorit "${repo_url}" "${destination_path}"
            '';
          } extraServiceAttrs;

          systemd.timers."mirrorit-${name}-timer" = pkgs.lib.attrsets.recursiveUpdate {
            enable = timer;

            description = "trigger for mirroring service for ${repo_url}";
            timerConfig = {
              OnCalendar = "weekly";
              Unit = "mirrorit-${name}.service";
              RandomizedDelaySec = "1200";
            };

            requires = ["network.target"];
            wantedBy = ["timers.target"];
          } extraTimerAttrs;
        };
      in
      {
        inherit
          mkMirror
          ;
      };

      packages = let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = let
            selfOverlay = _: _: { } // inputs.self.packages."${system}";
          in [ selfOverlay ];
        };
      in rec {
        default = mirrorit;

        mirrorit = pkgs.writeShellApplication {
          name = "mirrorit";
          text = builtins.readFile ./mirrorit;
        };
      };
    });
}
