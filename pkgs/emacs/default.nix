{ lib, emacs, cairo, fetchurl, jansson, harfbuzz, ... }:

with lib;

emacs.overrideAttrs(old: {
  name = "emacs-pretest-27.0.91";
  src = fetchurl {
    url = https://mirrors.tuna.tsinghua.edu.cn/gnu-alpha/emacs/pretest/emacs-27.0.91.tar.xz;
    sha256 = "0ykwxdylfnhkys5isq08mhip0fc41lv0gkl9pq8rimnbrr475cb5";
  };
  buildInputs = old.buildInputs ++ [ cairo jansson harfbuzz ];
  configureFlags =
    old.configureFlags ++ [ "--with-cairo" "--without-imagemagick" ];
  patches = [
    ./tramp-detect-wrapped-gvfsd-27.patch
    ./clean-env.patch
  ];
})
