;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :std/misc/uuid random-uuid uuid->string)
        (only-in :clan/poo/object .ref)
        (only-in "summary.ss" combination-performance-summaries))
(export combination-summary-test)
;;; These are deliberately wire fixtures, not a domain authoring surface.
(def (trial-wire index elapsed)
  (list '(depth 1) '(from instance) '(qualifiers primary) '(iterations 2)
        (list 'trial index) '(expected 3) '(plan-reused? #t)
        (list 'combination '(checksum 3) (list 'wall-ms elapsed) '(gc-ms 0) '(allocated-bytes 32))
        '(functional (checksum 3) (wall-ms 1) (gc-ms 0) (allocated-bytes 16))))
(def (with-trial-file rows inspect)
  (let* ((directory ".data/qualification/poo-method-combination/summary-fixtures")
         (path (path-expand (uuid->string (random-uuid)) directory)))
    (create-directory* directory)
    (when (file-exists? path) (error "Fixture path already exists" path))
    (unwind-protect
      (begin
        (call-with-output-file path
          (lambda (port)
            (for-each (lambda (row) (write (cons 'performance-trial row) port) (newline port)) rows)))
        (inspect path))
      (when (file-exists? path) (delete-file path)))))
(def combination-summary-test
  (test-suite "research: native qualification statistics"
    (test-case "summary is computed from repeated compatible trials"
      (with-trial-file (list (trial-wire 0 2) (trial-wire 1 4))
        (lambda (path)
          (let* ((summaries (combination-performance-summaries path))
                 (value (car summaries)) (distribution (.ref value 'combination-ms)))
            (check-equal? (length summaries) 1)
            (check-equal? (.ref value 'key) '(1 instance primary))
            (check-equal? (.ref value 'trials) 2)
            (check-equal? (.ref distribution 'median) 3)
            (check-equal? (.ref distribution 'min) 2)
            (check-equal? (.ref distribution 'max) 4)
            (check-equal? (.ref value 'median-ratio) 3)))))
    (test-case "empty, duplicate and inconsistent trials reject"
      (with-trial-file '()
        (lambda (path) (check-exception (combination-performance-summaries path) (lambda (_) #t))))
      (with-trial-file (list (trial-wire 0 2) (trial-wire 0 4))
        (lambda (path) (check-exception (combination-performance-summaries path) (lambda (_) #t))))
      (with-trial-file
        (list (trial-wire 0 2)
              (map (lambda (field) (if (eq? (car field) 'expected) '(expected 4) field)) (trial-wire 1 4)))
        (lambda (path) (check-exception (combination-performance-summaries path) (lambda (_) #t)))))))
