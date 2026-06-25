;;; -*- Gerbil -*-
;;; Boundary: aggregate Funflow config checks in one Gerbil loader.

(import :poo-flow/t/funflow-config-pipeline-direct-test
        :poo-flow/t/funflow-config-pipeline-downstream-test
        :poo-flow/t/funflow-config-pipeline-error-test)

(export funflow-config-pipeline-import-ok)

;; Focused modules execute their checks on import; this aggregate preserves
;; loader/expander memory coverage without adding runtime assertions.
;; : Boolean
(def poo-flow-import-side-effect-test-suite? #t)

;; : Symbol
(def funflow-config-pipeline-import-ok 'ok)
