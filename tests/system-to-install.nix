{disko, ...}: {
  modulesPath,
  self,
  ...
}: {
  imports = [
    disko.nixosModules.disko
    (modulesPath + "/testing/test-instrumentation.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];
  documentation.enable = false;
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;
  # networking.hostId = "8425e349"; # from profiles/base.nix, needed for zfs
  # boot.zfs.devNodes = "/dev/disk/by-uuid"; # needed because /dev/disk/by-id is empty in qemu-vms
  disko.devices = {
    disk = {
      vda = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "100M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
