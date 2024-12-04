{
  lib,
  fetchFromGitHub,
  buildLinux,
  llvmPackages_16,
  ...
}@args:

buildLinux (
  args
  // rec {

    stdenv = llvmPackages_16.stdenv;

    version = "6.1";
    modDirVersion = lib.versions.pad 3 version;

    src = fetchFromGitHub {
      owner = "luhsra";
      repo = "llfree-linux";
      rev = "v${version}";
      hash = "sha256-7HBzP6P/7KLCfKas4TRFfCutG0azFzV+IpQABtDMHnk=";
    };

    extraMakeFlags = with llvmPackages_16; [
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

    kernelPatches = [ ];
    extraConfig = "";

    # option X86_PLATFORM_DRIVERS_HP specified out of scope
    ignoreConfigErrors = true;
  }
  // (args.argsOverride or { })
)
