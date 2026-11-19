self:
{
  config,
  lib,
  ...
}:
let
  cfg = config.vanilla-mobile.soc.sm8150;
in
{
  imports = [
    (import ./xiaomi-vayu.nix self)
  ];

  options.vanilla-mobile.soc.sm8150 = {
    enable = lib.mkEnableOption "sm8150";

    audio.enable = lib.mkEnableOption "audio";
    modem.enable = lib.mkEnableOption "modem";
    sensors.enable = lib.mkEnableOption "sensors";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        vanilla-mobile.soc = {
          qualcomm.enable = true;
          sm8150 = {
            audio.enable = lib.mkDefault true;
            modem.enable = lib.mkDefault true;
            sensors.enable = lib.mkDefault true;
          };
        };

        # Prevent the devices from running out of RAM or generally
        # freezing up while building their configurations.
        nix.settings.max-jobs = lib.mkDefault 2;

        # These devices have limited RAM.
        zramSwap.enable = lib.mkDefault true;

        boot = {
          kernelPackages = lib.mkForce (
            config.vanilla-mobile.installer.crossPkgs.linuxPackagesFor config.vanilla-mobile.installer.vanillaMobileCrossPkgs.linuxKernels.linux_sm8150
          );

          blacklistedKernelModules = [
            # Can cause boot lockups on Qualcomm SoCs if loaded early.
            "ipa"
          ];
          kernelParams = [
            "console=tty0"
          ];
          initrd = {
            # disable default modules (some of which dont exist in our kernel).
            includeDefaultModules = false;
            availableKernelModules = [
              "sd_mod"
            ];
            kernelModules = [
              "dm_mod"
            ];

            systemd.tpm2.enable = false;
          };
        };
      }
      # Audio
      (lib.mkIf cfg.audio.enable {
        vanilla-mobile = {
          soc.qualcomm.audio.enable = true;
          alsa-ucm-conf = {
            enable = true;
            package = self.packages.alsa-ucm-conf-sm8150;
            mergeWithDefault = true;
          };
        };

        # Call audio routing (q6voiced) is not configured in the sm8150 DTS yet.
        services.q6voiced.enable = lib.mkDefault false;
      })
      # Modem
      (lib.mkIf cfg.modem.enable {
        vanilla-mobile.soc.qualcomm.modem.enable = true;
      })
      # Sensors
      (lib.mkIf cfg.sensors.enable {
        vanilla-mobile.soc.qualcomm.sensors.enable = true;
      })
    ]
  );
}
