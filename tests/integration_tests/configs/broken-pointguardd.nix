{ pkgs ? import ../../../nix { } }:
let pointguard = (pkgs.callPackage ../../../. { });
in
pointguard.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-pointguard.patch
  ];
})
