;;; -*- Gerbil -*-
;;; Boundary: Funflow declares its dependency on the shared method-combination
;;; standard without importing that module's private implementation factors.

(import (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-standard-library-source))

(export poo-flow-funflow-method-combination-module-ref)

;;; Engineering note: a standard-library source ref is inert module metadata;
;;; descriptor realization remains owned by the Loader.
;; : PooModuleSourceRef
(def poo-flow-funflow-method-combination-module-ref
  (poo-flow-standard-library-source 'poo-method-combination))
