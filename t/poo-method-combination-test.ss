;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :clan/poo/object .o .ref .mix .cc)
        "../src/module-system/poo-method-combination/interface.ss")
(export poo-method-combination-test)
(def generic
  (poo-combination-generic
   'poo-method-combination/render
   'poo-method-combination/render-plan))
(def root (poo-method-root generic))
(def (failure-code? code)
  (lambda (e) (and (poo-combination-failure? e) (eq? (.ref e 'code) code))))
(def (return-value _frame _receiver value) value)
(def leaf (poo-method-prototype root generic
            (poo-method-bundle primary: (poo-combination-method 'value return-value))))
(def poo-method-combination-test
  (test-suite "module: POO native C3 standard method combination"
    (test-case "native diamond order, reverse after, shared ancestor once, no result cache"
      (let (trace '())
        (def (record value) (set! trace (append trace (list value))))
        (def (layer base name)
          (def (around frame _receiver value)
            (record (list name 'around-enter))
            (let (result (poo-call-next-method frame))
              (record (list name 'around-exit)) result))
          (def (before _frame _receiver _value) (record (list name 'before)) (values 1 2))
          (def (primary frame _receiver value)
            (record (list name 'primary))
            (if (poo-next-method? frame) (poo-call-next-method frame) value))
          (def (after _frame _receiver _value) (record (list name 'after)) (values))
          (poo-method-prototype base generic
            (poo-method-bundle around: (poo-combination-method name around)
                               before: (poo-combination-method name before)
                               primary: (poo-combination-method name primary)
                               after: (poo-combination-method name after))))
        (let* ((a (layer root 'a)) (b (layer a 'b)) (c (layer a 'c))
               (d (layer (.mix b c) 'd)))
          (check-equal? (poo-combination-call generic d 7) 7)
          (check-equal? trace
            '((d around-enter) (b around-enter) (c around-enter) (a around-enter)
              (d before) (b before) (c before) (a before)
              (d primary) (b primary) (c primary) (a primary)
              (a after) (c after) (b after) (d after)
              (a around-exit) (c around-exit) (b around-exit) (d around-exit)))
          (set! trace '())
          (check-equal? (poo-combination-call generic d 8) 8)
          (check-equal? (length trace) 20))))
    (test-case "ordinary primary and around short circuit"
      (check-equal? (poo-combination-call generic leaf 12) 12)
      (def (stop _frame _receiver _value) 'stopped)
      (let (receiver (poo-method-prototype leaf generic
                       (poo-method-bundle around: (poo-combination-method 'stop stop))))
        (check-equal? (poo-combination-call generic receiver 1) 'stopped)))
    (test-case "zero and multiple values survive after and around"
      (def (many _frame _receiver _value) (values 1 2 3))
      (def (none _frame _receiver _value) (values))
      (def (next frame _receiver _value) (poo-call-next-method frame))
      (def (after _frame _receiver _value) (values 'ignored 'ignored))
      (for-each
       (lambda (body expected)
         (let (receiver (poo-method-prototype root generic
                          (poo-method-bundle primary: (poo-combination-method 'values body)
                            around: (poo-combination-method 'next next)
                            after: (poo-combination-method 'after after))))
           (check-equal? (call-with-values
                           (lambda () (poo-combination-call generic receiver 0)) list) expected)))
       (list many none) '((1 2 3) ())))
    (test-case "next original arguments and same-chain replacement receiver"
      (def (replace frame receiver _value)
        (poo-call-next-method frame (.cc receiver 'payload 'new) 42))
      (let (receiver (poo-method-prototype leaf generic
                       (poo-method-bundle primary: (poo-combination-method 'replace replace))))
        (check-equal? (poo-combination-call generic receiver 1) 42)))
    (test-case "changed applicability is not a redispatch"
      (def (replace frame _receiver _value) (poo-call-next-method frame leaf 42))
      (let (receiver (poo-method-prototype leaf generic
                       (poo-method-bundle primary: (poo-combination-method 'replace replace))))
        (check-exception (poo-combination-call generic receiver 1)
                         (failure-code? 'changed-applicable-methods))))
    (test-case "around-only rejection and collector identity collision"
      (def (stop _frame _receiver _value) 'stopped)
      (check-exception
       (poo-combination-call generic (poo-method-prototype root generic
         (poo-method-bundle around: (poo-combination-method 'stop stop))) 0)
       (failure-code? 'no-primary-method))
      (check-exception
       (poo-combination-call
        (poo-combination-generic
         'another
         'poo-method-combination/render-plan)
        leaf
        0)
       (failure-code? 'generic-slot-collision)))
    (test-case "multiple next calls retain lexical original arguments"
      (def (twice frame receiver value)
        (list (poo-call-next-method frame receiver 42) (poo-call-next-method frame)))
      (let (receiver (poo-method-prototype leaf generic
                       (poo-method-bundle primary: (poo-combination-method 'twice twice))))
        (check-equal? (poo-combination-call generic receiver 7) '(42 7))))
    (test-case "typed missing methods and forbidden auxiliary next"
      (def (next frame _receiver _value) (poo-call-next-method frame))
      (check-exception (poo-combination-call generic root 0) (failure-code? 'no-applicable-method))
      (check-exception (poo-combination-call generic (.o) 0) (failure-code? 'no-applicable-method))
      (for-each
       (lambda (bundle code)
         (check-exception (poo-combination-call generic (poo-method-prototype root generic bundle) 0)
                          (failure-code? code)))
       (list (poo-method-bundle before: (poo-combination-method 'before return-value))
             (poo-method-bundle primary: (poo-combination-method 'next next))
             (poo-method-bundle primary: (poo-combination-method 'value return-value)
                                before: (poo-combination-method 'next next))
             (poo-method-bundle primary: (poo-combination-method 'value return-value)
                                after: (poo-combination-method 'next next)))
       '(no-primary-method no-next-method next-forbidden-in-auxiliary next-forbidden-in-auxiliary)))
    (test-case "exception skips after"
      (let (after-ran? #f)
        (def (explode _frame _receiver _value) (raise 'domain-error))
        (def (after _frame _receiver _value) (set! after-ran? #t))
        (let (receiver (poo-method-prototype root generic
                         (poo-method-bundle primary: (poo-combination-method 'explode explode)
                                            after: (poo-combination-method 'after after))))
          (check-exception (poo-combination-call generic receiver 0) (lambda (e) (eq? e 'domain-error)))
          (check-equal? after-ran? #f))))))
