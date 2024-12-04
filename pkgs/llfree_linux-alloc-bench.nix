{
  linuxPackages_llfree,
  llvmPackages_16,
  fetchFromGitHub,
  ...
}:
let
  kernel = linuxPackages_llfree.kernel;
in
with llvmPackages_16;
stdenv.mkDerivation rec {
  pname = "linux-alloc-bench";
  version = "bd682985584908587c34b5ce73e4b5340e4cca69";

  src = fetchFromGitHub {
    owner = "luhsra";
    repo = pname;
    rev = version;
    hash = "sha256-VCqkaP6P9xv5PvUKZWLjUmhsRDI1eLSBZoA1W0S5Srw=";
  };

  hardeningDisable = [
    "pic"
    "format"
  ];

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "LINUX_SRC_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source"
    "LINUX_BUILD_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"

    "LLVM=1"
    "LD=${bintools-unwrapped}/bin/ld.lld"
    "AR=${bintools-unwrapped}/bin/llvm-ar"
    "NM=${bintools-unwrapped}/bin/llvm-nm"
    "STRIP=${bintools-unwrapped}/bin/llvm-strip"
    "OBJCOPY=${bintools-unwrapped}/bin/llvm-objcopy"
    "OBJDUMP=${bintools-unwrapped}/bin/llvm-objdump"
    "READELF=${bintools-unwrapped}/bin/llvm-readelf"
    "HOSTAR=${bintools-unwrapped}/bin/llvm-ar"
  ];

  installPhase = ''
    mkdir $out
    cp * $out
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;
}
