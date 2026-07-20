(import :std/test
        :std/srfi/13
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/composition-typescript)

(def browser-composition
  (use-composition browser-composition
    (use-module research as research
      (profile researcher
        :kind agent
        :scope research
        :capabilities (discover synthesize))
      (profile verifier :kind agent :scope evidence))
    (compose (profiles research researcher verifier))
    (stage collect
      (step researcher)
      (handoff verifier))
    (stage scenario
      (step collect))))

(def composition-typescript-tests
  (test-suite
   "composition TypeScript projection"
   (test-case
    "preserves Profile provenance and recursive Case instances"
    (let (typescript (composition->typescript-string browser-composition))
      (check-equal?
       (integer? (string-contains typescript "composition:browser-composition"))
       #t)
      (check-equal?
       (integer? (string-contains typescript "case:scenario/collect"))
       #t)
      (check-equal?
       (integer?
        (string-contains typescript
                         "profile:scenario/collect/researcher"))
       #t)
      (check-equal?
       (integer? (string-contains typescript "profile:research/researcher"))
       #t)
      (check-equal?
       (integer? (string-contains typescript "profile-instance"))
       #t)
      (check-equal?
       (integer? (string-contains typescript "objectSubtype: \"agent\""))
       #t)
      (check-equal?
       (integer? (string-contains typescript "scope: \"research\""))
       #t)
      (check-equal?
       (integer?
        (string-contains typescript
                         "capabilities: [\"discover\", \"synthesize\"]"))
       #t)))))

(run-tests! composition-typescript-tests)
