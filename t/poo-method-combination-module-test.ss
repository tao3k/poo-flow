;;; -*- Gerbil -*-
;;; First-class Doom-like module boundary and opt-in plugin contract.

(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-modules-system-use-module-group
                 poo-flow-user-module-selection-flags
                 poo-flow-user-module-selection-has-flag?
                 poo-flow-user-module-selection-key)
        (only-in :poo-flow/src/module-system/descriptor
                 poo-flow-module-depth
                 poo-flow-module-descriptor?
                 poo-flow-module-extensions
                 poo-flow-module-group
                 poo-flow-module-interface-object
                 poo-flow-module-name)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface-id)
        (only-in :poo-flow/src/module-system/module-registry
                 poo-flow-src-modules-source-refs)
        (only-in :poo-flow/src/module-system/source
                 poo-flow-module-source-ref-kind
                 poo-flow-module-source-ref-value)
        "../src/module-system/load.ss"
        (only-in "../src/modules/init.ss"
                 poo-flow-maintained-module-bundles)
        (only-in :poo-flow/src/modules/poo-method-combination/config
                 poo-method-combination-module
                 poo-method-combination-module-bundles
                 poo-method-combination-module-default-selection
                 poo-method-combination-observation-plugin-selection)
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-method-combination-module-ref))

(export poo-method-combination-module-test)

(def (maintained-module-standard-entrypoints-exist? bundles)
  (if (null? bundles)
    #t
    (let* ((key
            (poo-flow-user-module-selection-key (caar bundles)))
           (root
            (string-append "src/modules/" (symbol->string (cdr key)))))
      (and (file-exists? (string-append root "/config.ss"))
           (file-exists? (string-append root "/interface.ss"))
           (maintained-module-standard-entrypoints-exist? (cdr bundles))))))

(def poo-method-combination-module-test
  (test-suite "poo-method-combination first-class module boundary"
    (test-case "maintained and downstream declarations share one hygienic syntax"
      (let ((keys
             (map (lambda (bundle)
                    (poo-flow-user-module-selection-key (car bundle)))
                  poo-flow-maintained-module-bundles))
            (downstream
             (poo-flow-modules!
              :core (poo-method-combination)
              :flow (funflow +dag))))
        (check-equal? (length keys) 18)
        (check-equal?
         (and (member (cons 'core 'poo-method-combination) keys)
              (member (cons 'flow 'loop-engine) keys)
              #t)
         #t)
        (check-equal?
         (map (lambda (bundle)
                (poo-flow-user-module-selection-key (car bundle)))
              downstream)
         '((core . poo-method-combination) (flow . funflow)))
        (check-equal?
         (maintained-module-standard-entrypoints-exist?
          poo-flow-maintained-module-bundles)
         #t)))
    (test-case "registry derives the canonical config entrypoint"
      (let (paths
            (map poo-flow-module-source-ref-value
                 (poo-flow-src-modules-source-refs)))
        (check-equal?
         (and (member "src/modules/poo-method-combination/config.ss" paths) #t)
         #t)))
    (test-case "descriptor owns a native POO interface"
      (check-equal? (poo-flow-module-descriptor?
                     poo-method-combination-module)
                    #t)
      (check-equal? (poo-flow-module-name poo-method-combination-module)
                    'poo-method-combination)
      (check-equal? (poo-flow-module-group poo-method-combination-module)
                    'core)
      (check-equal? (poo-flow-module-depth poo-method-combination-module)
                    (cons -110 -110))
      (check-equal?
       (poo-flow-module-interface-id
        (poo-flow-module-interface-object poo-method-combination-module))
       "PooMethodCombination")
      (check-equal? (poo-flow-module-extensions poo-method-combination-module)
                    '()))
    (test-case "default selection is closed and Observation is opt-in"
      (let ((default (car poo-method-combination-module-default-selection))
            (observed
             (car poo-method-combination-observation-plugin-selection)))
        (check-equal? (poo-flow-modules-system-use-module-group
                       'poo-method-combination)
                      'core)
        (check-equal? (poo-flow-user-module-selection-flags default)
                      '(+standard))
        (check-equal? (poo-flow-user-module-selection-has-flag?
                       default '+observation)
                      #f)
        (check-equal? (poo-flow-user-module-selection-has-flag?
                       observed '+observation)
                      #t)))
    (test-case "Funflow references the shared core module"
      (check-equal?
       (poo-flow-module-source-ref-kind
        poo-flow-funflow-method-combination-module-ref)
       'standard-library)
      (check-equal?
       (poo-flow-module-source-ref-value
        poo-flow-funflow-method-combination-module-ref)
       'poo-method-combination))))
