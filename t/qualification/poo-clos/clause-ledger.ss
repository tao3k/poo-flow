;;; -*- Gerbil -*-
;;; Executable ANSI-CLOS and separately scoped MOP-EXTENDED clause inventory.

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/srfi/1 filter))

(export poo-clos-clause-ledger poo-clos-operator-ledger
        poo-clos-required-ansi-rows poo-clos-required-ansi-operators
        poo-clos-open-required-ansi-rows poo-clos-ledger-row-valid?
        poo-clos-operator-row-valid? poo-clos-evidence-id-resolves?)

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol POOObject)
(def (clause status-name row-id profile-name owner-name positive-name negative-name)
  (.o id: row-id
      profile: profile-name
      status: status-name
      owner: owner-name
      positive-test: positive-name
      negative-test: negative-name))

(def (closed-clause row-id profile owner positive negative)
  (clause 'closed row-id profile owner positive negative))

(def poo-clos-clause-ledger
  (list
   ;; Class definition, inheritance, slots, and construction.
   (closed-clause 'C43-class-metaobjects 'ansi-clos 'classes
           'native-class-metaobjects 'invalid-class)
   (closed-clause 'C432-class-definition 'ansi-clos 'syntax
           'defclass-lowering 'duplicate-class-declarations)
   (closed-clause 'C432-slot-options 'ansi-clos 'classes
           'slot-option-projection 'invalid-slot-options)
   (closed-clause 'C433-make-instance 'ansi-clos 'lifecycle
           'make-instance-initialization 'invalid-initargs)
   (closed-clause 'C434-inheritance 'ansi-clos 'classes
           'diamond-inheritance 'duplicate-direct-superclass)
   (closed-clause 'C435-class-precedence 'ansi-clos 'classes
           'native-c3-order 'inconsistent-c3)
   (closed-clause 'C436-class-redefinition 'ansi-clos 'evolution
           'successor-generation 'obsolete-generation-redefinition)
   (closed-clause 'C436-dependent-propagation 'ansi-clos 'evolution
           'dependent-generation-cascade 'stale-superclass-generation)
   (closed-clause 'C436-lazy-instance-update 'ansi-clos 'lifecycle
           'lazy-instance-convergence 'discarded-slot-property-list)
   (closed-clause 'C436-shared-slot-transition 'ansi-clos 'evolution
           'shared-slot-cell-preservation 'allocation-transition)
   (closed-clause 'C436-make-instances-obsolete 'ansi-clos 'evolution
           'explicit-obsolescence 'obsolete-generation-redefinition)
   (closed-clause 'C437-class-specialized-types 'ansi-clos 'dispatch
           'class-specializer-inheritance 'invalid-specializer)

   ;; Creation, reinitialization, class change, and slot protocols.
   (closed-clause 'C71-allocation-initialization 'ansi-clos 'lifecycle
           'allocate-initialize-shared 'malformed-initialization-arguments)
   (closed-clause 'C71-default-initargs 'ansi-clos 'lifecycle
           'leftmost-default-initargs 'unknown-initarg)
   (closed-clause 'C72-change-class 'ansi-clos 'lifecycle
           'identity-preserving-change-class 'invalid-target-class)
   (closed-clause 'C72-update-different-class 'ansi-clos 'lifecycle
           'previous-current-hook-views 'invalid-change-initargs)
   (closed-clause 'C73-reinitialize-instance 'ansi-clos 'lifecycle
           'reinitialize-supplied-slots 'reinitialize-does-not-run-initforms)
   (closed-clause 'C75-slot-value 'ansi-clos 'lifecycle
           'slot-read-write 'slot-missing)
   (closed-clause 'C75-slot-boundp-makunbound 'ansi-clos 'lifecycle
           'bound-and-makunbound 'slot-unbound)
   (closed-clause 'C752-generated-accessors 'ansi-clos 'syntax
           'reader-writer-method-dispatch 'missing-accessor-slot)
   (closed-clause 'C752-with-slots 'ansi-clos 'syntax
           'live-with-slots-read 'invalid-slot-name)
   (closed-clause 'C752-with-accessors 'ansi-clos 'syntax
           'live-with-accessors-dispatch 'missing-accessor-method)
   (closed-clause 'C753-slot-inheritance 'ansi-clos 'classes
           'effective-slot-option-merge 'duplicate-direct-slot)
   (closed-clause 'C753-class-allocation 'ansi-clos 'classes
           'shared-and-shadowed-slots 'invalid-slot-allocation)

   ;; Generic functions, methods, selection, and combination.
   (closed-clause 'C761-generic-function 'ansi-clos 'objects
           'generic-function-metaobject 'invalid-generic-function)
   (closed-clause 'C762-method-metaobject 'ansi-clos 'objects
           'method-metaobject 'invalid-method)
   (closed-clause 'C763-specializer-qualifier-agreement 'ansi-clos 'objects
           'method-replacement-agreement 'invalid-method-qualifier)
   (closed-clause 'C764-lambda-list-congruence 'ansi-clos 'objects
           'congruent-lambda-lists 'incongruent-method-lambda-list)
   (closed-clause 'C765-applicable-keyword-union 'ansi-clos 'dispatch
           'applicable-method-keyword-union 'invalid-keyword-argument)
   (closed-clause 'C766-no-applicable-first 'ansi-clos 'dispatch
           'no-applicable-before-keywords 'no-applicable-method)
   (closed-clause 'C766-applicable-methods 'ansi-clos 'dispatch
           'multiple-dispatch-ranking 'changed-applicable-methods)
   (closed-clause 'C766-argument-precedence-order 'ansi-clos 'dispatch
           'argument-precedence-order 'invalid-argument-precedence-order)
   (closed-clause 'C766-standard-combination 'ansi-clos 'dispatch
           'standard-method-combination 'no-primary-method)
   (closed-clause 'C766-next-method 'ansi-clos 'dispatch
           'call-next-method 'no-next-method)
   (closed-clause 'C7663-declarative-combination 'ansi-clos 'method-combination
           'short-and-long-combinations 'required-method-group-empty)
   (closed-clause 'C7664-built-in-combinations 'ansi-clos 'method-combination
           'all-nine-built-ins 'unsupported-combination-operator)
   (closed-clause 'C767-method-inheritance 'ansi-clos 'dispatch
           'superclass-method-applicability 'no-applicable-method)
   (closed-clause 'D-ensure-generic-function 'ansi-clos 'generic-evolution
           'ensure-generic-binding 'generic-binding-identity-mismatch)
   (closed-clause 'D-generic-reinitialization 'ansi-clos 'generic-evolution
           'atomic-generic-reconfiguration 'method-required-argument-mismatch)

   ;; This row is evidence but cannot satisfy or dilute an ANSI requirement.
   (closed-clause 'MOP-portable-read-only-profile 'mop-extended 'mop
           'sealed-capability-profile 'unadmitted-operation)))

;; Exact CLHS 7.7 dictionary surface.  A closed operator must point at a
;; source-owned executable suite; an open operator must name its blocking gap.
(def poo-clos-evidence-ids
  '(dispatch lifecycle syntax method-combination evolution generic-evolution
    load-form))

(def (poo-clos-evidence-id-resolves? id)
  (and id (if (memq id poo-clos-evidence-ids) #t #f)))

(def (operator name status-name evidence-name gap-name)
  (.o id: name profile: 'ansi-clos status: status-name
      evidence-id: evidence-name gap-id: gap-name))
(def (covered name evidence) (operator name 'closed evidence #f))
(def (missing name gap) (operator name 'open #f gap))

(def poo-clos-operator-ledger
  (list
   (covered 'function-keywords 'dispatch)
   (covered 'ensure-generic-function 'generic-evolution)
   (covered 'allocate-instance 'lifecycle)
   (covered 'reinitialize-instance 'lifecycle)
   (covered 'shared-initialize 'lifecycle)
   (covered 'update-instance-for-different-class 'evolution)
   (covered 'update-instance-for-redefined-class 'evolution)
   (covered 'change-class 'evolution)
   (covered 'slot-boundp 'lifecycle)
   (covered 'slot-exists-p 'lifecycle)
   (covered 'slot-makunbound 'lifecycle)
   (covered 'slot-missing 'lifecycle)
   (covered 'slot-unbound 'lifecycle)
   (covered 'slot-value 'lifecycle)
   (covered 'method-qualifiers 'dispatch)
   (covered 'no-applicable-method 'dispatch)
   (covered 'no-next-method 'dispatch)
   (covered 'remove-method 'dispatch)
   (covered 'make-instance 'lifecycle)
   (covered 'make-instances-obsolete 'evolution)
   (covered 'make-load-form 'load-form)
   (covered 'make-load-form-saving-slots 'load-form)
   (covered 'with-accessors 'syntax)
   (covered 'with-slots 'syntax)
   (covered 'defclass 'syntax)
   (covered 'defgeneric 'syntax)
   (covered 'defmethod 'syntax)
   (covered 'find-class 'lifecycle)
   (covered 'next-method-p 'dispatch)
   (covered 'call-method/make-method 'method-combination)
   (covered 'call-next-method 'dispatch)
   (covered 'compute-applicable-methods 'dispatch)
   (covered 'define-method-combination 'method-combination)
   (covered 'find-method 'dispatch)
   (covered 'add-method 'dispatch)
   (covered 'initialize-instance 'lifecycle)
   (covered 'class-name 'evolution)
   (covered '(setf class-name) 'lifecycle)
   (covered 'class-of 'lifecycle)
   (covered 'unbound-slot 'lifecycle)
   (covered 'unbound-slot-instance 'lifecycle)))

(def (poo-clos-required-ansi-operators) poo-clos-operator-ledger)

;; : (-> [POOObject])
(def (poo-clos-required-ansi-rows)
  (filter (lambda (row) (eq? (.ref row 'profile) 'ansi-clos))
          poo-clos-clause-ledger))

;; : (-> [POOObject])
(def (poo-clos-open-required-ansi-rows)
  (filter (lambda (row) (not (eq? (.ref row 'status) 'closed)))
          (append (poo-clos-required-ansi-rows)
                  (poo-clos-required-ansi-operators))))

;; : (-> POOObject Boolean)
(def (poo-clos-ledger-row-valid? row)
  (and (memq (.ref row 'status) '(closed open))
       (memq (.ref row 'profile) '(ansi-clos mop-extended))
       (symbol? (.ref row 'id))
       (symbol? (.ref row 'owner))
       (symbol? (.ref row 'positive-test))
       (symbol? (.ref row 'negative-test))))

(def (poo-clos-operator-row-valid? row)
  (let ((status (.ref row 'status))
        (evidence (.ref row 'evidence-id))
        (gap (.ref row 'gap-id)))
    (and (equal? (.ref row 'profile) 'ansi-clos)
         (or (symbol? (.ref row 'id)) (pair? (.ref row 'id)))
         (case status
           ((closed) (and (poo-clos-evidence-id-resolves? evidence) (not gap)))
           ((open) (and (not evidence) (symbol? gap)))
           (else #f)))))
