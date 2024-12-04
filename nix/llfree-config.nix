{
  flakepkgs,
  lib,
  pkgs,
  extraEnvPackages ? [ ],
  ...
}:
rec {
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

  boot.kernelPackages = flakepkgs.linuxPackages_llfree;

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
  boot.extraModulePackages = [ 
    flakepkgs.llfree_linux-alloc-bench
  ];
  system.stateVersion = "24.05";

  console.enable = true;
  systemd.services."serial-getty@ttys0".enable = true;
  services.qemuGuest.enable = true;
}
