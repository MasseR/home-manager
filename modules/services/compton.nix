{ config, lib, pkgs, ... }:

with lib;
with builtins;

let

  cfg = config.services.compton;

  configFile = pkgs.writeText "compton.conf"
    (optionalString cfg.fade ''
      # fading
      fading = true;
      fade-delta    = ${toString cfg.fadeDelta};
      fade-in-step  = ${elemAt cfg.fadeSteps 0};
      fade-out-step = ${elemAt cfg.fadeSteps 1};
      fade-exclude  = ${toJSON cfg.fadeExclude};
    '' +
    optionalString cfg.shadow ''

      # shadows
      shadow = true;
      shadow-offset-x = ${toString (elemAt cfg.shadowOffsets 0)};
      shadow-offset-y = ${toString (elemAt cfg.shadowOffsets 1)};
      shadow-opacity  = ${cfg.shadowOpacity};
      shadow-exclude  = ${toJSON cfg.shadowExclude};
    '' + 
    optionalString cfg.blur ''

      # blur
      blur-background         = true;
      blur-background-exclude = ${toJSON cfg.blurExclude};
      no-dock-blur            = ${toString cfg.noDockBlur};
    '' + ''

      # opacity
      active-opacity   = ${cfg.activeOpacity};
      inactive-opacity = ${cfg.inactiveOpacity};
      menu-opacity     = ${cfg.menuOpacity};
      opacity-rule     = ${toJSON cfg.opacityRule};

      # other options
      backend = ${toJSON cfg.backend};
      vsync = ${toJSON cfg.vSync};
      refresh-rate = ${toString cfg.refreshRate};
    '' + cfg.extraOptions);

in {

  options.services.compton = {
    enable = mkEnableOption "Compton X11 compositor";

    blur = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable background blur on transparent windows.
      '';
    };

    noDockBlur = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Avoid blur on docks.
      '';
    };

    blurExclude = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "class_g = 'slop'"
        "class_i = 'polybar'"
      ];
      description = ''
        List of windows to exclude background blur.
        See <literal>compton(1)</literal> man page for more examples.
      '';
    };

    fade = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Fade windows in and out.
      '';
    };

    fadeDelta = mkOption {
      type = types.int;
      default = 10;
      example = 5;
      description = ''
        Time between fade animation step (in ms).
      '';
    };

    fadeSteps = mkOption {
      type = types.listOf types.str;
      default = [ "0.028" "0.03" ];
      example = [ "0.04" "0.04" ];
      description = ''
        Opacity change between fade steps (in and out).
      '';
    };

    fadeExclude = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "window_type *= 'menu'"
        "name ~= 'Firefox$'"
        "focused = 1"
      ];
      description = ''
        List of conditions of windows that should not be faded.
        See <literal>compton(1)</literal> man page for more examples.
      '';
    };

    shadow = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Draw window shadows.
      '';
    };

    shadowOffsets = mkOption {
      type = types.listOf types.int;
      default = [ (-15) (-15) ];
      example = [ (-10) (-15) ];
      description = ''
        Horizontal and vertical offsets for shadows (in pixels).
      '';
    };

    shadowOpacity = mkOption {
      type = types.str;
      default = "0.75";
      example = "0.8";
      description = ''
        Window shadows opacity (number in range 0 - 1).
      '';
    };

    shadowExclude = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "window_type *= 'menu'"
        "name ~= 'Firefox$'"
        "focused = 1"
      ];
      description = ''
        List of conditions of windows that should have no shadow.
        See <literal>compton(1)</literal> man page for more examples.
      '';
    };

    activeOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of active windows.
      '';
    };

    inactiveOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of inactive windows.
      '';
    };

    menuOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of dropdown and popup menu.
      '';
    };

    opacityRule = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "87:class_i ?= 'scratchpad'"
        "91:class_i ?= 'xterm'"
      ];
      description = ''
        List of opacity rules.
        See <literal>compton(1)</literal> man page for more examples.
      '';
    };

    backend = mkOption {
      type = types.str;
      default = "glx";
      description = ''
        Backend to use: <literal>glx</literal> or <literal>xrender</literal>.
      '';
    };

    vSync = mkOption {
     type = types.str;
     default = "none";
     example = "opengl-swc";
     description = ''
       Enable vertical synchronization using the specified method.
       See <literal>compton(1)</literal> man page available methods.
     '';
    };

    refreshRate = mkOption {
      type = types.int;
      default = 0;
      example = 60;
      description = ''
       Screen refresh rate (0 = automatically detect).
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.compton;
      defaultText = "pkgs.compton";
      example = literalExample "pkgs.compton";
      description = ''
        Compton derivation to use.
      '';
    };

    extraOptions = mkOption {
      type = types.str;
      default = "";
      example = ''
        unredir-if-possible = true;
        dbe = true;
      '';
      description = ''
        Additional Compton configuration.
      '';
    };
  };

  config = mkIf cfg.enable {

    home.packages = [ cfg.package ];

    systemd.user.services.compton = {
        Unit = {
          Description = "Compton X11 compositor";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/compton --config ${configFile}";
          Restart = "always";
          RestartSec = 3;
        };
    };
  };
}
