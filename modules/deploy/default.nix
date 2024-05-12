# This dummy module simply adds `hello` to the system PATH
{ pkgs, config, ... }: {
  config = {
    system.build.spoDeployScript = pkgs.writeShellApplication {
      name = "spo-deploy-script";
      runtimeInputs = with pkgs; [ nixos-anywhere getopt ];
      text = ''
        # shellcheck disable=SC2154

        # ### command parsing ###

        usage() {
          echo "Usage: spo-deploy-script --target <target> --key-dir <key-dir>"
        }

        args="$(getopt --name spo-deploy-script -o 'h' --longoptions target:,key-dir: -- "$@")"
        eval set -- "$args"
        while true; do
          case "$1" in
            --target)
                target="$2"
                shift 2
                  ;;
            --key-dir)
                key_dir="$2"
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

        if [ -z "''${target:+true}" ] || [ -z "''${key_dir:+true}" ]; then
          usage
          exit 1
        fi

        # ### main ###

        # here key_dir should be of form dir/path/to/where/spo/expects/keys.
        # Options:
        #   1. leave to user to care
        #   2. make our key generation commands, generate the keys in a directory of this form
        #   3. Copy to tmp/dir/path/to/where/spo/expects/keys. set cleanup hook
        nixos-anywhere --store-paths ${config.system.build.toplevel} ${config.system.build.diskoScriptNoDeps} \
          --extra-files "$key_dir" \
          "$target"
      '';
    };
  };
}
