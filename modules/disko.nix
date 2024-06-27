{disko, ...}: {lib, modulesPath, ...}: {
  imports = [
    disko.nixosModules.disko
    "${modulesPath}/virtualisation/digital-ocean-config.nix"
    # (modulesPath + "/profiles/all-hardware.nix")
  ]; 

  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];

  # boot.loader.grub.device = "/dev/vda";

  # fileSystems."/" = {
  #   device = lib.mkForce "/dev/vda1";
  #   fsType = "ext4";
  # };

  # networking.useDHCP = true;
  # networking.firewall.enable = false;
  users.users.root.password = "spo";
  disko.devices = {
    disk = {
      vda = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # boot = {
            #   size = "1M";
            #   type = "EF02";
            # };
            # ESP = {
            #   size = "100M";
            #   type = "EF00";
            #   content = {
            #     type = "filesystem";
            #     format = "vfat";
            #     mountpoint = "/boot";
            #   };
            # };
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
