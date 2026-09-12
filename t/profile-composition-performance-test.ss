;;; -*- Gerbil -*-

(import :std/test
        (only-in :clan/poo/object .ref)
        "./scenarios/performance/composition-macro-expansion/benchmark.ss")

(export profile-composition-performance-test)

(def profile-composition-performance-test
  (test-suite
   "profile composition expansion performance"
   (test-case
    "1000 and 5000 profile expansion remain bounded"
    (let* ((receipt (run-composition-macro-expansion-benchmark))
           (case-1000 (.ref receipt 'case-1000))
           (case-5000 (.ref receipt 'case-5000-second)))
      (check-equal?
       (.ref case-1000 'profile-count)
       1000)
      (check-equal?
       (.ref case-1000 'generated-profile-expression-count)
       1000)
      (check-equal?
       (.ref case-5000 'profile-count)
       5000)
      (check-equal?
       (.ref case-5000 'generated-compose-reference-count)
       5000)
      (check-equal?
       (.ref case-1000 'gsc-executed)
       #f)
      (check-equal?
       (.ref case-1000 'timing-source)
       ":clan/timestamp#call-with-timing")
      (check-equal?
       (.ref receipt 'pass)
       #t)))))
