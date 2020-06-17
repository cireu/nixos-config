{ config, lib, ... }:

with lib;

let
  cfg = config.services.guix-daemon;
  inherit (cfg) enable buildUsersCount;
in

# ¡¡Impurity Warning!!
{
  options = {
    services.guix-daemon = {
      enable = mkEnableOption "Guix daemon service";
      buildUsersCount = mkOption {
        default = 10;
        description = "Guix worker user accounts count.";
        type = types.int;
      };
    };
  };

  config = mkIf enable {
    users.groups.guixbuild = {
      gid = 40000;
    };

    users.users =
      listToAttrs (map (id:
        let str = toString id; in
        {
          name = "guixbuilder${str}";
          value = {
            description = "Guix builder user ${str}";
            isSystemUser = true;
            extraGroups = [ "guixbuild" ];
          };
        }
      ) (range 1 buildUsersCount));

    environment.profiles = [
      "$HOME/.config/guix/current"
      "$HOME/.guix-profile"
    ];

    environment.variables = {
      GUIX_LOCPATH = "$HOME/.guix-profile/lib/locale";
      GUIX_PROFILE= "$HOME/.guix-profile";
    };

    systemd.services.guix-daemon = {
      description = "Guix daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
        /var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild --substitute-urls="https://mirror.guix.org.cn"
        '';
        RemainAfterExit = true;
        Environment = ''
        'GUIX_LOCPATH=/var/guix/profiles/per-user/root/guix-profile/lib/locale' LC_ALL=en_US.utf8
        '';

        # Some packages (e.g. go@1.8.1) may require even more than 1024 tasks.
        TasksMax = "8192";
      };
    };
  };
}
