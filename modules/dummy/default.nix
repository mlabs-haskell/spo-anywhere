# This dummy module simply adds `hello` to the system PATH
{pkgs, ...}: {
  config = {
    environment.systemPackages = [
      pkgs.hello
    ];
  };
}
