{
  stdenv,
  lib,
  fetchFromGitea,
  linux-pam,
  libxcb,
  makeBinaryWrapper,
  zig_0_14,
  callPackage,
  nixosTests,
  x11Support ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ly";
  version = "1.1.1";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "AnErrupTion";
    repo = "ly";
    tag = "v${finalAttrs.version}";
    hash = "sha256-q/MFI02YdAkPdkbi8FtsM46MNalraz2MJf4Oav3fCZA=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    zig_0_14.hook
  ];
  buildInputs = [
    linux-pam
  ]
  ++ (lib.optionals x11Support [ libxcb ]);

  postPatch = ''
    ln -s ${
      callPackage ./deps.nix {
        zig = zig_0_14;
      }
    } $ZIG_GLOBAL_CACHE_DIR/p
  '';
  zigBuildFlags = [
    "-Denable_x11_support=${lib.boolToString x11Support}"
  ];

  passthru.tests = { inherit (nixosTests) ly; };

  meta = {
    description = "TUI display manager";
    license = lib.licenses.wtfpl;
    homepage = "https://codeberg.org/AnErrupTion/ly";
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "ly";
  };
})
