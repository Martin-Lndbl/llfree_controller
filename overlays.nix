{ inputs, ... }:

final: _prev: rec {
  llfree_linux = _prev.callPackage ./pkgs/llfree_kernel.nix { };
  linuxPackages_llfree = _prev.recurseIntoAttrs (_prev.linuxPackagesFor llfree_linux);
  llfree_linux-alloc-bench = _prev.callPackage ./pkgs/llfree_linux-alloc-bench.nix { };
}
