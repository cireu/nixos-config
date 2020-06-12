{ pkgs, config, lib, ... }:

with lib;

let
  inherit (pkgs) gnugrep iptables v2ray;
  inherit (lib) optionalString mkIf;
  cfg = config.services.v2ray-ipv4-transproxy;
  inherit (cfg) v2rayUserName;
  inherit (cfg) configPath;
  redirProxyPortStr = toString cfg.redirPort;

  tag = "V2RAY_SPEC";

  opts = {
    enable = mkOption {
      type = types.bool;
      default = false;
      # FIXME: Description
    };

    v2rayUserName = mkOption {
      type = types.str;
      default = "v2ray";
      description =
        "The user who would run the v2ray proxy systemd service. will be created automatically.";
    };

    redirPort = mkOption {
      type = types.port;
      default = 1081;
      description =
        "Proxy local redir server (<literal>ss-redir</literal>) listen port";
    };

    configPath = mkOption {
      type = types.path;
      description = "The v2ray configuration file";
    };
  };

in {
  options = {
    services.v2ray-ipv4-transproxy = opts;
  };

  config = mkIf (cfg.enable) {

    users.users.${v2rayUserName} = {
      description = "v2ray deamon user";
      isSystemUser = true;
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    systemd.services.v2ray-ipv4-transproxy = let
      ipt = "${iptables}/bin/iptables";
      preStartScript = pkgs.writeShellScript "v2ray-prestart" ''
        ${ipt} -t nat -N ${tag}
        ${ipt} -t nat -A ${tag} -j RETURN -m owner --uid-owner ${v2rayUserName}
        ${ipt} -t nat -A ${tag} -d 0.0.0.0/8 -j RETURN
        ${ipt} -t nat -A ${tag} -d 127.0.0.0/8 -j RETURN
        ${ipt} -t nat -A ${tag} -p tcp -j REDIRECT --to-ports ${redirProxyPortStr}
        ${ipt} -t nat -A OUTPUT -p tcp -j ${tag}
        '';

      postStopScript = pkgs.writeShellScript "v2ray-poststop" ''
        ${iptables}/bin/iptables-save -c \
        | ${gnugrep}/bin/grep -v ${tag} \
        | ${iptables}/bin/iptables-restore -c
        '';
    in {
      description = "V2ray transparent proxy service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script =
        "exec ${v2ray}/bin/v2ray -config ${toString configPath}";

      # Don't start if the config file doesn't exist.
      unitConfig = { ConditionPathExists = configPath; };
      serviceConfig = {
        ExecStartPre =
          "+${preStartScript}"; # Use prefix `+` to run iptables as root/
        ExecStopPost = "+${postStopScript}";
        # CAP_NET_BIND_SERVICE: Bind arbitary ports by unprivileged user.
        # CAP_NET_ADMIN: Listen on UDP.
        AmbientCapabilities =
          "CAP_NET_BIND_SERVICE CAP_NET_ADMIN"; # We want additional capabilities upon a unprivileged user.
        User = v2rayUserName;
        Restart = "on-failure";
      };
    };
  };
}
