;;; -*- Gerbil -*-
;;; Boundary: pure bounded inspection of existing Contract evidence.
;;; Never re-evaluates the observed candidate, reads a clock, or prints a value.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop validate raise-type-error)
        (only-in "../module-system/types.ss" PooFlowValidationEvidence)
        "types.ss")
(export poo-flow-observation-admission-facts
        poo-flow-observation-admission-explanation
        poo-flow-observation-admission-summary
        poo-flow-observation-summary-sexp
        poo-flow-debug-call-policy
        poo-flow-debug-call-receipt
        poo-flow-debug-call-receipt-sexp
        poo-flow-debug-memory-policy
        poo-flow-debug-memory-sample
        poo-flow-debug-memory-receipt
        poo-flow-debug-memory-receipt-sexp)

(def (poo-flow-observation-validate-receipt receipt)
  (validate PooFlowValidationEvidence receipt)
  (unless (eq? (.ref receipt 'contract-identity)
               (.ref (.ref receipt 'classification) 'type-identity))
    (raise-type-error PooFlowValidationEvidence receipt))
  receipt)

(def (poo-flow-observation-failure-code receipt)
  (let* ((classification (.ref receipt 'classification))
         (classified? (.ref classification 'accepted?))
         (diagnostics (if classified? (.ref receipt 'obligation-evidence)
                         (.ref classification 'diagnostics)))
         (first (and (pair? diagnostics) (car diagnostics))))
    (cond
     ((symbol? first) first)
     ((and (object? first) (.slot? first 'reason) (symbol? (.ref first 'reason)))
      (.ref first 'reason))
     ((and (object? first) (.slot? first 'code) (symbol? (.ref first 'code)))
      (.ref first 'code))
     ((and (object? first) (.slot? first 'kind) (symbol? (.ref first 'kind)))
      (.ref first 'kind))
     (classified? 'obligation-rejected)
     (else 'classification-rejected))))

(def (poo-flow-observation-failure receipt path-value)
  (let ((contract-value (.ref receipt 'contract-identity))
        (code-value (poo-flow-observation-failure-code receipt)))
    (.o (:: @ (.ref PooFlowObservationFailureContract 'proto))
        path: path-value contract: contract-value code: code-value)))

;;; The returned values are failures, completeness, and visited receipt count.
;;; A repeated receipt is an incomplete inspection, not a Module cycle claim.
(def (poo-flow-observation-inspect receipt path budget ancestors)
  (cond
   ((or (zero? budget) (memq receipt ancestors)) (values '() #f 0))
   (else
    (poo-flow-observation-validate-receipt receipt)
    (cond
     ((.ref receipt 'accepted?) (values '() #t 1))
     ((not (.ref (.ref receipt 'classification) 'accepted?))
      (values (list (poo-flow-observation-failure receipt path)) #t 1))
     ((and (.slot? receipt 'responsibility-evidence)
           (pair? (.ref receipt 'responsibility-evidence)))
      (let (children (.ref receipt 'responsibility-evidence))
        (unless (list? children) (error "invalid observation responsibility evidence"))
        (let-values (((failures complete? inspected)
                      (poo-flow-observation-inspect-children
                       children path (1- budget) (cons receipt ancestors))))
          ;; Object-level obligations can fail after every field was accepted.
          (values (if (and complete? (null? failures))
                    (list (poo-flow-observation-failure receipt path)) failures)
                  complete? (1+ inspected)))))
     (else (values (list (poo-flow-observation-failure receipt path)) #t 1))))))

(def (poo-flow-observation-inspect-children children path budget ancestors)
  (cond
   ((null? children) (values '() #t 0))
   ((zero? budget) (values '() #f 0))
   (else
    (let (child (car children))
      (unless (and (object? child) (.slot? child 'responsibility)
                   (symbol? (.ref child 'responsibility)))
        (error "invalid observation responsibility identity"))
      (let-values (((failures complete? inspected)
                    (poo-flow-observation-inspect
                     child (append path (list (.ref child 'responsibility))) budget ancestors)))
        (if (not complete?)
          (values failures #f inspected)
          (let-values (((tail-failures tail-complete? tail-inspected)
                        (poo-flow-observation-inspect-children
                         (cdr children) path (- budget inspected) ancestors)))
            (values (append failures tail-failures) tail-complete?
                    (+ inspected tail-inspected)))))))))

(def (poo-flow-observation-admission-facts receipt context)
  (validate PooFlowObservationContextContract context)
  (poo-flow-observation-validate-receipt receipt)
  (let-values (((failure-values complete-value inspected-value)
                (poo-flow-observation-inspect receipt '() (.ref context 'detail-budget) '())))
    (let ((contract-value (.ref receipt 'contract-identity))
          (accepted-value (.ref receipt 'accepted?))
          (classified-value (.ref (.ref receipt 'classification) 'accepted?))
          (obligation-count-value (length (.ref receipt 'obligation-evidence))))
      (validate PooFlowAdmissionObservationFactsContract
        (.o (:: @ (.ref PooFlowAdmissionObservationFactsContract 'proto))
            contract: contract-value accepted?: accepted-value
            classification-accepted?: classified-value obligation-count: obligation-count-value
            failures: failure-values detail-complete?: complete-value
            inspected-count: inspected-value)))))

;;; The summary is a fresh bounded aggregate projection. It does not carry the
;;; candidate, raw context, free-form diagnostic strings, identities, or paths.
(def (poo-flow-observation-admission-summary observation)
  (validate PooFlowAdmissionObservationContract observation)
  (let* ((facts (.ref observation 'evidence))
         (accepted-value (.ref facts 'accepted?))
         (complete-value (.ref facts 'detail-complete?))
         (count-value (length (.ref facts 'failures)))
         (inspected-value (.ref facts 'inspected-count)))
    (.o (:: @ (.ref PooFlowObservationSummaryContract 'proto))
        accepted?: accepted-value detail-complete?: complete-value
        failure-count: count-value inspected-count: inspected-value)))

;;; An internal explanation carries semantic correlation and bounded field
;;; paths. It is not the default development-output projection.
(def (poo-flow-observation-admission-explanation observation)
  (let ((summary (poo-flow-observation-admission-summary observation))
        (source-value (.ref observation 'source))
        (generation-value (.ref observation 'generation))
        (causes-value (.ref observation 'causes))
        (provenance-value (.ref observation 'provenance))
        (failure-values (.ref (.ref observation 'evidence) 'failures))
        (contract-value (.ref (.ref observation 'evidence) 'contract))
        (obligation-count-value (.ref (.ref observation 'evidence) 'obligation-count))
        (classified-value (.ref (.ref observation 'evidence) 'classification-accepted?)))
    (.o (:: @ summary) source: source-value generation: generation-value
        causes: causes-value provenance: provenance-value failures: failure-values
        contract: contract-value obligation-count: obligation-count-value
        classification-accepted?: classified-value)))

(def (poo-flow-observation-summary-sexp summary)
  (validate PooFlowObservationSummaryContract summary)
  (list 'admission-observation
        (list 'accepted? (.ref summary 'accepted?))
        (list 'detail-complete? (.ref summary 'detail-complete?))
        (list 'failure-count (.ref summary 'failure-count))
        (list 'inspected-count (.ref summary 'inspected-count))))

;; : (-> Symbol Natural PooFlowDebugCallPolicy)
(def (poo-flow-debug-call-policy label-value maximum-depth-value)
  (unless (> maximum-depth-value 0)
    (error "POO Flow debug call depth must be positive" maximum-depth-value))
  (validate PooFlowDebugCallPolicyContract
    (.o (:: @ (.ref PooFlowDebugCallPolicyContract 'proto))
        label: label-value
        maximum-depth: maximum-depth-value)))

;; : (-> PooFlowDebugCallPolicy Symbol Natural [Symbol] Symbol Symbol PooFlowDebugCallReceipt)
(def (poo-flow-debug-call-receipt policy call-value depth-value path-value
                                  operator-kind-value outcome-value)
  (validate PooFlowDebugCallPolicyContract policy)
  (let* ((policy-value policy)
         (accepted-value (memq outcome-value '(admitted returned)))
         (reason-value
          (case outcome-value
            ((admitted) 'call-admitted)
            ((returned) 'call-returned)
            ((raised) 'operator-raised)
            ((rejected-non-procedure) 'non-procedure-operator)
            ((rejected-cycle) 'recursive-call-cycle)
            ((rejected-depth) 'maximum-call-depth-exceeded)
            (else 'invalid-call-outcome))))
    (validate PooFlowDebugCallReceiptContract
      (.o (:: @ (.ref PooFlowDebugCallReceiptContract 'proto))
          policy: policy-value
          call: call-value
          depth: depth-value
          active-path: path-value
          operator-kind: operator-kind-value
          outcome: outcome-value
          accepted?: (if accepted-value #t #f)
          reason: reason-value))))

;;; The renderer is deliberately closed: it cannot force or retain arguments,
;;; results, a POO receiver, or an exception while reporting a bad call edge.
(def (poo-flow-debug-call-receipt-sexp receipt)
  (validate PooFlowDebugCallReceiptContract receipt)
  (list 'debug-call-observation
        (list 'label (.ref (.ref receipt 'policy) 'label))
        (list 'call (.ref receipt 'call))
        (list 'depth (.ref receipt 'depth))
        (list 'active-path (.ref receipt 'active-path))
        (list 'operator-kind (.ref receipt 'operator-kind))
        (list 'outcome (.ref receipt 'outcome))
        (list 'accepted? (.ref receipt 'accepted?))
        (list 'reason (.ref receipt 'reason))))

;;; Public policy construction remains POO-native. The defaults affect debug
;;; observation only; they do not replace a launch-time Gambit heap ceiling.
(def (poo-flow-debug-memory-policy label-value
                                   heap-limit-bytes: heap-limit-value
                                   live-growth-limit-bytes: live-growth-limit-value
                                   sample-interval-milliseconds:
                                   (sample-interval-value 100)
                                   collect-before-sample?: (collect-value #f)
                                   fail-closed?: (fail-closed-value #t))
  (validate PooFlowDebugMemoryPolicyContract
    (.o (:: @ (.ref PooFlowDebugMemoryPolicyContract 'proto))
        label: label-value
        heap-limit-bytes: heap-limit-value
        live-growth-limit-bytes: live-growth-limit-value
        sample-interval-milliseconds: sample-interval-value
        collect-before-sample?: collect-value
        fail-closed?: fail-closed-value)))

;;; The effectful adapter supplies already-read scalar counters here.
(def (poo-flow-debug-memory-sample phase-value heap-size-value allocated-value
                                   live-value movable-value still-value)
  (validate PooFlowDebugMemorySampleContract
    (.o (:: @ (.ref PooFlowDebugMemorySampleContract 'proto))
        phase: phase-value
        heap-size-bytes: heap-size-value
        allocated-bytes: allocated-value
        live-bytes: live-value
        movable-bytes: movable-value
        still-bytes: still-value)))

(def (poo-flow-debug-memory-positive-delta after-value before-value)
  (max 0 (- after-value before-value)))

;;; This comparison is deterministic for equal policy and sample values. It
;;; does not read the clock, trigger collection, inspect the heap, or print.
(def (poo-flow-debug-memory-receipt policy before after)
  (validate PooFlowDebugMemoryPolicyContract policy)
  (validate PooFlowDebugMemorySampleContract before)
  (validate PooFlowDebugMemorySampleContract after)
  ;; The *-value bindings are semantically required: .o slot bodies use bare
  ;; slot names for self dispatch, so directly writing `policy: policy` would
  ;; create a recursive self.policy computation instead of capturing the
  ;; constructor argument.
  (let* ((policy-value policy)
         (before-value before)
         (after-value after)
         (phase-value (.ref after 'phase))
         (heap-growth
          (poo-flow-debug-memory-positive-delta
           (.ref after-value 'heap-size-bytes)
           (.ref before-value 'heap-size-bytes)))
         (live-growth
          (poo-flow-debug-memory-positive-delta
           (.ref after-value 'live-bytes)
           (.ref before-value 'live-bytes)))
         (heap-exceeded?
          (> (.ref after-value 'heap-size-bytes)
             (.ref policy-value 'heap-limit-bytes)))
         (growth-exceeded?
          (> live-growth (.ref policy-value 'live-growth-limit-bytes)))
         (reason-value
          (cond (heap-exceeded? 'heap-limit-exceeded)
                (growth-exceeded? 'live-growth-limit-exceeded)
                (else 'within-budget))))
    (validate PooFlowDebugMemoryReceiptContract
      (.o (:: @ (.ref PooFlowDebugMemoryReceiptContract 'proto))
          phase: phase-value
          policy: policy-value
          before: before-value
          after: after-value
          heap-growth-bytes: heap-growth
          live-growth-bytes: live-growth
          accepted?: (eq? reason-value 'within-budget)
          reason: reason-value))))

;;; Only bounded scalar diagnostics reach DDT or a terminal. The policy and raw
;;; samples remain available as native objects for local drill-down.
(def (poo-flow-debug-memory-receipt-sexp receipt)
  (validate PooFlowDebugMemoryReceiptContract receipt)
  (list 'debug-memory-observation
        (list 'phase (.ref receipt 'phase))
        (list 'accepted? (.ref receipt 'accepted?))
        (list 'reason (.ref receipt 'reason))
        (list 'heap-size-bytes (.ref (.ref receipt 'after) 'heap-size-bytes))
        (list 'heap-growth-bytes (.ref receipt 'heap-growth-bytes))
        (list 'live-bytes (.ref (.ref receipt 'after) 'live-bytes))
        (list 'live-growth-bytes (.ref receipt 'live-growth-bytes))))
