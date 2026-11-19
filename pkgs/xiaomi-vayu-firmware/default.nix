{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation {
  pname = "xiaomi-vayu-firmware";
  version = "0-unstable-2026-04-26";

  src = fetchFromGitLab {
    owner = "alinasrullayev";
    repo = "firmware-xiaomi-vayu";
    rev = "9240ae83a70189c7513666a245a72de2c7aaf698";
    hash = "sha256-mE0oUDrNd0+nw6I9yo8l17raFKjqHzJ9CFQAgoPN7UQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    while IFS="" read -r _i || [ -n "$_i" ]; do
      install -Dm644 "$_i" "$out/''${_i/"/xiaomi/"/"/Xiaomi/"}"
    done < "${./firmware.files}"

    ln -s Xiaomi "$out/lib/firmware/qcom/sm8150/xiaomi"

    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "Firmware for Xiaomi POCO X3 Pro";
    homepage = "https://gitlab.com/alinasrullayev/firmware-xiaomi-vayu";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    # Needs to override ath10k/WCN3990/hw1.0/firmware-5.bin from linux-firmware.
    # See <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/work_items/3803>.
    priority = 7;
  };
}
