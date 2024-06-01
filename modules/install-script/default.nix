# This module defines deployment script at `config.system.build.spoInstallScript`.
{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    spo-anywhere.install-script = {
      enable =
        lib.mkEnableOption "Create deployment script at `config.system.build.spoInstallScript`."
        // {default = config.spo-anywhere.enable or false;};
    };
  };

  config = let
    cfg = config.spo-anywhere.install-script;
  in
    lib.mkIf cfg.enable {
      system.build.spoInstallScript = pkgs.writeShellApplication {
        name = "spo-install-script";
        runtimeInputs = with pkgs; [nixos-anywhere getopt];
        text = ''
          # shellcheck disable=SC2154

          # ### command parsing ###

          usage() {
            echo "Usage: spo-install-script --target <target> --ssh-key <filepath> --spo-keys <directory>"
          }

          args="$(getopt --name spo-install-script -o 'h' --longoptions target:,ssh-key:,spo-keys: -- "$@")"
          eval set -- "$args"
          while true; do
            case "$1" in
              --target)
                  target="$2"
                  shift 2
                    ;;
              --ssh-key)
                  ssh_key="$2"
                  shift 2
                  ;;
              --spo-keys)
                  spo_keys="$2"
                  shift 2
                  ;;
              -h|--help)
                  usage ; exit;;
              --)
                  shift; break;;
              *)
                  printf "Unknown option %s\n" "$1"; usage; exit 1;;
            esac
          done

          if [ -z "''${target:+true}" ] || [ -z "''${spo_keys:+true}" ] || [ -z "''${ssh_key:+true}" ]; then
            usage
            exit 1
          fi

          # ### main ###

          # here spo_keys should be of form dir/path/to/where/spo/expects/keys.
          # Options:
          #   1. leave to user to care
          #   2. make our key generation commands, generate the keys in a directory of this form
          #   3. Copy to tmp/dir/path/to/where/spo/expects/keys. set cleanup hook
          #   4. use scp instead
          nixos-anywhere \
            --store-paths ${config.system.build.toplevel} ${config.system.build.diskoScript} \
            --extra-files "$spo_keys" \
            -i "$ssh_key" \
            "$target"
        '';
      };
    };
}
