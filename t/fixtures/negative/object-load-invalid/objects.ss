;;; -*- Gerbil -*-
;;; Boundary: negative load! fixture; importing this module must fail.

(import :poo-flow/src/modules/object-core
        :poo-flow/src/modules/user-config-syntax)

(load! "parts/object1")
