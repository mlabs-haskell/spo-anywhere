# This module defines deployment script at `config.system.build.spoInstallScript`.
{inputs}: {
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

          # args="$(getopt --name spo-install-script -o 'h' --longoptions target:,ssh-key:,spo-keys: )"
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

          echo "rest of args:" "$@"


          # prepare keys, copy to tmp dir and set permissions
          # tmp_keys="$(mktemp -d --tmpdir=.)"
          tmp_keys="my_tmp_keys"
          trap cleanup 0
          # chmod +t "$tmp_keys" # only file owner access file inside
          # target_key_path=/etc/spo-anywhere/block-producer-keys
          target_key_path=${config.spo-anywhere.node.block-producer-key-path}
          mkdir -p "''${tmp_keys}''${target_key_path}"
          chmod 755 "''${tmp_keys}''${target_key_path}"
          # umask 277
          # cp --no-preserve=mode -r "''${spo_keys}"/* "''${tmp_keys}''${target_key_path}"
          cp --no-preserve=mode,owner -r "''${spo_keys}"/* "''${tmp_keys}''${target_key_path}"
          # cp -r "''${spo_keys}"/* "''${tmp_keys}''${target_key_path}"
          # chown -R cardano-node "''${tmp_keys}"
          # chmod -R u=rX,g=,o=w "''${tmp_keys}''${target_key_path}"
          stat "''${tmp_keys}''${target_key_path}"

          echo "$tmp_keys"
          ls -1la "$tmp_keys"

          # here spo_keys should be of form dir/path/to/where/spo/expects/keys.
          # Options:
          #   1. leave to user to care
          #   2. make our key generation commands, generate the keys in a directory of this form
          #   3. Copy to tmp/dir/path/to/where/spo/expects/keys. set cleanup hook
          #   4. use scp instead
          #             --extra-files "$spo_keys" \
          nixos-anywhere \
            --debug \
            --store-paths ${config.system.build.diskoScript} ${config.system.build.toplevel} \
            --kexec ${kexec-installer} \
            -i "$ssh_key" \
            --copy-host-keys \
            --extra-files "$tmp_keys" \
            --no-reboot \
            "$target" 2>&1
          
          echo "installed"
          # sleep 300
          # rsync -e "ssh -i $ssh_key" --chmod=u=rX,g=,o= "$spo_keys" "$target":/etc/spo-anywhere/ 2>&1
          # ssh -i "$ssh_key" "$target" chmod u=rX,g=,o= /etc/spo-anywhere 2>&1

          # target="root@${config.networking.hostName}"
          
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$ssh_key" "$target" ls -1la / /etc /mnt /run /root 2>&1

          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$ssh_key" "$target" chown -R ${builtins.toString config.users.users.cardano-node.uid} "''${target_key_path}" 2>&1

            #   users.users.cardano-node = {
            # description = "cardano-node node daemon user";
            # uid = 1001;
          echo "keys copied"
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$ssh_key" "$target" shutdown -r +1 2>&1
        '';
      };
    };
}
