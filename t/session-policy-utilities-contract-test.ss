;;; -*- Gerbil -*-
;;; Contract: session policy exposes utilities-backed type contracts.

(eval '(import "./src/modules/session/policy.ss"))
(eval '(import "./src/type-facts/objects.ss"))

;; : (-> PooFlowSessionPolicyExpr PooFlowSessionPolicyValue)
(def (session-policy-eval expr)
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

;; : (-> [Alist] Symbol Alist)
(def (fact-row-by-source-slot rows source-slot)
  (cond
   ((null? rows) '())
   ((eq? (alist-ref/default (car rows) 'source-slot #f)
         source-slot)
    (car rows))
   (else
    (fact-row-by-source-slot (cdr rows) source-slot))))

(let (policy-row
      (session-policy-eval
       '(poo-flow-session-policy-type-contract->alist)))
  (unless (and (eq? (alist-ref/default policy-row 'object-kind #f)
                    'PooSessionPolicy)
               (equal? (contract-slot-names policy-row)
                       '(kind schema policy-kind policy-name scope-ref
                         default-action policy-slots metadata runtime-owner
                         runtime-executed)))
    (error "session policy contract should expose policy slots")))

(let (grant-row
      (session-policy-eval
       '(poo-flow-session-tool-grant-type-contract->alist)))
  (unless (and (eq? (alist-ref/default grant-row 'object-kind #f)
                    'PooSessionToolGrant)
               (equal? (contract-slot-names grant-row)
                       '(kind schema grant-id tool-ref actions resource-refs
                         trigger-refs metadata runtime-executed)))
    (error "session tool grant contract should expose grant slots")))

(let (policy-fact-rows
      (session-policy-eval
       '(map poo-flow-type-fact-contract->alist
             (poo-flow-object-type-contract->type-facts
              +poo-flow-session-policy-type-contract+))))
  (let (default-action-row
        (fact-row-by-source-slot policy-fact-rows 'default-action))
    (unless (and (= (length policy-fact-rows) 10)
                 (eq? (alist-ref/default default-action-row 'owner #f)
                      'PooSessionPolicy)
                 (eq? (alist-ref/default default-action-row 'value-kind #f)
                      'Symbol)
                 (eq? (alist-ref/default default-action-row 'polarity #f)
                      'positive)
                 (eq? (alist-ref/default
                       (alist-ref/default default-action-row 'metadata '())
                       'predicate
                       #f)
                      'symbol?))
      (error "session policy contract should project type facts"))))

(let (grant-lean-rows
      (session-policy-eval
       '(map poo-flow-lean-fact-contract->alist
             (poo-flow-object-type-contract->lean-fact-contracts
              +poo-flow-session-tool-grant-type-contract+))))
  (let (actions-row
        (fact-row-by-source-slot grant-lean-rows 'actions))
    (unless (and (= (length grant-lean-rows) 9)
                 (eq? (alist-ref/default actions-row 'kind #f)
                      'slot-contract)
                 (eq? (alist-ref/default actions-row 'lean-owner #f)
                      'PooSessionToolGrant)
                 (eq? (alist-ref/default actions-row 'lean-name #f)
                      'actions)
                 (eq? (alist-ref/default actions-row 'polarity #f)
                      'positive))
      (error "session tool grant contract should project Lean fact rows"))))

(unless
 (session-policy-eval
  '(poo-flow-session-policy-require-slots!
    'poo-flow.session.policy
    'poo-flow.modules.session.policy.tool-permission.v1
    'agent-tool-permission
    'policy/test-tools
    'session/test
    'deny
    '((tool-grants . ())
      (denied-tool-refs . (write-workspace-file)))
    '((fixture . session-policy-contract))
    "marlin-agent-core"
    #f))
 (error "session policy slot checks should accept valid values"))

(unless
 (session-policy-eval
  '(poo-flow-session-tool-grant-require-slots!
    'poo-flow.session.tool-grant
    'poo-flow.modules.session.tool-grant.v1
    'grant/read
    'read-workspace-file
    '(read)
    '(project-workspace "reports/")
    '(agent-turn)
    '((fixture . session-policy-contract))
    #f))
 (error "session tool grant slot checks should accept valid values"))

(unless
 (session-policy-eval
  '(let* ((grant
           (poo-flow-session-tool-grant
            'grant/read
            'read-workspace-file
            '(read)
            '(project-workspace)
            '(agent-turn)))
          (policy
           (poo-flow-session-tool-permission-policy
            'policy/test-tools
            'session/test
            (list grant)
            '(write-workspace-file)
            'deny))
          (row (poo-flow-session-policy->alist policy)))
     (and (poo-flow-session-policy? policy)
          (= (alist-ref/default row 'tool-grant-count 0) 1)
          (not (alist-ref/default row 'runtime-executed #t)))))
 (error "session policy constructor should use valid contract-gated values"))

(when
 (session-policy-eval
  '(with-catch
    (lambda (_failure) #f)
    (lambda ()
      (poo-flow-session-tool-grant-require-slots!
       'poo-flow.session.tool-grant
       'poo-flow.modules.session.tool-grant.v1
       'grant/read
       'read-workspace-file
       '(read)
       '(project-workspace)
       '(agent-turn)
       '()
       'not-a-boolean)
      #t)))
 (error "session tool grant runtime-executed contract should reject invalid values"))
