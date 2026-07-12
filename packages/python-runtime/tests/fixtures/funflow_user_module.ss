;;; -*- Gerbil -*-
;;; Boundary: user-authored Scheme FunFlow module loaded from Python.

(use-composition python-runtime-ci
  (use-module funflow as ff
    (profiles github-ci python-anyio))

  (compose
    (profiles ff github-ci python-anyio))

  (stage default
    (step build
      (run "gxpkg" "build"))
    (step test
      (run "gxtest" "t/unit-tests.ss"))
    (step package
      (run "tar" "cf" "artifact.tar" "build"))
    (edges
      (build -> test)
      (test -> package))))
