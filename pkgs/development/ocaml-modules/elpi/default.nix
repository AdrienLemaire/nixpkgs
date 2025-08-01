{
  lib,
  buildDunePackage,
  camlp5,
  ocaml,
  menhir,
  menhirLib,
  atdgen,
  atdgen-runtime,
  stdlib-shims,
  re,
  perl,
  ncurses,
  ppxlib,
  ppx_deriving,
  ppxlib_0_15,
  ppx_deriving_0_15,
  coqPackages,
  version ?
    if lib.versionAtLeast ocaml.version "4.13" then
      "2.0.7"
    else if lib.versionAtLeast ocaml.version "4.08" then
      "1.20.0"
    else
      "1.15.2",
}:

let
  p5 = camlp5;
in
let
  camlp5 = p5.override { legacy = true; };
in

let
  fetched = coqPackages.metaFetch ({
    release."2.0.7".sha256 = "sha256-gCM+vZK6vWlhSO1VMjiWHse23mvxVwRarhxwkIQK7e0=";
    release."2.0.6".sha256 = "sha256-tRUYXQZ0VXrjIZBZ1skdzieUsww4rSNEe5ik+iKpk3U=";
    release."2.0.5".sha256 = "sha256-cHgERFqrfSg5WtUX3UxR6L+QkzS7+t6n4V+wweiEacc=";
    release."2.0.3".sha256 = "sha256-t2z0sWPiFgp6LuR6CsH/Zk9qfxW+3QjjFcYrB6qSPgc=";
    release."1.20.0".sha256 = "sha256-lctZAIQgOg5d+LfILtWsBVcsemV3zTZYfJfDlCxHtcA=";
    release."1.19.2".sha256 = "sha256-dBj5Ek7PWq/8Btq/dggJUqa8cUtfvbi6EWo/lJEDOU4=";
    release."1.18.2".sha256 = "sha256-usOYukHQ/h4YBxlhYrAkMTVjNm97hq4IArI9bvDzy/k=";
    release."1.18.1".sha256 = "sha256-rrIv/mVC0Ez3nU7fpnzwduIC3tI6l73DjgAbv1gd2v0=";
    release."1.17.0".sha256 = "sha256-J8FJBeaB+2HtHjrkgNzOZJngZ2AcYU+npL9Y1HNPnzo=";
    release."1.15.2".sha256 = "sha256-+sQYQiN3n+dlzXzi5opOjhkJZqpkNwlHZcUjaUM6+xQ=";
    release."1.15.0".sha256 = "sha256-vpQzbkDqJPCmaBmXcBnzlWGS7djW9wWv8xslkIlXgP0=";
    release."1.13.7".sha256 = "sha256-0QbOEnrRCYA2mXDGRKe+QYCXSESLJvLzRW0Iq+/3P9Y=";
    release."1.12.0".sha256 = "sha256-w4JzLZB8jcxw7nA7AfgU9jTZTr6IYUxPU5E2vNIFC4Q=";
    release."1.11.4".sha256 = "sha256-dyzEpzokgffsF9lt+FZgUlcZEuAb70vGuHfGUtjZYIM=";
    releaseRev = v: "v${v}";
    releaseArtifact = v: if lib.versionAtLeast v "1.13.8" then "elpi-${v}.tbz" else "elpi-v${v}.tbz";
    location = {
      domain = "github.com";
      owner = "LPCIC";
      repo = "elpi";
    };
  }) version;
in
let
  inherit (fetched) version;
in
buildDunePackage {
  pname = "elpi";
  inherit version;
  inherit (fetched) src;

  patches = lib.optional (version == "1.16.5") ./atd_2_10.patch;

  minimalOCamlVersion = "4.07";

  nativeBuildInputs = [
    perl
  ]
  ++ [ (if lib.versionAtLeast version "1.15" || version == "dev" then menhir else camlp5) ]
  ++ lib.optional (lib.versionAtLeast version "1.16" || version == "dev") atdgen;
  buildInputs = [
    ncurses
  ]
  ++ lib.optional (lib.versionAtLeast version "1.16" || version == "dev") atdgen-runtime;

  propagatedBuildInputs = [
    re
    stdlib-shims
  ]
  ++ (if lib.versionAtLeast version "1.15" || version == "dev" then [ menhirLib ] else [ camlp5 ])
  ++ (
    if lib.versionAtLeast version "1.13" || version == "dev" then
      [
        ppxlib
        ppx_deriving
      ]
    else
      [
        ppxlib_0_15
        ppx_deriving_0_15
      ]
  );

  meta = with lib; {
    description = "Embeddable λProlog Interpreter";
    license = licenses.lgpl21Plus;
    maintainers = [ maintainers.vbgl ];
    homepage = "https://github.com/LPCIC/elpi";
  };

  postPatch = ''
    substituteInPlace elpi_REPL.ml --replace-warn "tput cols" "${ncurses}/bin/tput cols"
  ''
  + lib.optionalString (lib.versionAtLeast version "1.16" || version == "dev") ''
    substituteInPlace src/dune --replace-warn ' atdgen re' ' atdgen-runtime re'
  '';
}
