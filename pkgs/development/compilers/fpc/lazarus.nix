{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  writeText,
  fpc,
  gtk2,
  glib,
  pango,
  atk,
  gdk-pixbuf,
  libXi,
  xorgproto,
  libX11,
  libXext,
  gdb,
  gnumake,
  binutils,
  withQt ? false,
  qtbase ? null,
  libqtpas ? null,
  wrapQtAppsHook ? null,
}:

# TODO:
#  1. the build date is embedded in the binary through `$I %DATE%` - we should dump that

let
  version = "4.0-0";

  # as of 2.0.10 a suffix is being added. That may or may not disappear and then
  # come back, so just leave this here.
  majorMinorPatch = v: builtins.concatStringsSep "." (lib.take 2 (lib.splitVersion v));

  overrides = writeText "revision.inc" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "const ${k} = '${v}';") {
        # this is technically the SVN revision but as we don't have that replace
        # it with the version instead of showing "Unknown"
        RevisionStr = version;
      }
    )
  );

  qtVersion = lib.versions.major qtbase.version;
in
stdenv.mkDerivation rec {
  pname = "lazarus-${LCL_PLATFORM}";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/lazarus/Lazarus%20Zip%20_%20GZip/Lazarus%20${majorMinorPatch version}/lazarus-${version}.tar.gz";
    hash = "sha256-vIM7RxzXqCYSiavND1OhFjuMcG5FmD+zq6kmEiM5z8s=";
  };

  postPatch = ''
    cp ${overrides} ide/${overrides.name}
  '';

  buildInputs = [
    # we need gtk2 unconditionally as that is the default target when building applications with lazarus
    fpc
    gtk2
    glib
    libXi
    xorgproto
    libX11
    libXext
    pango
    atk
    stdenv.cc
    gdk-pixbuf
  ]
  ++ lib.optionals withQt [
    libqtpas
    qtbase
  ];

  # Disable parallel build, errors:
  #  Fatal: (1018) Compilation aborted
  enableParallelBuilding = false;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optional withQt wrapQtAppsHook;

  makeFlags = [
    "FPC=fpc"
    "PP=fpc"
    "LAZARUS_INSTALL_DIR=${placeholder "out"}/share/lazarus/"
    "INSTALL_PREFIX=${placeholder "out"}/"
    "REQUIRE_PACKAGES+=tachartlazaruspkg"
    "bigide"
  ];

  LCL_PLATFORM = if withQt then "qt${qtVersion}" else "gtk2";

  NIX_LDFLAGS = lib.concatStringsSep " " (
    [
      "-L${lib.getLib stdenv.cc.cc}/lib"
      "-lX11"
      "-lXext"
      "-lXi"
      "-latk-1.0"
      "-lc"
      "-lcairo"
      "-lgcc_s"
      "-lgdk-x11-2.0"
      "-lgdk_pixbuf-2.0"
      "-lglib-2.0"
      "-lgtk-x11-2.0"
      "-lpango-1.0"
    ]
    ++ lib.optionals withQt [
      "-L${lib.getLib libqtpas}/lib"
      "-lQt${qtVersion}Pas"
    ]
  );

  preBuild = ''
    mkdir -p $out/share "$out/lazarus"
    tar xf ${fpc.src} --strip-components=1 -C $out/share -m
    substituteInPlace ide/packages/ideconfig/include/unix/lazbaseconf.inc \
      --replace '/usr/fpcsrc' "$out/share/fpcsrc"
  '';

  postInstall =
    let
      ldFlags = ''$(echo "$NIX_LDFLAGS" | sed -re 's/-rpath [^ ]+//g')'';
    in
    ''
      wrapProgram $out/bin/startlazarus \
        --prefix NIX_LDFLAGS ' ' "${ldFlags}" \
        --prefix NIX_LDFLAGS_${binutils.suffixSalt} ' ' "${ldFlags}" \
        --prefix LCL_PLATFORM ' ' "$LCL_PLATFORM" \
        --prefix PATH ':' "${
          lib.makeBinPath [
            fpc
            gdb
            gnumake
            binutils
          ]
        }"
    '';

  meta = with lib; {
    description = "Graphical IDE for the FreePascal language";
    homepage = "https://www.lazarus.freepascal.org";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ raskin ];
    platforms = platforms.linux;
  };
}
