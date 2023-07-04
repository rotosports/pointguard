{ pkgs ? import ../../../nix { } }:
let pointguard = (pkgs.callPackage ../../../. { });
in
ethermint.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-ethermint.patch
  ];
})
