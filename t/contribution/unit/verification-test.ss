(import :std/test :std/error
        (only-in :clan/poo/object .o .ref .put!)
        :poo-flow/src/module-system/contribution/verification)
(export verification-test)

(def (snapshot value) (call-with-output-string (lambda (p) (write (.ref value 'claim) p))))
(def (operation value now until) (equal? (.ref value 'claim) "trusted"))
(def verification-test
  (test-suite "Sealed verification admission"
  (test-case "only issued matching receipts are admitted within their validity interval"
    (let* ((adapter (poo-flow-verification-adapter "test" operation snapshot))
           (claim (.o claim: "trusted"))
           (receipt (poo-flow-verify adapter claim 10 20)))
      (check-equal? (poo-flow-verification-valid? adapter receipt claim 10) #t)
      (check-equal? (poo-flow-verification-valid? adapter receipt claim 9) #f)
      (check-equal? (poo-flow-verification-valid? adapter receipt claim 20) #f)
      (check-equal? (poo-flow-verification-valid? adapter (.o (:: @ receipt)) claim 11) #f)
      (check-equal? (poo-flow-verification-valid? adapter receipt (.o claim: "forged") 11) #f)
      (.put! receipt 'expires-at 200)
      (check-equal? (poo-flow-verification-valid? adapter receipt claim 11) #f)))
  (test-case "revocation, issuer isolation and rejected operations are enforced"
    (let* ((a (poo-flow-verification-adapter "a" operation snapshot))
           (b (poo-flow-verification-adapter "b" operation snapshot))
           (claim (.o claim: "trusted")) (receipt (poo-flow-verify a claim 0 10)))
      (check-equal? (poo-flow-verification-valid? b receipt claim 1) #f)
      (check-equal? (poo-flow-verify a (.o claim: "forged" verified?: #t) 0 10) #f)
      (poo-flow-revoke-verification! a receipt)
      (check-equal? (poo-flow-verification-valid? a receipt claim 1) #f)
      (check-exception (poo-flow-verify a claim 10 10) Error?)))
  (test-case "an operation cannot change the value it is attesting"
    (let ((adapter (poo-flow-verification-adapter "mutating"
                     (lambda (v now until) (.put! v 'claim "changed") #t) snapshot)))
      (check-exception (poo-flow-verify adapter (.o claim: "trusted") 0 10) Error?)))))
