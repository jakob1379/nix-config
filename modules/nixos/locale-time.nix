{
  config,
  lib,
  ...
}:

{
  time.timeZone = "Europe/Copenhagen";

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "da_DK.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings =
    let
      defaultLocale =
        if
          lib.hasAttr "i18n" config
          && lib.hasAttr "defaultLocale" config.i18n
          && config.i18n.defaultLocale != null
        then
          config.i18n.defaultLocale
        else
          "en_US.UTF-8";
    in
    {
      LC_ADDRESS = defaultLocale;
      LC_IDENTIFICATION = defaultLocale;
      LC_MEASUREMENT = defaultLocale;
      LC_MONETARY = defaultLocale;
      LC_NAME = defaultLocale;
      LC_NUMERIC = defaultLocale;
      LC_PAPER = defaultLocale;
      LC_TELEPHONE = defaultLocale;
      LC_TIME = defaultLocale;
    };

  console.keyMap = "dk-latin1";
}
