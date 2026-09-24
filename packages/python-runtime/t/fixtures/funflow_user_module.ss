;;; -*- Gerbil -*-
;;; Boundary: user-authored Scheme FunFlow module loaded from Python.

(user-composition python-runtime-ci
  (compose profiles
    (use-module FunflowProfileModule as ff github-ci python-anyio)
    PythonRuntimeCIScenarioProfile))

python-runtime-ci
