;;; -*- Gerbil -*-
;;; Contract: loop governor exposes utilities-backed type contracts.

(eval '(import "./src/loops/descriptor.ss"))
(eval '(import "./src/loops/strategy.ss"))
(eval '(import "./src/loops/governor.ss"))

;; : (-> PooFlowLoopGovernorExpr PooFlowLoopGovernorValue)
(def (loop-governor-eval expr)
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

(let (node-row
      (loop-governor-eval '(loop-governor-node-type-contract->alist)))
  (unless (and (eq? (alist-ref/default node-row 'object-kind #f)
                    'LoopGovernorNode)
               (equal? (contract-slot-names node-row)
                       '(name governance-node-kind governance-responsibility
                         human-intervention control-owner execution-owner
                         metadata)))
    (error "governor node contract should expose governance node slots")))

(let (governor-row
      (loop-governor-eval '(loop-governor-type-contract->alist)))
  (unless (and (eq? (alist-ref/default governor-row 'object-kind #f)
                    'LoopGovernor)
               (member 'strategy (contract-slot-names governor-row))
               (member 'agent-judge-nodes
                       (contract-slot-names governor-row))
               (member 'shared-denylist
                       (contract-slot-names governor-row)))
    (error "governor contract should expose governor policy slots")))

(unless
 (loop-governor-eval
  '(loop-governor-require-node-slots!
    'repo-auditor
    'agent
    'audit
    #f
    'gerbil
    'marlin-agent-core
    '((fixture . loop-governor-contract))))
 (error "governor node slot checks should accept valid values"))

(unless
 (loop-governor-eval
  '(let* ((pattern
           (make-loop-pattern-descriptor
            'repair
            "Repair one controlled target."
            '((level . l1)
              (priority . 1)
              (metadata . ((acting_on . "src/a"))))))
          (strategy
           (make-loop-strategy-plan 'maintenance (list pattern))))
     (loop-governor-require-slots!
      'repo-governor
      strategy
      '()
      '("src/a")
      '((field . acting_on))
      '((mode . acting_on))
      '((max-actionable . 1))
      '((mode . multi-agent-governance))
      (list (make-loop-governor-agent-node 'repo-auditor 'audit))
      '((target . human-inbox))
      '((target . marlin-agent-core) (transport . scheme-abi))
      'gerbil
      'marlin-agent-core
      '((fixture . loop-governor-contract)))))
 (error "governor slot checks should accept valid object values"))

(when
 (loop-governor-eval
  '(with-catch
    (lambda (_failure) #f)
    (lambda ()
      (let* ((pattern
              (make-loop-pattern-descriptor
               'repair
               "Repair one controlled target."
               '((level . l1))))
             (strategy
              (make-loop-strategy-plan 'maintenance (list pattern))))
        (loop-governor-require-slots!
         'repo-governor
         strategy
         '()
         '(42)
         '((field . acting_on))
         '((mode . acting_on))
         '((max-actionable . 1))
         '((mode . multi-agent-governance))
         (list (make-loop-governor-agent-node 'repo-auditor 'audit))
         '((target . human-inbox))
         '((target . marlin-agent-core) (transport . scheme-abi))
         'gerbil
         'marlin-agent-core
         '()))
      #t)))
 (error "governor shared-denylist contract should reject unsupported keys"))
