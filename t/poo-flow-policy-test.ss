;;; -*- Gerbil -*-
;;; Boundary: static gxtest bridge for poo-flow CLI scoped policy checks.

(import :gerbil/gambit
        (only-in :gslph/src/policy/gxtest
                 make-policy-test))

(export poo-flow-cli-policy-decode-test-files
        poo-flow-cli-policy-test-files
        poo-flow-cli-policy-test)

;; : String
(def +poo-flow-cli-policy-files-env+
  "POO_FLOW_TEST_FILES")

;; : (-> MaybeString [String])
(def (poo-flow-cli-policy-decode-test-files value)
  (if (and value (not (string=? value "")))
    (let (datum (read (open-input-string value)))
      (if (list? datum) datum []))
    []))

;; : (-> Unit [String])
(def (poo-flow-cli-policy-test-files)
  (poo-flow-cli-policy-decode-test-files
   (getenv +poo-flow-cli-policy-files-env+ #f)))

(def poo-flow-cli-policy-test
  (make-policy-test "." (poo-flow-cli-policy-test-files)))
