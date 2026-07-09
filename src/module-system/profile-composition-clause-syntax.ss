;;; -*- Gerbil -*-
;;; Boundary: clause syntax for POO-native profile composition.
;;; Invariant: clause syntax only wraps payloads; engines interpret later.

(import :poo-flow/src/module-system/profile-composition-core)

(export profile
        profiles
        compose
        graph
        loop
        prove
        handoff)

;; profile
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a profile clause into a POO profile reference for one module slot.
;;   # Examples
;;   ```scheme
;;   (profile workflow default)
;;   ;; => profile-ref
;;   ```
(defsyntax (profile stx)
  (syntax-case stx ()
    ((_ module slot)
     #'(poo-flow-profile-ref module 'slot))))

;; profiles
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a batch of profile slots from one module into POO profile refs.
;;   # Examples
;;   ```scheme
;;   (profiles workflow build test package)
;;   ;; => profile-ref list
;;   ```
(defsyntax (profiles stx)
  (syntax-case stx ()
    ((_ module slot ...)
     #'(list (poo-flow-profile-ref module 'slot) ...))))

(begin-syntax
  ;; : (-> Any Any)
  (def (poo-flow-compose-profile-item-exprs form)
    (let (items (syntax->list form))
      (match items
        ([head module . slots]
         (let (kind (syntax->datum head))
           (cond
            ((eq? kind 'profiles)
             (map (lambda (slot)
                    (with-syntax ((module module)
                                  (slot slot))
                      #'(poo-flow-profile-ref module 'slot)))
                  slots))
            ((and (eq? kind 'profile)
                  (= (length slots) 1))
             (with-syntax ((module module)
                           (slot (car slots)))
               (list #'(poo-flow-profile-ref module 'slot))))
            (else
             (list form)))))
        (else
         (list form)))))

  ;; : (-> Any Any)
  (def (poo-flow-compose-profile-exprs items)
    (let loop ((rest items) (out '()))
      (if (null? rest)
        (reverse out)
        (loop (cdr rest)
              (append (reverse (poo-flow-compose-profile-item-exprs
                                (car rest)))
                      out))))))

;; compose
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a compose clause for object-level profile composition.
;;   # Examples
;;   ```scheme
;;   (compose base overlay)
;;   ;; => composition clause
;;   ```
(defsyntax (compose stx)
  (syntax-case stx ()
    ((_ item ...)
     (let (profile-exprs
           (poo-flow-compose-profile-exprs (syntax->list #'(item ...))))
       (with-syntax (((profile-ref ...) profile-exprs))
         #'(poo-flow-composition-clause 'compose
                                        (list profile-ref ...)))))))

;; graph
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a graph clause that binds profile composition to graph receipts.
;;   # Examples
;;   ```scheme
;;   (graph workflow dag)
;;   ;; => graph clause
;;   ```
(defsyntax (graph stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'graph '(item ...)))))

;; loop
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a loop clause that connects profile composition with loop receipts.
;;   # Examples
;;   ```scheme
;;   (loop engine policy)
;;   ;; => loop clause
;;   ```
(defsyntax (loop stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'loop '(item ...)))))

;; prove
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a proof clause for validating composition contracts before handoff.
;;   # Examples
;;   ```scheme
;;   (prove capability receipt)
;;   ;; => proof clause
;;   ```
(defsyntax (prove stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'prove '(item ...)))))

;; handoff
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a handoff clause that projects composed profile state to a runtime boundary.
;;   # Examples
;;   ```scheme
;;   (handoff marlin receipt)
;;   ;; => handoff clause
;;   ```
(defsyntax (handoff stx)
  (syntax-case stx ()
    ((_ item ...)
     #'(poo-flow-composition-clause 'handoff '(item ...)))))
