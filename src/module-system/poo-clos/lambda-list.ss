;;; -*- Gerbil -*-
;;; Functional argument binding helpers for hygienically lowered CLOS methods.

(import (only-in :clan/poo/object .ref)
        (only-in :std/srfi/1 drop iota find))

(export poo-clos-positional-supplied? poo-clos-positional-argument
        poo-clos-rest-arguments poo-clos-key-argument
        poo-clos-method-combination-options-valid?
        poo-clos-combination-required-argument
        poo-clos-combination-optional-supplied?
        poo-clos-combination-optional-argument
        poo-clos-combination-rest-arguments
        poo-clos-combination-key-argument)

;; : (-> [SchemeValue] Natural Boolean)
(def (poo-clos-positional-supplied? arguments index)
  (< index (length arguments)))

;; : (-> [SchemeValue] Natural Thunk SchemeValue)
(def (poo-clos-positional-argument arguments index default-value)
  (if (poo-clos-positional-supplied? arguments index)
    (list-ref arguments index)
    (default-value)))

;; : (-> [SchemeValue] Natural [SchemeValue])
(def (poo-clos-rest-arguments arguments start)
  (drop arguments (min start (length arguments))))

;; : (-> [SchemeValue] Natural InitargName (Pair Boolean SchemeValue))
(def (poo-clos-key-argument arguments start name)
  (let* ((tail (poo-clos-rest-arguments arguments start))
         (position
          (find (lambda (index)
                  (eq? (list-ref tail (* 2 index)) name))
                (iota (quotient (length tail) 2)))))
    (if position
      (cons #t (list-ref tail (+ 1 (* 2 position))))
      (cons #f #f))))

;; : (-> [SchemeValue] Natural Natural Boolean Boolean [InitargName]
;;        Boolean Boolean)
(def (poo-clos-method-combination-options-valid?
      arguments required optional rest? key? keys allow-other-keys?)
  (let* ((count (length arguments))
         (start (+ required optional))
         (open-tail? (or rest? key?)))
    (and (>= count required)
         (or open-tail? (<= count start))
         (or (not key?)
             (let (tail (poo-clos-rest-arguments arguments start))
               (and (even? (length tail))
                    (andmap
                     (lambda (index)
                       (let (name (list-ref tail (* 2 index)))
                         (and (or (symbol? name) (keyword? name))
                              (or allow-other-keys?
                                  (memq name keys)
                                  (eq? name 'allow-other-keys)
                                  (and (keyword? name)
                                       (string=? (keyword->string name)
                                                 "allow-other-keys"))))))
                     (iota (quotient (length tail) 2)))))))))

;; : (-> ClosGenericFunction [SchemeValue] Natural SchemeValue)
(def (poo-clos-combination-required-argument generic arguments index)
  (let (generic-required (.ref (.ref generic 'lambda-list) 'required))
    (if (and (< index generic-required) (< index (length arguments)))
      (list-ref arguments index)
      #f)))

;; : (-> ClosGenericFunction [SchemeValue] Natural Boolean)
(def (poo-clos-combination-optional-supplied? generic arguments index)
  (let* ((lambda-list (.ref generic 'lambda-list))
         (required (.ref lambda-list 'required))
         (optional (.ref lambda-list 'optional))
         (position (+ required index)))
    (and (< index optional) (< position (length arguments)))))

;; : (-> ClosGenericFunction [SchemeValue] Natural Thunk SchemeValue)
(def (poo-clos-combination-optional-argument generic arguments index default)
  (if (poo-clos-combination-optional-supplied? generic arguments index)
    (list-ref arguments (+ (.ref (.ref generic 'lambda-list) 'required) index))
    (default)))

;; : (-> ClosGenericFunction [SchemeValue] [SchemeValue])
(def (poo-clos-combination-rest-arguments generic arguments)
  (let (lambda-list (.ref generic 'lambda-list))
    (poo-clos-rest-arguments
     arguments (+ (.ref lambda-list 'required) (.ref lambda-list 'optional)))))

;; : (-> ClosGenericFunction [SchemeValue] InitargName
;;        (Pair Boolean SchemeValue))
(def (poo-clos-combination-key-argument generic arguments name)
  (let (lambda-list (.ref generic 'lambda-list))
    (poo-clos-key-argument
     arguments (+ (.ref lambda-list 'required) (.ref lambda-list 'optional))
     name)))
