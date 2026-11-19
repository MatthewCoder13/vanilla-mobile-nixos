# Xiaomi POCO X3 Pro (xiaomi-vayu)

## Setup Instructions

These instructions require `fastboot`. You can access it with `nix-shell -p android-tools`.

### Prep Work

Before installing Linux on the POCO X3 Pro:

- Your device's bootloader needs to be unlocked. To unlock the bootloader, follow [these](https://wiki.lineageos.org/devices/vayu/install/#unlocking-the-bootloader) instructions.
- Note down your device's display panel variant (`tianma` or `huaxing`). You can find this out by following [these](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu)#Panel_Types) instructions.
- Update your device's firmware following [these](https://wiki.lineageos.org/devices/vayu/fw_update) instructions.

### Installing NixOS

1. Create a simple "install" NixOS configuration for the phone.
2. Use `disko` to build the configuration into flashable images.
3. Flash U-Boot to the phone.
4. Flash the NixOS configuration images to the phone.
5. Boot into NixOS and customize your config.

### NixOS Config

Copy `examples/installConfigs/xiaomi-vayu` from this repository
into your NixOS configuration.

Here's a simple example of that for flakes:

`flake.nix`
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vanilla-mobile-nixos.url = "github:vanilla-mobile-nixos/vanilla-mobile-nixos";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      vanilla-mobile-nixos,
      disko,
      ...
    }:
    {
      nixosConfigurations.xiaomi-vayu = nixpkgs.lib.nixosSystem {
        modules = [
          vanilla-mobile-nixos.nixosModules.vanilla-mobile
          disko.nixosModules.disko
          ./hosts/xiaomi-vayu/configuration.nix
        ];
      };
    };
}
```

Open `xiaomi-vayu/configuration.nix` and ensure `vanilla-mobile.device.xiaomi-vayu.displayPanel` is set to your display variant (`"tianma"` or `"huaxing"`).

## NixOS Image Building

Build the script that will generate the images:
`nix build .#nixosConfigurations.xiaomi-vayu.config.system.build.diskoImagesScript`

Run the script (with LUKS password):
`bash -c 'read -s -p "LUKS Password: " p; tmp=$(mktemp); trap "rm \"$tmp\"" EXIT; echo "$p" > "$tmp"; ./result --pre-format-files "$tmp" /tmp/nixos-root.key'`

### U-Boot

- Build the U-Boot boot image:
  - `nix build .#nixosConfigurations.xiaomi-vayu.config.vanilla-mobile.deviceInfo.uboot`
- Go into fastboot mode on the phone.
- Flash U-Boot to the phone: `fastboot erase dtbo erase boot flash boot result/u-boot.img`
- Do not reboot or power off the phone yet.

### NixOS Image Flashing

Note: `xiaomi-vayu` uses dynamic partitions (`super`), or you can flash `nixos-boot.raw` to `cache` / subpartition and `nixos-root.raw` to `userdata` depending on your U-Boot partition layout.

- Flash the NixOS boot image:
  - `fastboot flash cache nixos-boot.raw` (or `system` if non-super / blkmap subpartition)
- Flash the NixOS root image to the phone's `userdata` partition:
  - `fastboot erase userdata flash userdata nixos-root.raw`
- Reboot the phone with `fastboot reboot`.
