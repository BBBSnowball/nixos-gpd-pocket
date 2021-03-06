{ pkgs, ... }:
let
  rev = {
    "4.17-rc3.hdg.1" = "b8653b1e56ee1b5e8b3e11d7c17928dc7b9be3c8";
    "5.7" = "ba6f71b5034b9e74fb1f74d15a81491edae5e2d8";
    "5.8" = "842bb80b0ed5e8f34d9c9bd403e4b510acfe7514";
  };
  sha256 = {
    "4.17-rc3.hdg.1" = "137wldp9szs2w1zv5qxnlbzijgwal7iq47bfi4vzzwai7w0f8inm";
    "5.7" = "sha256-F2T60oMq1KFC1QJLkEq1BWa7DMhZhqqveYqffz4IVuw=";
    "5.8" = "0l6yawcn6slqj4kzarz1w2yj9wfa0p068ilfzmlfhfyylgk094m1";
  };
  #version =  "4.17-rc3.hdg.1";
  version =  "5.7";

  cleanSource = src: pkgs.runCommand "clean-src-${version}" {} ''
    set -ex
    cp -r ${src} $out
    chmod u+rw -R $out
    rm $out/.config
    ${pkgs.gnumake}/bin/make -C $out mrproper
  '';

  pkg = { stdenv, buildPackages, gnumake, hostPlatform, fetchurl, fetchFromGitHub, perl, buildLinux, libelf, utillinux, flex, bison, ... } @ args:
    buildLinux (args // rec {
      inherit version;
      kernelPatches = [
        pkgs.kernelPatches.bridge_stp_helper
        #pkgs.kernelPatches.modinst_arg_list_too_long
      ];
      modDirVersion = "${version}.0";
      extrameta.branch = "${version}-footrail";
      src = cleanSource (fetchFromGitHub {
        owner = "jwrdegoede";
        repo = "linux-sunxi";
        rev = rev.${version};
        sha256 = sha256.${version};
      });
      nativeBuildInputs = [ flex bison ];
      extraConfig = ''
       ACPI_CUSTOM_METHOD m
       B43_SDIO y
       BATTERY_MAX17042 m

       COMMON_CLK y

       INTEL_SOC_PMIC? y
       INTEL_SOC_PMIC_CHTWC? y
       #FIXME: INTEL_PMC_IPC m
       INTEL_BXTWC_PMIC_TMU m

       ACPI y
       PMIC_OPREGION y
       CHT_WC_PMIC_OPREGION? y
       XPOWER_PMIC_OPREGION y
       BXT_WC_PMIC_OPREGION y
       CRC_PMIC_OPREGION? y # wtf. nix kernel config script is madness
       XPOWER_PMIC_OPREGION y
       CHT_DC_TI_PMIC_OPREGION y

       #EXTCON_INTEL_CHT_WC? y # wtf

       DW_DMAC y
       DW_DMAC_CORE y
       DW_DMAC_PCI y
       GPD_POCKET_FAN y
       HSU_DMA y
       I2C_CHT_WC? y
       I2C_DESIGNWARE_BAYTRAIL? y
       INTEL_CHT_INT33FE m
       MFD_AXP20X m
       #MUX_INTEL_CHT_USB_MUX m
       TYPEC_MUX_PI3USB30532 m
       #MUX_PI3USB30532 m
       NVRAM y
       POWER_RESET y
       PWM y
       PWM_LPSS m
       PWM_LPSS_PCI m
       PWM_LPSS_PLATFORM m
       PWM_SYSFS y
       RAW_DRIVER y
       #FIXME: RTC_DS1685_SYSFS_REGS y
       SERIAL_8250_DW y
       SERIAL_8250_MID y
       SERIAL_8250_NR_UARTS 32
       SERIAL_8250_PCI m
       SERIAL_DEV_BUS y
       SERIAL_DEV_CTRL_TTYPORT y
       TOUCHSCREEN_ELAN m
       TULIP_MMIO y
       W1_SLAVE_DS2433_CRC y
       XXHASH y


       TYPEC_TCPM m
       I2C y
       I2C_DESIGNWARE_PLATFORM y
       ACPI y
       TYPEC_WCOVE m
       #MFD_INTEL_PMC_BXT m
       INTEL_SOC_PMIC m
       BXT_WC_PMIC_OPREGION y

       TYPEC_UCSI m
       UCSI_CCG m
       UCSI_ACPI m
       TYPEC_DP_ALTMODE m
       USB_ROLE_SWITCH m
       USB_ROLES_INTEL_XHCI m
       USB_LED_TRIG y
       USB_ULPI_BUS m

       CHARGER_BQ24190 m

       MATOM y

       # some "random" stuff from stockmind's 5.0 kernel config
       ACPI_APEI y
       ACPI_APEI_GHES y
       ACPI_APEI_PCIEAER y
       CPU_FREQ_STAT y
       CPU_FREQ_DEFAULT_GOV_PERFORMANCE n
       CPU_FREQ_DEFAULT_GOV_ONDEMAND y

       #X86_INTEL_UMIP y
       #X86_INTEL_MPX y
       BT_HCIUART_INTEL y
       INTEL_SOC_PMIC y
       INTEL_SOC_PMIC_CHTWC y
       SND_SOC_INTEL_SKYLAKE_HDAUDIO_CODEC y
       INTEL_WMI_THUNDERBOLT m
       INTEL_CHT_INT33FE m
       INTEL_INT0002_VGPIO y
       INTEL_HID_EVENT y
       INTEL_VBTN y
       INTEL_PMC_CORE y
       INTEL_OAKTRAIL m
       INTEL_PMC_IPC y
       INTEL_TURBO_MAX_3 y
       INTEL_CHTDC_TI_PWRBTN m
       INTEL_ATOMISP2_PM y
       INTEL_IOMMU_SVM y
       EXTCON_INTEL_CHT_WC y
       INTEL_TXT y
     '';
  });

in {
  nixpkgs.overlays = [ (self: super: {
    linux_gpd_pocket = super.callPackage pkg {};
  })];
}
