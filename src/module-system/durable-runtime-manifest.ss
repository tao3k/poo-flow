(import :gerbil/gambit
        :poo-flow/src/module-system/durable-policy-manifest
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend)

(export +poo-flow-durable-runtime-envelope-schema+
        poo-flow-durable-runtime-manifest-alist
        poo-flow-durable-runtime-manifest-string
        poo-flow-durable-runtime-manifest-bytes)

(def +poo-flow-durable-runtime-envelope-schema+
  'poo-flow.durable.runtime-envelope.v1)

(def (poo-flow-durable-runtime-manifest-alist policy store-contract backend)
  (let* ((policy-row
          (poo-flow-durable-policy-runtime-manifest-alist policy))
         (store-row
          (poo-flow-durable-runtime-store-contract-receipt->alist
           (poo-flow-durable-runtime-store-contract->receipt store-contract)))
         (backend-row
          (poo-flow-durable-runtime-store-backend-receipt->alist
           (poo-flow-durable-runtime-store-backend->receipt backend)))
         (operation-kinds
          (poo-flow-durable-runtime-manifest-ref backend-row 'operation-kinds '()))
         (backend-executable
          (poo-flow-durable-runtime-manifest-ref backend-row 'executable "")))
    `((schema . ,+poo-flow-durable-runtime-envelope-schema+)
      (owner . scheme)
      (policy-schema . ,(poo-flow-durable-runtime-manifest-ref policy-row 'schema #f))
      (policy-id . ,(poo-flow-durable-runtime-manifest-ref policy-row 'policy-id #f))
      (checkpoint-id-strategy
       . ,(poo-flow-durable-runtime-manifest-ref
           policy-row 'checkpoint-id-strategy #f))
      (checkpoint-store
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'checkpoint-store #f))
      (repair-mode . ,(poo-flow-durable-runtime-manifest-ref policy-row 'repair-mode #f))
      (action-classes
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'action-classes '()))
      (store-schema . ,(poo-flow-durable-runtime-manifest-ref store-row 'schema #f))
      (store-id . ,(poo-flow-durable-runtime-manifest-ref store-row 'store-id #f))
      (store-owner . ,(poo-flow-durable-runtime-manifest-ref store-row 'store-owner #f))
      (fact-log-ref . ,(poo-flow-durable-runtime-manifest-ref store-row 'fact-log-ref #f))
      (checkpoint-store-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'checkpoint-store-ref #f))
      (derived-index-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'derived-index-ref #f))
      (job-store-ref . ,(poo-flow-durable-runtime-manifest-ref store-row 'job-store-ref #f))
      (repair-journal-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'repair-journal-ref #f))
      (artifact-store-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'artifact-store-ref #f))
      (communication-ledger-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'communication-ledger-ref #f))
      (sandbox-ledger-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'sandbox-ledger-ref #f))
      (ledger-kinds
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'ledger-kinds '()))
      (capability-flags
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'capability-flags '()))
      (backend-schema . ,(poo-flow-durable-runtime-manifest-ref backend-row 'schema #f))
      (backend-id . ,(poo-flow-durable-runtime-manifest-ref backend-row 'backend-id #f))
      (backend-kind
       . ,(poo-flow-durable-runtime-manifest-ref backend-row 'backend-kind #f))
      (backend-executable . ,backend-executable)
      (backend-protocol
       . ,(poo-flow-durable-runtime-manifest-ref backend-row 'protocol #f))
      (operation-kinds . ,operation-kinds)
      (operation-count . ,(length operation-kinds))
      (negotiate-argv . ,(list backend-executable "durable-runtime-store" "negotiate"))
      (operations-argv . ,(list backend-executable "durable-runtime-store" "operations"))
      (runtime-owner
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'runtime-owner #f))
      (policy-valid . ,(poo-flow-durable-runtime-manifest-ref policy-row 'receipt-valid #f))
      (store-valid . ,(poo-flow-durable-runtime-manifest-ref store-row 'valid? #f))
      (backend-valid . ,(poo-flow-durable-runtime-manifest-ref backend-row 'valid? #f))
      (diagnostic-count
       . ,(+ (poo-flow-durable-runtime-manifest-ref policy-row 'receipt-diagnostic-count 0)
             (poo-flow-durable-runtime-manifest-ref store-row 'diagnostic-count 0)
             (poo-flow-durable-runtime-manifest-ref backend-row 'diagnostic-count 0)))
      (runtime-executed . #f))))

(def (poo-flow-durable-runtime-manifest-string policy store-contract backend)
  (poo-flow-durable-runtime-manifest-lines->string
   (poo-flow-durable-runtime-manifest-alist policy store-contract backend)))

(def (poo-flow-durable-runtime-manifest-bytes policy store-contract backend)
  (string->utf8
   (poo-flow-durable-runtime-manifest-string policy store-contract backend)))

(def (poo-flow-durable-runtime-manifest-ref row key default)
  (let ((cell (assq key row)))
    (if cell (cdr cell) default)))

(def (poo-flow-durable-runtime-manifest-lines->string rows)
  (let loop ((rest rows) (out ""))
    (if (null? rest)
      out
      (let ((row (car rest)))
        (loop (cdr rest)
              (string-append out
                             (symbol->string (car row))
                             "="
                             (poo-flow-durable-runtime-manifest-value->string (cdr row))
                             "\n"))))))

(def (poo-flow-durable-runtime-manifest-value->string value)
  (cond
   ((not value) "")
   ((eq? value #t) "true")
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   ((number? value) (number->string value))
   ((list? value) (poo-flow-durable-runtime-manifest-list->string value))
   (else (call-with-output-string
          (lambda (port) (write value port))))))

(def (poo-flow-durable-runtime-manifest-list->string value)
  (let loop ((rest value) (out #f))
    (if (null? rest)
      (or out "")
      (let ((item (poo-flow-durable-runtime-manifest-value->string (car rest))))
        (loop (cdr rest)
              (if out
                (string-append out "," item)
                item))))))
