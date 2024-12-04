{ inputs, ... }:

final: _prev: rec {
  linux_llfree = _prev.callPackage ./pkgs/llfree-kernel.nix { };
  linuxPackages_llfree = _prev.recurseIntoAttrs (_prev.linuxPackagesFor linux_llfree);
}
