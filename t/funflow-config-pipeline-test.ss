;;; -*- Gerbil -*-
;;; Boundary: aggregate Funflow config checks in one Gerbil loader.

(import :poo-flow/t/funflow-config-pipeline-direct-test
        :poo-flow/t/funflow-config-pipeline-downstream-test
        :poo-flow/t/funflow-config-pipeline-error-test)

(export funflow-config-pipeline-import-ok)

;;; The focused modules execute their checks on import. Keeping this aggregate
;;; in-process preserves coverage for the loader/expander memory boundary.
(def poo-flow-import-side-effect-test-suite? #t)

(def funflow-config-pipeline-import-ok 'ok)
