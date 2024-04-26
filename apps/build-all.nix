{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    apps.nix-build-all.program = pkgs.writeShellApplication {
      name = "nix-build-all";
      runtimeInputs = [
        (pkgs.callPackage inputs.devour-flake {})
      ];
      text = ''
        # Make sure that flake.lock is sync
        nix flake lock --no-update-lock-file

        # Do a full nix build (all outputs)
        devour-flake . "$@"
      '';
    };
  };
}
