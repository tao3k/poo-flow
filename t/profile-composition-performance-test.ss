;;; -*- Gerbil -*-

(import :std/test
        :std/misc/process)

(def +composition-benchmark-expression+
  "(begin
     (import
      \"./t/scenarios/performance/composition-macro-expansion/benchmark.ss\"
      (only-in :gerbil/gambit exit))
     (write
      (composition-macro-expansion-benchmark->alist
       (run-composition-macro-expansion-benchmark)))
     (newline)
     (exit 0))")

(def (composition-benchmark-alist-ref alist key)
  (let (entry (assoc key alist))
    (and entry (cdr entry))))

(def (run-composition-benchmark-process)
  (let (output
        (run-process
         (list "gxi" "-e" +composition-benchmark-expression+)
         stderr-redirection: #t))
    (call-with-input-string output read)))

(def profile-composition-performance-tests
  (test-suite
   "profile composition expansion performance"
   (test-case
    "1000 and 5000 profile expansion remain bounded and RSS-stable"
    (let* ((receipt (run-composition-benchmark-process))
           (case-1000
            (composition-benchmark-alist-ref receipt 'case-1000))
           (case-5000
            (composition-benchmark-alist-ref
             receipt
             'case-5000-second)))
      (check-equal?
       (composition-benchmark-alist-ref case-1000 'profile-count)
       1000)
      (check-equal?
       (composition-benchmark-alist-ref
        case-1000
        'generated-profile-expression-count)
       1000)
      (check-equal?
       (composition-benchmark-alist-ref case-5000 'profile-count)
       5000)
      (check-equal?
       (composition-benchmark-alist-ref
        case-5000
        'generated-compose-reference-count)
       5000)
      (check-equal?
       (composition-benchmark-alist-ref case-1000 'gsc-executed)
       #f)
      (check-equal?
       (composition-benchmark-alist-ref receipt 'stable-rss)
       #t)
      (check-equal?
       (composition-benchmark-alist-ref receipt 'pass)
       #t)))))

(run-tests! profile-composition-performance-tests)
