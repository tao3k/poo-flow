;;; -*- Gerbil -*-
;;; Boundary: POO roles describe conceptual control-plane ownership.
;;; Invariant: runtime data stays in typed structs and adapter receipts.

(import (only-in :clan/poo/object .o .@ .ref .mix .slot? object? $constant-slot-spec))

(export control-plane-role
        flow-role
        branch-role
        task-role
        strategy-role
        execution-policy-role
        run-config-role
        runner-role
        runtime-adapter-role
        receipt-role
        replay-role
        role-name
        role-kind
        role-responsibility
        role-runtime-owner
        role-slot/default
        role-compose
        role-object?
        role-constant-slots)

;;; Boundary: compose is the only higher-order role operation in this module.
;;; Invariant: derived roles share one mixing path with leftmost POO precedence.
;; : (forall (a) (-> [a] [a] [a]))
(import (only-in :clan/poo/object
                 object<-fun .all-slots object-slots object-supers
                 $constant-slot-spec?))
(export role-instance-overlay-compatible? role-instance-overlay)

(def (role-values/tail values tail)
  (append values tail))

;; : (-> Unit Role)
(def control-plane-role
  (.mix
   slots:
   (list
    (cons 'name ($constant-slot-spec 'control-plane))
    (cons 'kind ($constant-slot-spec 'system))
    (cons 'responsibility ($constant-slot-spec 'conceptual-model))
    (cons 'runtime-owner ($constant-slot-spec 'gerbil))
    (cons 'control-plane-capability
          ($constant-slot-spec 'conceptual-model))
    (cons 'compose
          ($constant-slot-spec
           (lambda roles
             (apply .mix
                    (role-values/tail roles (list control-plane-role)))))))))

