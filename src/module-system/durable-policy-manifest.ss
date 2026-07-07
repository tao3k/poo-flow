(import :gerbil/gambit
        :poo-flow/src/module-system/durable-policy)

(export +poo-flow-durable-runtime-policy-manifest-schema+
        poo-flow-durable-policy-runtime-manifest-alist
        poo-flow-durable-policy-runtime-manifest-string
        poo-flow-durable-policy-runtime-manifest-bytes)

(def +poo-flow-durable-runtime-policy-manifest-schema+
  'poo-flow.durable.runtime-policy-manifest.v1)

(def (poo-flow-durable-policy-runtime-manifest-alist policy)
  (let* ((receipt (poo-flow-durable-policy->receipt policy))
         (diagnostics (poo-flow-durable-policy-receipt-diagnostics receipt)))
    `((schema . ,+poo-flow-durable-runtime-policy-manifest-schema+)
      (owner . scheme)
      (policy-id . ,(poo-flow-durable-policy-receipt-policy-id receipt))
      (checkpoint-id-strategy . runtime-generated)
      (require-plan-digest-match . #t)
      (history-retention-limit . #f)
      (checkpoint-store . ,(poo-flow-durable-policy-receipt-checkpoint-store receipt))
      (repair-mode . ,(poo-flow-durable-policy-receipt-repair-mode receipt))
      (action-classes . ,(poo-flow-durable-policy-receipt-action-classes receipt))
      (runtime-owner . ,(poo-flow-durable-policy-receipt-runtime-owner receipt))
      (receipt-schema . ,+poo-flow-durable-policy-receipt-schema+)
      (receipt-kind . ,+poo-flow-durable-policy-kind+)
      (receipt-valid . ,(poo-flow-durable-policy-receipt-valid? receipt))
      (receipt-diagnostic-count . ,(length diagnostics)))))

(def (poo-flow-durable-policy-runtime-manifest-string policy)
  (poo-flow-durable-manifest-lines->string
   (poo-flow-durable-policy-runtime-manifest-alist policy)))

(def (poo-flow-durable-policy-runtime-manifest-bytes policy)
  (string->utf8 (poo-flow-durable-policy-runtime-manifest-string policy)))

(def (poo-flow-durable-manifest-lines->string rows)
  (let loop ((rest rows) (out ""))
    (if (null? rest)
      out
      (let ((row (car rest)))
        (loop (cdr rest)
              (string-append out
                             (symbol->string (car row))
                             "="
                             (poo-flow-durable-manifest-value->string (cdr row))
                             "\n"))))))

(def (poo-flow-durable-manifest-value->string value)
  (cond
   ((not value) "")
   ((eq? value #t) "true")
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   ((number? value) (number->string value))
   ((list? value) (poo-flow-durable-manifest-list->string value))
   (else (call-with-output-string
          (lambda (port) (write value port))))))

(def (poo-flow-durable-manifest-list->string value)
  (let loop ((rest value) (out #f))
    (if (null? rest)
      (or out "")
      (let ((item (poo-flow-durable-manifest-value->string (car rest))))
        (loop (cdr rest)
              (if out
                (string-append out "," item)
                item))))))
