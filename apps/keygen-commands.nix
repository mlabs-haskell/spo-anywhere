{
  perSystem = {
    pkgs,
    inputs',
    lib,
    ...
  }: let
    # Runs the command but first checks if key files already exist.
    # makeKeysAux :: { name, command string using cardano-cli, list of filenames the command produces } -> app
    makeKeysAux = {
      name,
      command,
      files,
    }: let
      all-filenames-string = builtins.concatStringsSep ", " files;
      exitIfFilesExist = ''
        if ${builtins.foldl' (str: fnm: "${str} || [ -f ./${fnm} ]") "false" files};
        then
          echo "File/s ${all-filenames-string} already exists!" && exit 1
        fi
      '';
      echoWroteFiles =
        # cp ${builtins.concatStringsSep " " files} "$out"
        ''
          echo "Wrote ${all-filenames-string}."
        '';
    in {
      type = "app";
      program = pkgs.writeShellApplication {
        runtimeInputs = [inputs'.cardano-node.packages.cardano-cli];
        inherit name;
        text = ''
          ${exitIfFilesExist}
          ${command}
          ${echoWroteFiles}
        '';
      };
    };

    makePaymentKeys = {
      name = "make-payment-keys";
      files = ["payment.vkey" "payment.skey"];
      command = ''
        cardano-cli address key-gen \
          --verification-key-file ./payment.vkey \
          --signing-key-file ./payment.skey
      '';
    };
    makeStakingKeys = {
      name = "make-staking-keys";
      files = ["stake.vkey" "stake.skey"];
      command = ''
        cardano-cli stake-address key-gen \
          --verification-key-file stake.vkey \
          --signing-key-file stake.skey
      '';
    };
    makeStakingAddress = {
      name = "make-staking-address";
      files = ["stake.addr"];
      command = ''
        if [ -z "''${1+x}" ] || [ -z "''${2+x}" ];
        then
          echo "Pass testnet-magic and stake-vkey path as cli arguments in this order!" && exit 1
        else
          cardano-cli stake-address build \
            --stake-verification-key-file "$2" \
            --out-file stake.addr \
            --testnet-magic "$1"
        fi
      '';
    };
    makePaymentAddress = {
      name = "make-payment-address";
      files = ["payment.addr"];
      command = ''
        if [ -z "''${1+x}" ] || [ -z "''${2+x}" ];
        then
          echo "Pass testnet-magic and payment-vkey path as cli arguments in this order!" && exit 1
        else
          cardano-cli address build \
            --payment-verification-key-file "$2" \
            --out-file payment.addr \
            --testnet-magic "$1"
        fi
      '';
    };
    makeNodeColdKeys = {
      name = "make-node-cold-keys";
      files = ["cold.vkey" "cold.skey" "opcert.counter"];
      command = ''
        cardano-cli node key-gen \
          --cold-verification-key-file cold.vkey \
          --cold-signing-key-file cold.skey \
          --operational-certificate-issue-counter-file opcert.counter
      '';
    };
    makeKesKeys = {
      name = "make-kes-keys";
      files = ["kes.vkey" "kes.skey"];
      command = ''
        cardano-cli node key-gen-KES \
          --verification-key-file kes.vkey \
          --signing-key-file kes.skey
      '';
    };
    makeVRFKeys = {
      name = "make-vrf-keys";
      files = ["vrf.vkey" "vrf.skey"];
      command = ''
        cardano-cli node key-gen-VRF \
          --verification-key-file vrf.vkey \
          --signing-key-file vrf.skey
      '';
    };
    # this is valid for some number of slots, needs to be kept updated
    makeOpCert = let
      echo-txt = ''
        Pass kes vkey path, cold skey path, opcert counter path and current kes period as cli arguments in this order!
        Current KES period needs to be calculated by checking current slot number (by querying a node/network) and number of slots per KES period (defined in the shelley genesis file).
        Then divide rounding down the current slot number by the number of slots per KES period.

        Modifies opcert.counter (increments)!
      '';
    in {
      name = "make-opcert";
      files = ["opcert.cert"];
      command = ''
        if [ -z "''${1+x}" ] || [ -z "''${2+x}" ] || [ -z "''${3+x}" ] || [ -z "''${4+x}" ];
          then
            echo "${echo-txt}" && exit 1
        else
          cardano-cli node issue-op-cert --kes-verification-key-file "$1" \
            --cold-signing-key-file "$2" \
            --operational-certificate-issue-counter-file "$3" \
            --kes-period "$4" \
            --out-file opcert.cert
          echo "Incremented opcert.counter."
        fi
      '';
    };
    # TODO: create transactions registering the stake pool
    apps' = {
      inherit makePaymentKeys makeStakingKeys makeStakingAddress makePaymentAddress makeNodeColdKeys makeKesKeys makeVRFKeys makeOpCert;
    };
    apps = builtins.mapAttrs (_: makeKeysAux) apps';
  in {
    inherit apps;
    devshells.spo-shell = {
      devshell = {
        name = "SPO-anywhere";
        motd = ''
          ❄️ Welcome to the {14}{bold}SPO-anywhere{reset} shell ❄️
          It contains useful tools for preparing keys for a stake pool.
          $(type -p menu &>/dev/null && menu)
        '';
      };
      packages = [
        inputs'.cardano-node.packages.cardano-cli
      ];
      commands =
        lib.attrsets.mapAttrsToList (name: value: {
          category = "Key generation";
          name = apps'."${name}".name;
          help = "Generates files: ${builtins.concatStringsSep " " apps'."${name}".files}";
          package = value.program;
        })
        apps;
    };
  };
}
