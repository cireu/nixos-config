# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let unstablePkg = import <nixpkgs-unstable> {};
in
{

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./services/v2ray-ipv4-transproxy.nix
      ./services/guix.nix
    ];

  nix.binaryCaches = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
    useOSProber = true;
  };

  fonts = {
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      emacs-all-the-icons-fonts
    ] ++ [
      unstablePkg.sarasa-gothic # For Slab variant
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Sarsa Mono SC" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans CJK SC" ];
        serif = [ "Noto Serif CJK SC" ];
      };
    };
  };
  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.interfaces.wlp0s20u9.useDHCP = true;

  services.v2ray-ipv4-transproxy = let
    assets = {
      "geoip.dat" = pkgs.fetchurl {
        url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202006130214/geoip.dat";
        sha256 = "273d10dc8dede54a55bc2caeb9220eedd88a4f6f2a9d0631b93837faf38aab75";
      };
      "geosite.dat" = pkgs.fetchurl {
        url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202006130214/geosite.dat";
        sha256 = "992929d803ef5bf6750111603fcfd42f8763806248494437e19bed580a6d1cbf";
      };
    };
    v2ray = pkgs.v2ray.override {
      inherit assets;
    };
  in
    {
      enable = true;
      package = v2ray;
      redirPort = 7892;
      configPath = ./secrets/v2ray/config.json;
    };

  services.guix-daemon.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.inputMethod.enabled = "fcitx";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    binutils clang llvm git git-crypt
    libsForQt5.fcitx-qt5
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  programs.gnupg.agent.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.citreu = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
   };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
