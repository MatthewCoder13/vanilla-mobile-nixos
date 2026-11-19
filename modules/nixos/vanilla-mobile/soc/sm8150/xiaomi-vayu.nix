self:
{
  config,
  lib,
  ...
}:
let
  cfg = config.vanilla-mobile.device.xiaomi-vayu;
in
{
  options.vanilla-mobile.device.xiaomi-vayu = {
    enable = lib.mkEnableOption "Xiaomi POCO X3 Pro (xiaomi-vayu)";
    displayPanel = lib.mkOption {
      type = lib.types.enum [
        "huaxing"
        "tianma"
      ];
      description = "Display panel variant of the Xiaomi POCO X3 Pro.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      if !config.boot.loader.systemd-boot.enable then
        [
          ''
            systemd-boot is disabled. xiaomi-vayu has currently only
            been configured for systemd-boot.
          ''
        ]
      else
        [ ];

    vanilla-mobile = {
      deviceInfo = {
        name = "Xiaomi POCO X3 Pro";
        codename = "xiaomi-vayu";
        manufacturer = "Xiaomi";
        dtb = "qcom/sm8150-xiaomi-vayu-${cfg.displayPanel}.dtb";
        imageSectorSize = 4096;
        firmware = self.packages.xiaomi-vayu-firmware;
        uboot = self.packages.ubootPackages."xiaomi-vayu-${cfg.displayPanel}-boot-image";
      };
      soc.sm8150.enable = true;
    };

    boot = {
      kernelParams = [
        # Look for the firmware we add to `extra-firmware`.
        "firmware_class.path=/extra-firmware"
      ];
      initrd = {
        kernelModules = [
          "gpi"
          "i2c_qcom_geni"
          "spi_qcom_geni"
        ];

        systemd.storePaths =
          map
            (fw: {
              source = "${config.hardware.firmware}/lib/firmware/${fw}.zst";
              target = "/extra-firmware/${fw}.zst";
            })
            (
              [
                "qcom/sm8150/Xiaomi/vayu/adsp.mbn"
                "qcom/sm8150/Xiaomi/vayu/cdsp.mbn"
                "qcom/sm8150/Xiaomi/vayu/ipa_fws.mbn"
                "qcom/sm8150/Xiaomi/vayu/a640_zap.mbn"

                "ath10k/WCN3990/hw1.0/board-2.bin"
                "ath10k/WCN3990/hw1.0/firmware-5.bin"
                "qca/crbtfw21.tlv"
                "qca/crnv21.bin"

                "qcom/a630_sqe.fw"
                "qcom/a640_gmu.bin"
              ]
              ++ (
                if cfg.displayPanel == "tianma" then
                  [ "novatek/j20s_novatek_ts_fw01.bin" ]
                else
                  [ "novatek/j20s_novatek_ts_fw02.bin" ]
              )
            );
      };
    };
  };
}
