#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/build-script)

;; Build only the package-manager capability updated after Gerbil v0.18.2.
(defbuild-script
  '("gxpkg")
  libdir: (path-expand "lib" (getenv "GERBIL_BUILD_PREFIX" (gerbil-home)))
  bindir: (path-expand "bin" (getenv "GERBIL_BUILD_PREFIX" (gerbil-home)))
  debug: #f)
