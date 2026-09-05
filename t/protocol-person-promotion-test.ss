(export protocol-person-promotion-test)

(import :std/test
        :clan/poo/object
        :poo-flow/src/policy/protocol-person-promotion)

(def provenance
  (poo-flow-provenance
   'org-bundle "source-digest-1" 101 '("parent-digest-0") '(receipt-1)))

(def subject
  (poo-flow-protocol-subject
   'subject-1 "candidate-digest-1" 3 provenance 'history 90 120
   '(model-changed repository-changed authority-epoch-changed)))

(def commitment
  (poo-flow-commitment
   'commitment-1 'subject-1 "candidate-digest-1" "contract-digest-1"
   'organization 7 'proposed))

(def intent
  (poo-flow-promotion-intent
   'promotion-1 "candidate-digest-1" 'subject-1 'commitment-1
   'history 'active 'organization 11 7 5 3 "evidence-root-1"
   'materialization-1 'org-bundle-active 'history-slot-1))

(def current-world (poo-flow-promotion-world 11 7 5 3))

(def (facts cedar? lean? evaluator? evidence? count injection?)
  (poo-flow-promotion-decision-facts
   cedar? lean? evaluator? evidence? count injection?))

(def protocol-person-promotion-test
  (test-suite "RFC 149 protocol-person promotion"
  (test-case "protocol subjects keep identity, provenance, and temporal role separate"
    (check (.ref subject 'kind) => 'poo-flow-protocol-subject)
    (check (.ref subject 'content-digest) => "candidate-digest-1")
    (check (.ref subject 'temporal-role) => 'history)
    (check (.ref (.ref subject 'provenance) 'source-digest)
           => "source-digest-1")
    (check (.ref commitment 'subject-digest) => "candidate-digest-1")
    (check (.ref intent 'target-role) => 'active))

    (test-case "dual-engine approval plus exactly-once injection activates"
      (let (receipt
            (poo-flow-promotion-intent-validate
             intent current-world (facts #t #t #t #t 1 #t)))
        (check (poo-flow-promotion-validation-receipt? receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-approved? receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-active? receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-approval-code receipt)
               => 'promotion-approved)
        (check (poo-flow-promotion-validation-receipt-activation-code receipt)
               => 'promotion-active)
        (check (poo-flow-promotion-validation-receipt-runtime-executed receipt)
               => #f)))

    (test-case "Cedar deny and missing Lean proof fail closed"
      (let ((cedar
             (poo-flow-promotion-intent-validate
              intent current-world (facts #f #t #t #t 1 #t)))
            (lean
             (poo-flow-promotion-intent-validate
              intent current-world (facts #t #f #t #t 1 #t))))
        (check (poo-flow-promotion-validation-receipt-approval-code cedar)
               => 'cedar-deny)
        (check (poo-flow-promotion-validation-receipt-approved cedar) => #f)
        (check (poo-flow-promotion-validation-receipt-approval-code lean)
               => 'lean-unverified)
        (check (poo-flow-promotion-validation-receipt-active lean) => #f)))

    (test-case "all four epochs are part of the approval boundary"
      (let* ((stale-world (poo-flow-promotion-world 12 8 6 4))
             (receipt
              (poo-flow-promotion-intent-validate
               intent stale-world (facts #t #t #t #t 1 #t)))
             (failures
              (poo-flow-promotion-validation-receipt-approval-failures receipt)))
        (check (poo-flow-promotion-epochs-match? intent current-world) => #t)
        (check (poo-flow-promotion-epochs-match? intent stale-world) => #f)
        (check (member 'stale-bundle-epoch failures) ? values)
        (check (member 'stale-authority-epoch failures) ? values)
        (check (member 'stale-proof-epoch failures) ? values)
        (check (member 'stale-evaluator-epoch failures) ? values)))

    (test-case "evaluator applicability and evidence completeness are explicit"
      (let (receipt
            (poo-flow-promotion-intent-validate
             intent current-world (facts #t #t #f #f 1 #t)))
        (check (poo-flow-promotion-validation-receipt-approval-failures receipt)
               => '(evaluator-inapplicable evidence-incomplete))
        (check (poo-flow-promotion-validation-receipt-approved receipt) => #f)))

    (test-case "approval does not imply materialization"
      (let (receipt
            (poo-flow-promotion-intent-validate
             intent current-world (facts #t #t #t #t 0 #f)))
        (check (poo-flow-promotion-validation-receipt-approved receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-active receipt) => #f)
        (check (poo-flow-promotion-validation-receipt-activation-code receipt)
               => 'materialization-missing)))

    (test-case "duplicate materialization fails closed"
      (let (receipt
            (poo-flow-promotion-intent-validate
             intent current-world (facts #t #t #t #t 2 #t)))
        (check (poo-flow-promotion-validation-receipt-approved receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-active receipt) => #f)
        (check (poo-flow-promotion-validation-receipt-activation-code receipt)
               => 'materialization-duplicate)))

    (test-case "materialization without an injection receipt stays inactive"
      (let* ((receipt
              (poo-flow-promotion-intent-validate
               intent current-world (facts #t #t #t #t 1 #f)))
             (projection
              (poo-flow-promotion-validation-receipt->alist receipt)))
        (check (poo-flow-promotion-validation-receipt-approved receipt) => #t)
        (check (poo-flow-promotion-validation-receipt-active receipt) => #f)
        (check (poo-flow-promotion-validation-receipt-activation-code receipt)
               => 'injection-receipt-missing)
        (check (cdr (assq 'candidate-digest projection))
               => "candidate-digest-1")
        (check (cdr (assq 'runtime-executed projection)) => #f))))
  )
