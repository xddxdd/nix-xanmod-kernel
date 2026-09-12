inputs:
pkgs:
let
  load =
    path:
    pkgs.lib.removeAttrs
      (pkgs.callPackage path {
        inherit inputs;
      })
      [
        "override"
        "overrideDerivation"
      ];
  kernels = load ./kernel-xanmod;
  packages = load ./kernel-xanmod/packages.nix;
in
kernels // packages