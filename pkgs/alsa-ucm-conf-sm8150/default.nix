{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "alsa-ucm-conf-sm8150";
  version = "0-unstable-2026-05-21";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 ${./HiFi.conf} \
      "$out/share/alsa/ucm2/Xiaomi/vayu/HiFi.conf"

    install -Dm644 ${./vayu.conf} \
      "$out/share/alsa/ucm2/conf.d/sm8150/Xiaomi POCO X3 Pro.conf"

    ln -s "Xiaomi POCO X3 Pro.conf" \
      "$out/share/alsa/ucm2/conf.d/sm8150/xiaomi-XiaomiPOCOX3Pro.conf"

    runHook postInstall
  '';

  meta = {
    description = "ALSA UCM configuration for Qualcomm SM8150 devices";
    license = lib.licenses.mit;
    platforms = [ "aarch64-linux" ];
  };
}
