{
  users.users.root.openssh.authorizedKeys.keys = [(builtins.throw "Add your SSH key here")];

  spo-anywhere.install-script.target = builtins.throw "Add the target here e.g. root@X.X.X.X";
}
