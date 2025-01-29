{lib, ...}: let
  disk = "sda";
in {
  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  };
  boot.loader.grub.device = lib.mkForce "/dev/${disk}";
  boot.loader.grub.devices = lib.mkForce ["/dev/${disk}"];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/${disk}";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            ESP = {
              size = "512M";
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
