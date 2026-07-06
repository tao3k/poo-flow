;;; -*- Gerbil -*-
;;; Boundary: clause syntax for POO-native profile composition.
;;; Invariant: clause syntax only wraps payloads; engines interpret later.

(import :poo-flow/src/module-system/profile-composition-core)

(export profile
        compose
        graph
        loop
        prove
        handoff)

;;; Expands a module/profile pair to direct POO slot selection.
;;   | doc m%
;;       # Examples
;;       (profile session hardened)
;;   | result: selects (.ref session 'hardened)
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Select a named profile slot from a bound composition module.
;;       # Examples
;;       (profile session hardened)
;;   | result: expands to a POO profile reference value
;;   | boundary: slot lookup stays in the generated composition value
;;     %
(defsyntax (profile stx)
  (syntax-case stx ()
    ((_ module slot)
     #'(poo-flow-profile-ref module 'slot))))

;;; Stores selected profile objects as the stage compose payload.
;;   | doc m%
;;       # Examples
;;       (compose (profile session hardened) (profile sandbox restricted))
;;   | result: returns a compose clause containing profile objects
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Declare the ordered profile set composed by a composition stage.
;;       # Examples
;;       (compose (profile session hardened)
;;                (profile sandbox restricted))
;;   | result: expands to a composition clause with profile payload values
;;   | boundary: does not execute profiles; it declares reusable policy objects
;;     %
(defsyntax (compose stx)
  (syntax-case stx ()
    ((_ profile-ref ...)
     #'(poo-flow-composition-clause 'compose
                                    (list profile-ref ...)))))

;;; Stores graph metadata for graph-engine projection.
;;   | doc m%
;;       # Examples
;;       (graph guarded-rag-flow)
;;   | result: returns a graph clause without interpreting graph payloads
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Attach the graph strategy reference used by a composition stage.
;;       # Examples
;;       (graph guarded-flow)
;;   | result: expands to a graph composition clause
;;   | boundary: graph validation remains a downstream proof/test obligation
;;     %
(defsyntax (graph stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'graph '(item ...)))))

;;; Stores loop metadata for loop-engine projection.
;;   | doc m%
;;       # Examples
;;       (loop #:fuel 8 #:exit answer-ready)
;;   | result: returns a loop clause with policy metadata
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Attach loop policy metadata to a composition stage.
;;       # Examples
;;       (loop #:fuel 4 #:exit done)
;;   | result: expands to a loop composition clause
;;   | boundary: fuel and exit semantics are represented as policy data
;;     %
(defsyntax (loop stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'loop '(item ...)))))

;;; Stores proof obligation symbols for later fact projection.
;;   | doc m%
;;       # Examples
;;       (prove scope-contained graph-reachable loop-progress)
;;   | result: returns a prove clause with obligation symbols
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Declare proof obligations associated with a composition stage.
;;       # Examples
;;       (prove scope-contained graph-reachable loop-progress)
;;   | result: expands to a prove composition clause
;;   | boundary: proof names are declarations consumed by Lean/test gates
;;     %
(defsyntax (prove stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'prove '(item ...)))))

;;; Stores runtime handoff metadata at the composition boundary.
;;   | doc m%
;;       # Examples
;;       (handoff cicd runtime marlin)
;;   | result: returns a handoff clause for downstream runtime owners
;; : (-> Syntax Syntax)
;; : (-> Syntax Syntax)
;;   | doc m%
;;       Declare handoff metadata for runtime or Marlin boundaries.
;;       # Examples
;;       (handoff marlin-runtime)
;;   | result: expands to a handoff composition clause
;;   | boundary: handoff execution stays behind explicit runtime adapters
;;     %
(defsyntax (handoff stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'handoff '(item ...)))))
