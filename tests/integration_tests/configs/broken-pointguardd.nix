{ pkgs ? import ../../../nix { } }:
let pointguardd = (pkgs.callPackage ../../../. { });
in
pointguardd.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-pointguardd.patch
  ];
})
