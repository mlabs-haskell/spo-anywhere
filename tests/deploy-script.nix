inputs: { config, pkgs, ... }: {
  spo-anywhere.tests = {
    deploy-script = let
      common = {
        config,
        pkgs,
        ...
      }: {
        networking = {
          firewall.enable = false; # Useful when running the test interactively
        };
        virtualisation = {
          cores = 2;
          memorySize = 1512;
          writableStore = false;
        };
        # Useful for debugging the test
        environment = {
          systemPackages = [
            # config.services.cardano-node.cardanoNodePackages.cardano-cli
            # pkgs.jq
          ];
        };
      };
    ssh-keys = pkgs.runCommand "deploy-test-ssh-keys" {} ''
      mkdir $out
      ${pkgs.openssh}/bin/ssh-keygen -f $out/my_key -P "password"
    '';
    installed = {
      imports = [
        # common
        # self.nixosModules.default <- can't do, so:
        (import ../modules/deploy-script )
        (import ./disko.nix inputs)
      ];
      config = {
        spo-anywhere.deploy-script.enable = true;
      };
    };
    # TODO: how to test other systems?
    system = "x86_64-linux";
    deploy-script = (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        installed
      ];
    }).config.system.build.spoDeployScript; 
    in {
      systems = [system];

      module = {
        name = "deploy script";

        nodes = {
          installer = {
            pkgs,
            lib,
            ...
          }: {
            imports = [common];
            config = {
              environment.systemPackages = [
                (pkgs.writeShellApplication {
                  name = "deploy";
                  runtimeInputs = [
                    deploy-script
                  ];
                  text = ''
                    cp ${ssh-keys}/my_key ssh-keys
                    chmod 400 ./ssh-keys
                    spo-deploy-script --target root@host --spo-keys . --ssh-key ./ssh-keys
                  '';
                  # spo-deploy-script --target root@host --spo-keys . --ssh-key ./ssh-keys
                })
              ];
            };
          };
          host = {
            imports = [common];
            config = {
              services.openssh.enable = true;
              users.users.root.openssh.authorizedKeys.keyFiles = [ "${ssh-keys}/my_key.pub" ];
            };
          };
        };
        testScript = ''
          start_all()
          print(installer.succeed("deploy"))
        '';
      };
    };
  };
}
