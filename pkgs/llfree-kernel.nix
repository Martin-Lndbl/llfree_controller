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
    version = "6.1";

    stdenv = llvmPackages_16.stdenv;

    src = fetchFromGitHub {
      owner = "luhsra";
      repo = "llfree-linux";
      rev = "v${version}";
      hash = "sha256-7HBzP6P/7KLCfKas4TRFfCutG0azFzV+IpQABtDMHnk=";
    };

    extraMakeFlags = [
      "LLVM=1"
      "LD=${llvmPackages_16.bintools-unwrapped}/bin/ld.lld"
      "AR=${llvmPackages_16.bintools-unwrapped}/bin/llvm-ar"
      "NM=${llvmPackages_16.bintools-unwrapped}/bin/llvm-nm"
      "STRIP=${llvmPackages_16.bintools-unwrapped}/bin/llvm-strip"
      "OBJCOPY=${llvmPackages_16.bintools-unwrapped}/bin/llvm-objcopy"
      "OBJDUMP=${llvmPackages_16.bintools-unwrapped}/bin/llvm-objdump"
      "READELF=${llvmPackages_16.bintools-unwrapped}/bin/llvm-readelf"
      "HOSTAR=${llvmPackages_16.bintools-unwrapped}/bin/llvm-ar"
    ];

    modDirVersion = lib.versions.pad 3 version;

    # option X86_PLATFORM_DRIVERS_HP specified out of scope
    ignoreConfigErrors = true;
  }
  // (args.argsOverride or { })
)
