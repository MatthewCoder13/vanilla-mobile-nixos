self: {
  imports = [
    (import ./sdm845 self)
    (import ./sm8150 self)
    ./qualcomm.nix
  ];
}
