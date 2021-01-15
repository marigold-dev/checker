let
  sources = import ./nix/sources.nix { };
  pkgs = import sources.nixpkgs { };
  ligoPkgs =
    let ligoSrc = pkgs.fetchzip {
      url = "https://gitlab.com/ligolang/ligo/-/archive/0.7.0/ligo-0.7.0.zip";
      sha256 = "sha256-x0I1FW7zpaJ4IxLocFvQoEWd25xyYNZynqUZ9KhkvYY="; };
    in (import "${ligoSrc}/nix/pkgs.nix" {});
in
pkgs.mkShell {
  name = "huxian-ocaml";
  buildInputs =
    # ligo does not compile on macos
    pkgs.lib.optional pkgs.stdenv.isLinux ligoPkgs.ligo
    ++ (with pkgs.ocamlPackages; [
      ocaml
      dune_2
      findlib # Lets merlin see packages like ounit
      ocp-indent
      merlin
      ounit
      qcheck
      ppx_deriving
      zarith
      odoc
    ]);
}
