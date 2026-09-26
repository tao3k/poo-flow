;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO-native CLOS module declaration.
;;; Runtime factors stay lazy; selecting the module does not import interface.ss.

(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-modules-system-use-module
                 poo-flow-user-module-selection)
        (only-in :poo-flow/src/module-system/descriptor/interface
                 poo-flow-modules)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface)
        (only-in :poo-flow/src/module-system/loader/source
                 make-poo-flow-module-local-source))

(export poo-clos-module-interface
        poo-clos-module
        poo-clos-module-bundles
        poo-clos-module-default-selection)

(def poo-clos-module-interface
  (poo-flow-module-interface
   "PooClos"
   (.o)
   '((owner . poo-clos)
     (runtime-factors . (types objects funcs classes dispatch
                         method-combination interface))
     (runtime-lazy? . #t)
     (runtime-executed . #f))))

(def poo-clos-module
  (poo-flow-modules
   poo-clos-module-interface
   (.o id: 'poo-clos
       imports: '()
       config: (.o)
       extensions: '()
       scripts: '()
       group: 'core
       flags: '(+native)
       features: '(native-poo native-mop c4 multiple-dispatch
                   method-combination lexical-next)
       depth: (cons -110 -110)
       phase-files:
       '((config . "src/module-system/poo-clos/config.ss")
         (interface . "core/poo-clos/interface.ss"))
       metadata:
       '((owner . poo-clos)
         (precedence-owner . clan/poo)
         (runtime-lazy? . #t))
       source-ref:
       (make-poo-flow-module-local-source
        "src/module-system/poo-clos/config.ss"))))

(def poo-clos-module-default-selection
  (poo-flow-modules-system-use-module 'poo-clos '(+native)))

(def poo-clos-module-bundles
  (list
   (list
    (poo-flow-user-module-selection 'core 'poo-clos '(+native)))))
