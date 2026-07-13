;;; -*- Gerbil -*-
;;; Boundary: verify existing benchmark receipts; never synthesize measurements.

(export #t)

(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/srfi/13 string-index string-prefix?))

(def +runtime-batches+ '(1 8 32 128 1024))
(def +runtime-payloads+ '(0 1024 65536 1048576))
(def +runtime-dispositions+
  '(allow deny success runtime-failure timeout cancel indeterminate))

(def (receipt-lines path)
  (call-with-input-file
   path
   (lambda (port)
     (let loop ((lines '()))
       (let (line (read-line port))
         (if (eof-object? line) (reverse lines)
             (loop (cons line lines))))))))

(def (line-field line)
  (let (separator (string-index line #\=))
    (and separator
         (cons (substring line 0 separator)
               (substring line (+ separator 1) (string-length line))))))

(def (receipt-blocks lines)
  (let loop ((rest lines) (current '()) (blocks '()))
    (cond
     ((null? rest)
      (reverse (if (pair? current) (cons (reverse current) blocks) blocks)))
     ((string=? (car rest) "--")
      (loop (cdr rest) '()
            (if (pair? current) (cons (reverse current) blocks) blocks)))
     (else
      (let (field (line-field (car rest)))
        (loop (cdr rest) (if field (cons field current) current) blocks))))))

(def (block-ref block key)
  (let (entry (assoc key block))
    (and entry (cdr entry))))

(def (runtime-block-signature block)
  (list (string->number (block-ref block "batch"))
        (string->number (block-ref block "payload-bytes"))
        (string->symbol (block-ref block "disposition"))))

(def (expected-runtime-signatures)
  (apply append
         (map (lambda (batch)
                (apply append
                       (map (lambda (payload)
                              (map (lambda (disposition)
                                     (list batch payload disposition))
                                   +runtime-dispositions+))
                            +runtime-payloads+)))
              +runtime-batches+)))

(def (proof-profile-row? line profile batch)
  (string-prefix? (string-append (symbol->string profile) ","
                                 (number->string batch) ",")
                  line))

(def (proof-profile-complete? lines)
  (andmap
   (lambda (profile)
     (andmap (lambda (batch)
               (ormap (lambda (line) (proof-profile-row? line profile batch))
                      lines))
             +runtime-batches+))
   '(strict batched)))

(def (line-present? lines expected)
  (member expected lines))

(def (poo-flow-performance-matrix-verify runtime-path native-proof-path
                                         python-proof-path)
  (let* ((runtime-lines (receipt-lines runtime-path))
         (runtime-blocks-value (receipt-blocks runtime-lines))
         (observed (map runtime-block-signature runtime-blocks-value))
         (expected (expected-runtime-signatures))
         (native-lines (receipt-lines native-proof-path))
         (python-lines (receipt-lines python-proof-path))
         (diagnostics '()))
    (def (reject! code observed-value)
      (set! diagnostics
            (cons (list (cons 'code code) (cons 'observed observed-value))
                  diagnostics)))
    (unless (and (= (length runtime-blocks-value) 140)
                 (andmap (lambda (signature) (member signature observed))
                         expected))
      (reject! 'incomplete-runtime-cartesian-matrix
               (length runtime-blocks-value)))
    (unless (and (line-present? runtime-lines
                                "lookup-complexity=O(log-n-plus-k)")
                 (line-present? runtime-lines "abi-v1-frozen=false"))
      (reject! 'invalid-runtime-performance-contract runtime-path))
    (unless (and (proof-profile-complete? native-lines)
                 (line-present? native-lines "threshold-status=baseline-only")
                 (line-present? native-lines "allocations-per-item=0")
                 (line-present? native-lines "crossings-per-item=3"))
      (reject! 'invalid-native-proof-baseline native-proof-path))
    (unless (and (proof-profile-complete? python-lines)
                 (line-present? python-lines "threshold-status=baseline-only")
                 (line-present? python-lines
                                "crossings-per-item-steady=3")
                 (line-present? python-lines
                                "caller-output-allocations-per-item=0"))
      (reject! 'invalid-python-proof-baseline python-proof-path))
    (object<-alist
     (list (cons 'kind 'poo-flow.performance-matrix-verification.v1)
           (cons 'accepted? (null? diagnostics))
           (cons 'runtime-block-count (length runtime-blocks-value))
           (cons 'batch-sizes +runtime-batches+)
           (cons 'payload-bytes +runtime-payloads+)
           (cons 'dispositions +runtime-dispositions+)
           (cons 'proof-profiles '(strict batched))
           (cons 'threshold-status 'baseline-only)
           (cons 'unsupported-dimensions
                 '((restore . no-runtime-benchmark-owner)
                   (absolute-latency-budget . insufficient-host-series)))
           (cons 'diagnostics (reverse diagnostics))))))
