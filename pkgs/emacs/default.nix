{ lib, emacs, cairo, fetchurl, jansson, harfbuzz, ... }:

with lib;

emacs.overrideAttrs(old: {
  name = "emacs-pretest-27.0.91";
  src = fetchurl {
    url = https://mirrors.tuna.tsinghua.edu.cn/gnu-alpha/emacs/pretest/emacs-27.0.91.tar.xz;
    sha256 = "1aj52fymw4iq9n5sahpb3wncm0cvshwmjr3833mirj6yhp9kv0cn";
  };
  buildInputs = old.buildInputs ++ [ cairo jansson harfbuzz ];
  configureFlags =
    old.configureFlags ++ [ "--with-cairo" "--without-imagemagick" ];
  patches = [
    ./tramp-detect-wrapped-gvfsd-27.patch
    ./clean-env.patch
  ];
})
