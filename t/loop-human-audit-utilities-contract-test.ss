;;; -*- Gerbil -*-
;;; Contract: human audit loops expose utilities-backed type contracts.

(eval '(import "./src/loops/descriptor.ss"))
(eval '(import "./src/loops/strategy.ss"))
(eval '(import "./src/loops/governor.ss"))
(eval '(import "./src/loops/human-audit.ss"))

;; : (-> PooFlowHumanAuditExpr PooFlowHumanAuditValue)
(def (human-audit-eval expr)
  (eval expr))

;; : (-> Alist Symbol Object Object)
(def (alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> Alist [Symbol])
(def (contract-slot-names row)
  (map (lambda (slot-row)
         (alist-ref/default slot-row 'slot #f))
       (alist-ref/default row 'slots '())))

(let (audit-row
      (human-audit-eval '(loop-human-audit-type-contract->alist)))
  (unless (and (eq? (alist-ref/default audit-row 'object-kind #f)
                    'LoopHumanAudit)
               (member 'governor (contract-slot-names audit-row))
               (member 'state-facts (contract-slot-names audit-row))
               (member 'decisions (contract-slot-names audit-row))
               (member 'decision-owner (contract-slot-names audit-row)))
    (error "human audit contract should expose review loop slots")))

(unless
 (human-audit-eval
  '(let* ((pattern
           (make-loop-pattern-descriptor
            'repair
            "Repair one controlled target."
            '((level . l1)
              (priority . 1)
              (metadata . ((acting_on . "src/a"))))))
          (strategy
           (make-loop-strategy-plan 'maintenance (list pattern)))
          (governor
           (make-loop-governor 'repo-governor strategy)))
     (loop-human-audit-require-slots!
      'human-review
      governor
      #f
      '(((acting_on . "src/a")))
      '((repair . approved))
      '((mode . review-loop))
      #t
      'human
      #t
      'gerbil
      'human
      'marlin-agent-core
      '((fixture . human-audit-contract)))))
 (error "human audit slot checks should accept valid review values"))

(when
 (human-audit-eval
  '(with-catch
    (lambda (_failure) #f)
    (lambda ()
      (let* ((pattern
              (make-loop-pattern-descriptor
               'repair
               "Repair one controlled target."
               '((level . l1))))
             (strategy
              (make-loop-strategy-plan 'maintenance (list pattern)))
             (governor
              (make-loop-governor 'repo-governor strategy)))
        (loop-human-audit-require-slots!
         'human-review
         governor
         #f
         '()
         '((repair . unsupported))
         '((mode . review-loop))
         #t
         'human
         #t
         'gerbil
         'human
         'marlin-agent-core
         '()))
      #t)))
 (error "human audit decision contract should reject unsupported decisions"))
