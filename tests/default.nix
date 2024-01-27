{
  inputs,
  ...
}: {
  perSystem = _: {
    imports = [
      ./dummy.nix
      (import ./block-producer.nix {inherit inputs;})
    ];
  };
}
