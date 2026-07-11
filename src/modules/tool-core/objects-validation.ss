;;; -*- Gerbil -*-
;;; Boundary: pure catalog and policy validation.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/tool-core/objects-catalog
        :poo-flow/src/modules/tool-core/objects-policy-refs
        :poo-flow/src/modules/tool-core/objects-spec)

(export poo-flow-tool-action-mismatch-bundle
        poo-flow-tool-policy-catalog-validation-summary)

(def (poo-flow-tool-diagnostic code tool-ref)
  (list (cons 'kind 'poo-flow.tool-core.diagnostic)
        (cons 'schema 'poo-flow.modules.tool-core.diagnostic.v1)
        (cons 'code code) (cons 'tool-ref tool-ref)
        (cons 'severity 'error) (cons 'runtime-executed #f)))

(def (poo-flow-tool-unsupported-actions requested supported)
  (cond ((null? requested) '())
        ((or (member (car requested) supported) (member '* supported))
         (poo-flow-tool-unsupported-actions (cdr requested) supported))
        (else (cons (car requested)
                    (poo-flow-tool-unsupported-actions (cdr requested)
                                                       supported)))))

(def (poo-flow-tool-action-mismatch-row grant spec)
  (let* ((requested (poo-flow-session-tool-grant-actions grant))
         (supported (poo-flow-tool-spec-actions spec))
         (unsupported (poo-flow-tool-unsupported-actions requested supported)))
    (and (not (null? unsupported))
         (list (cons 'grant-id (poo-flow-session-tool-grant-id grant))
               (cons 'tool-ref (poo-flow-session-tool-grant-tool-ref grant))
               (cons 'requested-actions requested)
               (cons 'supported-actions supported)
               (cons 'unsupported-actions unsupported)))))

(def (poo-flow-tool-action-diagnostic row)
  (list (cons 'kind 'poo-flow.tool-core.diagnostic)
        (cons 'schema 'poo-flow.modules.tool-core.diagnostic.v1)
        (cons 'code 'tool-grant-action-not-supported)
        (cons 'grant-id (poo-flow-session-alist-ref row 'grant-id #f))
        (cons 'tool-ref (poo-flow-session-alist-ref row 'tool-ref #f))
        (cons 'requested-actions
              (poo-flow-session-alist-ref row 'requested-actions '()))
        (cons 'supported-actions
              (poo-flow-session-alist-ref row 'supported-actions '()))
        (cons 'unsupported-actions
              (poo-flow-session-alist-ref row 'unsupported-actions '()))
        (cons 'severity 'error) (cons 'runtime-executed #f)))

(def (poo-flow-tool-action-mismatch-fold catalog grants rows-rev diagnostics-rev)
  (cond ((null? grants) (cons rows-rev diagnostics-rev))
        (else
         (let* ((grant (car grants))
                (spec (poo-flow-tool-catalog-find
                       catalog (poo-flow-session-tool-grant-tool-ref grant)))
                (row (and spec (poo-flow-tool-action-mismatch-row grant spec))))
           (if row
             (poo-flow-tool-action-mismatch-fold catalog (cdr grants)
                                                  (cons row rows-rev)
                                                  (cons (poo-flow-tool-action-diagnostic row)
                                                        diagnostics-rev))
             (poo-flow-tool-action-mismatch-fold catalog (cdr grants)
                                                  rows-rev diagnostics-rev))))))

(def (poo-flow-tool-action-mismatch-bundle catalog agent-grants hook-grants)
  (let* ((agent (poo-flow-tool-action-mismatch-fold catalog agent-grants '() '()))
         (hook (poo-flow-tool-action-mismatch-fold catalog hook-grants
                                                     (car agent) (cdr agent))))
    (list (cons 'rows (reverse (car hook)))
          (cons 'diagnostics (reverse (cdr hook))))))

(def (poo-flow-tool-reverse-onto values tail)
  (if (null? values) tail
      (poo-flow-tool-reverse-onto (cdr values) (cons (car values) tail))))

(def (poo-flow-tool-validation-summary-finish resolved-rev unresolved-rev
                                                sandbox-rev unresolved-diagnostics-rev
                                                sandbox-diagnostics-rev)
  (list
   (cons 'resolved-tool-refs (reverse resolved-rev))
   (cons 'unresolved-tool-refs (reverse unresolved-rev))
   (cons 'sandbox-required-tool-refs (reverse sandbox-rev))
   (cons 'unresolved-diagnostics-rev unresolved-diagnostics-rev)
   (cons 'sandbox-diagnostics-rev sandbox-diagnostics-rev)
   (cons 'diagnostics
         (poo-flow-tool-reverse-onto
          unresolved-diagnostics-rev
          (poo-flow-tool-reverse-onto sandbox-diagnostics-rev '())))))

(def (poo-flow-tool-policy-catalog-validation-summary catalog tool-refs)
  (let loop ((remaining tool-refs) (resolved-rev '()) (unresolved-rev '())
             (sandbox-rev '()) (unresolved-diagnostics-rev '())
             (sandbox-diagnostics-rev '()))
    (cond
     ((null? remaining)
      (poo-flow-tool-validation-summary-finish
       resolved-rev unresolved-rev sandbox-rev unresolved-diagnostics-rev
       sandbox-diagnostics-rev))
     (else
      (let* ((tool-ref (car remaining))
             (spec (poo-flow-tool-catalog-find catalog tool-ref)))
        (if spec
          (let* ((sandbox-required? (poo-flow-tool-spec-sandbox-required? spec))
                 (sandbox-profile-ref
                  (poo-flow-tool-spec-sandbox-profile-ref spec)))
            (loop (cdr remaining) (cons tool-ref resolved-rev) unresolved-rev
                  (if sandbox-required? (cons tool-ref sandbox-rev) sandbox-rev)
                  unresolved-diagnostics-rev
                  (if (and sandbox-required? (not (symbol? sandbox-profile-ref)))
                    (cons (poo-flow-tool-diagnostic
                           'tool-spec-missing-sandbox-profile tool-ref)
                          sandbox-diagnostics-rev)
                    sandbox-diagnostics-rev)))
          (loop (cdr remaining) resolved-rev (cons tool-ref unresolved-rev)
                sandbox-rev
                (cons (poo-flow-tool-diagnostic 'tool-spec-not-in-catalog tool-ref)
                      unresolved-diagnostics-rev)
                sandbox-diagnostics-rev)))))))
