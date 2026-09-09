;;; -*- Gerbil -*-
;;; Boundary: first-class POO method-combination module declaration.
;;; Invariant: the default module imports only the kernel/public facade;
;;; Observation integration remains an explicit +observation plugin factor.

(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-modules-system-use-module
                 poo-flow-user-module-selection)
        (only-in :poo-flow/src/module-system/descriptor
                 poo-flow-modules)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface
                 poo-flow-option-override)
        (only-in :poo-flow/src/module-system/source
                 make-poo-flow-module-local-source)
        "interface.ss")

(export (import: "interface.ss")
        poo-method-combination-module-interface
        poo-method-combination-module
        poo-method-combination-module-bundles
        poo-method-combination-module-default-selection
        poo-method-combination-observation-plugin-selection)

;;; The interface describes activation data. Method declarations themselves
;;; remain native POO objects exported by interface.ss.
(def poo-method-combination-module-interface
  (poo-flow-module-interface
   "PooMethodCombination"
   (.o observation: (poo-flow-option-override 'Boolean #f))
   '((owner . poo-method-combination)
     (kernel-factors . (types objects funcs))
     (public-factor . interface)
     (optional-plugin-factors . (observation))
     (runtime-executed . #f))))

;;; Doom-like module descriptor: a closed kernel, one public factor, and an
;;; opt-in plugin factor. Merely importing config.ss never imports plugins/observation.ss.
(def poo-method-combination-module
  (poo-flow-modules
   poo-method-combination-module-interface
   (.o id: 'poo-method-combination
       imports: '()
       config: (.o observation: #f)
       extensions: '()
       scripts: '()
       group: 'core
       flags: '(+standard)
       features: '(native-poo c3 standard-method-combination lexical-next)
       depth: (cons -110 -110)
       phase-files:
       '((objects . "src/modules/poo-method-combination/objects.ss")
         (config . "src/modules/poo-method-combination/config.ss"))
       metadata:
       '((owner . poo-method-combination)
         (kernel-factors . (types objects funcs))
         (public-factor . interface)
         (optional-plugin-factors . (observation)))
       source-ref:
       (make-poo-flow-module-local-source
        "src/modules/poo-method-combination/config.ss"))))

;;; Default activation is the closed module only.
(def poo-method-combination-module-default-selection
  (poo-flow-modules-system-use-module
   'poo-method-combination
   '(+standard)))

;;; The kernel profile consumes this module before its dependents by depth.
;;; It is not owned by Funflow or Observability.
(def poo-method-combination-module-bundles
  (list
   (list
    (poo-flow-user-module-selection
     'core
     'poo-method-combination
     '(+standard)))))

;;; Observation is selected explicitly; the plugin owner is still
;;; src/modules/poo-method-combination/plugins/observation.ss.
(def poo-method-combination-observation-plugin-selection
  (poo-flow-modules-system-use-module
   'poo-method-combination
   '(+observation)))
