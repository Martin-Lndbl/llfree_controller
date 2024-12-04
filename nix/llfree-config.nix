{
  flakepkgs,
  lib,
  pkgs,
  extraEnvPackages ? [ ],
  ...
}:
{
  networking.hostName = "llfree";

  services.sshd.enable = true;
  networking.firewall.enable = false;

  users.users.root.password = "password";
  services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./ssh_key.pub)
  ];
  services.getty.autologinUser = lib.mkDefault "root";

  fileSystems."/root" = {
    device = "home";
    fsType = "9p";
    options = [
      "trans=virtio"
      "nofail"
      "msize=104857600"
    ];
  };

  fileSystems."/nix/store" = {
    device = "myNixStore";
    fsType = "9p";
    options = [
      "trans=virtio"
      "nofail"
      "msize=104857600"
    ];
  };
  boot.initrd.availableKernelModules = [ "overlay" ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.package = pkgs.nixFlakes;
  environment.systemPackages =
    with pkgs;
    [
      kmod
      git
      gnumake
      qemu
      htop
      tmux
      tunctl
      bridge-utils
      killall
      gdb
      iperf
      fio
      pciutils
      just
      python3
      ioport # access port io (pio) via inb and outw commands
      busybox # for devmem to access physical memory
      (writeScriptBin "devmem" ''
        ${busybox}/bin/devmem $@
      '')
      ethtool
      linuxptp
      bpftrace
    ]
    ++ extraEnvPackages;

  boot.kernelPackages =
    let
      llfree-linux-pkg =
        {
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
              # This overrides O="$buildRoot" https://github.com/NixOS/nixpkgs/blob/6f9368f591c653b91c4371e6a9e0e40ef4871441/pkgs/os-specific/linux/kernel/generic.nix#L181
              # "O=build-llfree-vm" 
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

            extraConfig = ''
              INTEL_SGX y
            '';

            ignoreConfigErrors = true;
          }
          // (args.argsOverride or { })
        );
      llfree-linux = pkgs.callPackage llfree-linux-pkg { };
    in
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor llfree-linux);

  boot.kernelModules = [
    "vfio"
    "vfio-pci"
  ];
  boot.kernelParams = [
    "nokaslr"
    "iomem=relaxed"
    # spdk/dpdk hugepages
    "default_hugepages=2MB"
    "hugepagesz=2MB"
    "hugepages=1000"
  ];

  system.stateVersion = "24.05";

  console.enable = true;
  systemd.services."serial-getty@ttys0".enable = true;
  services.qemuGuest.enable = true;
}