;; : (-> Unit Role)
(def flow-role
  (.o (:: @ control-plane-role)
      (name 'flow)
      (kind 'declaration)
      (responsibility 'workflow-composition)
      (flow-capability 'workflow-composition)))

;; : (-> Unit Role)
(def branch-role
  (.o (:: @ control-plane-role)
      (name 'branch)
      (kind 'composition)
      (responsibility 'dag-fanout-join)
      (branch-capability 'dag-fanout-join)))

;; : (-> Unit Role)
(def task-role
  (.o (:: @ control-plane-role)
      (name 'task)
      (kind 'declaration)
      (responsibility 'work-intent)
      (task-capability 'work-intent)))

;; : (-> Unit Role)
(def strategy-role
  (.o (:: @ control-plane-role)
      (name 'strategy)
      (kind 'policy)
      (responsibility 'execution-selection)))

;; : (-> Unit Role)
(def execution-policy-role
  (.o (:: @ control-plane-role)
      (name 'execution-policy)
      (kind 'policy-envelope)
      (responsibility 'runtime-policy-handoff)
      (policy-capability 'runtime-policy-handoff)))

;; : (-> Unit Role)
(def run-config-role
  (.o (:: @ control-plane-role)
      (name 'run-config)
      (kind 'configuration)
      (responsibility 'configured-runner-assembly)))

;; : (-> Unit Role)
(def runner-role
  (.o (:: @ control-plane-role)
      (name 'runner)
      (kind 'interpreter)
      (responsibility 'plan-interpretation)))

;; : (-> Unit Role)
(def runtime-adapter-role
  (.o (:: @ control-plane-role)
      (name 'runtime-adapter)
      (kind 'boundary)
      (responsibility 'heavy-runtime-delegation)
      (runtime-capability 'heavy-runtime-delegation)
      (runtime-owner 'rust-or-external-runtime)))

;; : (-> Unit Role)
(def receipt-role
  (.o (:: @ control-plane-role)
      (name 'receipt)
      (kind 'evidence)
      (responsibility 'execution-explanation)))

;; : (-> Unit Role)
(def replay-role
  (.o (:: @ control-plane-role)
      (name 'replay)
      (kind 'policy)
      (responsibility 'audit-validation)))

;; : (-> Role Symbol)
(def (role-name role)
  (.@ role name))

;; : (-> Role Symbol)
(def (role-kind role)
  (.@ role kind))

;; : (-> Role Symbol)
(def (role-responsibility role)
  (.@ role responsibility))

;; : (-> Role Symbol)
(def (role-runtime-owner role)
  (.@ role runtime-owner))

;;; Slot probing is the safe boundary for C3-composed role objects: descriptor
;;; callers can inspect inherited capabilities without assuming every role
;;; contributes the same slot set.
;; : (-> Role Symbol Value Value)
(def (role-slot/default role slot default)
  (if (and (role-object? role)
           (.slot? role slot))
    (.ref role slot)
    default))

;; : (-> [Role] Role)
(def (role-compose . roles)
  (apply (.@ control-plane-role compose) roles))

;;; Instance-overlay fast lane.
;;; Invariant: delegation is semantics-preserving only for constant slot specs;
;;; self/computed/super specs remain on role-compose/.mix.
(def (role-constant-slot-specs? slots)
  (or (null? slots)
      (and ($constant-slot-spec? (cdar slots))
           (role-constant-slot-specs? (cdr slots)))))

(def (role-instance-overlay-compatible?/seen role path)
  (and (role-object? role)
       (not (memq role path))
       (role-constant-slot-specs? (object-slots role))
       (role-instance-overlay-compatible-list?
        (object-supers role) (cons role path))))

(def (role-instance-overlay-compatible-list? roles path)
  (or (null? roles)
      (and (role-instance-overlay-compatible?/seen (car roles) path)
           (role-instance-overlay-compatible-list? (cdr roles) path))))

(def (role-instance-overlay-compatible? role)
  (role-instance-overlay-compatible?/seen role '()))

(def (role-instance-overlay-owner-index/one keys source roles owners)
  (if (null? keys)
      (role-instance-overlay-owner-index roles owners)
      (let (key (car keys))
        (if (hash-key? owners key)
            (role-instance-overlay-owner-index/one
             (cdr keys) source roles owners)
            (begin
              (hash-put! owners key source)
              (role-instance-overlay-owner-index/one
               (cdr keys) source roles owners))))))

(def (role-instance-overlay-owner-index roles owners)
  (if (or (null? roles) (null? (cdr roles)))
      owners
      (let (source (car roles))
        (role-instance-overlay-owner-index/one
         (.all-slots source) source (cdr roles) owners))))

(def (role-instance-overlay-last roles)
  (if (null? (cdr roles))
      (car roles)
      (role-instance-overlay-last (cdr roles))))

(def (role-instance-overlay-keys roles)
  (apply append (map .all-slots roles)))

(def (role-instance-overlay-resolve owners fallback slot)
  (.ref (if (hash-key? owners slot)
            (hash-ref owners slot)
            fallback)
        slot))

(def (role-instance-overlay . roles)
  (unless (and (pair? roles)
               (role-instance-overlay-compatible-list? roles '()))
    (error "role instance overlay requires constant-slot POO roles" roles))
  (let* ((owners
          (role-instance-overlay-owner-index roles (make-hash-table)))
         (fallback (role-instance-overlay-last roles)))
    (object<-fun
     (lambda (slot)
       (role-instance-overlay-resolve owners fallback slot))
     keys: (role-instance-overlay-keys roles))))

;; : (-> Role Boolean)
(def (role-object? role)
  (object? role))

;;; Boundary: descriptor modules hand this helper plain slot/value pairs.
;;; Data flow: each pair becomes the constant slot spec required by =.mix=.
;;; Invariant: callers use slot precedence so descriptors can override inherited
;;; role slots without falling back to lower-precedence defaults.
;; : (-> Alist [SlotSpec] [SlotSpec])
(def (role-constant-slots/rev alist slots-rev)
  (if (null? alist)
    slots-rev
    (role-constant-slots/rev
     (cdr alist)
     (cons (cons (caar alist) ($constant-slot-spec (cdar alist)))
           slots-rev))))

;; : (-> Alist [SlotSpec])
(def (role-constant-slots alist)
  (reverse (role-constant-slots/rev alist '())))
