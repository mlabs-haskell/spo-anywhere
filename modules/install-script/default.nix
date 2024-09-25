# This module defines deployment script at `config.system.build.spoInstallScript`.
{inputs}: {
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    spo-anywhere.install-script = with lib;
    with types; {
      enable =
        mkEnableOption "Create deployment script at `config.system.build.spoInstallScript`."
        // {default = config.spo-anywhere.enable or false;};
      target = mkOption {
        type = nullOr str;
        default = null;
        example = "root@128.196.0.1";
        description = ''
          The target DNS address to deploy to. Overwritten by a command line argument.
        '';
      };
    };
  };

  config = let
    cfg = config.spo-anywhere.install-script;
  in
    lib.mkIf cfg.enable {
      system.build.spoInstallScript = pkgs.writeShellApplication {
        name = "spo-install-script";
        runtimeInputs = with pkgs; [nixos-anywhere getopt rsync];
        text = let
          kexec-installer =
            (builtins.toString
              inputs.nixos-images.packages."${pkgs.stdenv.system}".kexec-installer-nixos-unstable-noninteractive)
            + "/nixos-kexec-installer-noninteractive-${pkgs.stdenv.system}.tar.gz";
        in ''
          # shellcheck disable=SC2154

          # ### command parsing ###

          usage() {
            echo "Usage: spo-install-script --target <target> --ssh-key <filepath> --spo-keys <directory> [-- <nixos-anywhere options>]"
          }

          cleanup() {
            rm -rf "$tmp_keys"
          }

          target="${builtins.toString (config.spo-anywhere.install-script.target or "")}"

          # todo: make target optional option

          args="$(getopt --name spo-install-script -o 'h' --longoptions target:,ssh-key:,spo-keys: -- "$@")"
          eval set -- "$args"
          while true; do
            case "$1" in
              --target)
                  # todo: verify thats correct, namely is target set to ":" or "" or does it not appear as a case here?
                  target="''${2:-''${target}}"
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

          # # prepare keys, copy to tmp dir and set permissions
          tmp_keys="$(mktemp -d --tmpdir=.)"
          trap cleanup 0
          target_key_path=${config.spo-anywhere.node.block-producer-key-path}
          mkdir -p "''${tmp_keys}''${target_key_path}"
          cp -vr "''${spo_keys}"/* "''${tmp_keys}''${target_key_path}/"

          # here spo_keys should be of form dir/path/to/where/spo/expects/keys.
          # Options:
          #   1. leave to user to care
          #   2. make our key generation commands, generate the keys in a directory of this form
          #   3. Copy to tmp/dir/path/to/where/spo/expects/keys. set cleanup hook
          #   4. use scp instead
          nixos-anywhere \
            --debug \
            --kexec ${kexec-installer} \
            -i "$ssh_key" \
            --copy-host-keys \
            --extra-files "$tmp_keys" \
            "$target" "$@" 2>&1

          echo "installed"
        '';
      };
    };
}
