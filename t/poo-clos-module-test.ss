;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO CLOS first-class module boundary and lazy runtime contract.

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         (only-in :std/test test-suite check-equal?)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-modules-system-use-module-group
                 poo-flow-user-module-selection-flags
                 poo-flow-user-module-selection-key)
        (only-in :poo-flow/src/module-system/descriptor/interface
                 poo-flow-module-depth
                 poo-flow-module-descriptor?
                 poo-flow-module-extensions
                 poo-flow-module-group
                 poo-flow-module-interface-object
                 poo-flow-module-name)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface-id)
        (only-in :poo-flow/src/module-system/loader/registry
                 poo-flow-src-modules-source-refs)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-kind
                 poo-flow-module-source-ref-value)
        :poo-flow/src/module-system/load
        (only-in :poo-flow/src/module-system/poo-clos/config
                 poo-clos-module
                 poo-clos-module-default-selection)
        (only-in :poo-flow/modules/funflow/method-combination
                 poo-flow-funflow-method-combination-module-ref))

(export poo-clos-module-test)

(def module-system-feature-interface-paths
  '("src/module-system/composition/interface.ss"
    "src/module-system/declaration/interface.ss"
    "src/module-system/descriptor/interface.ss"
    "src/module-system/diagnostics/interface.ss"
    "core/extension-graph/interface.ss"
    "src/module-system/loader/interface.ss"
    "core/module-schema/interface.ss"
    "core/object-family/interface.ss"
    "core/module-schema/validation.ss"
    "src/module-system/observability/interface.ss"
    "core/poo-clos/interface.ss"
    "src/module-system/profile-composition/interface.ss"
    "src/module-system/projection/interface.ss"
    "src/module-system/semantic-module/interface.ss"))

(def (all-files-exist? paths)
  (or (null? paths)
      (and (file-exists? (car paths))
           (all-files-exist? (cdr paths)))))

(def poo-clos-module-test
  (test-suite "POO CLOS first-class module boundary"
    (poo-flow-test-case "declaration syntax selects the POO-native core owner"
      (let (bundles
            (poo-flow-modules!
             :core (poo-clos +native)
             :flow (funflow +dag)))
        (check-equal?
         (map (lambda (bundle)
                (poo-flow-user-module-selection-key (car bundle)))
              bundles)
         '((core . poo-clos) (flow . funflow)))))
    (poo-flow-test-case "module-system feature layout exposes the POO CLOS owner"
      (check-equal? (all-files-exist? module-system-feature-interface-paths) #t))
    (poo-flow-test-case "registry resolves the lightweight POO CLOS config"
      (let (paths
            (map poo-flow-module-source-ref-value
                 (poo-flow-src-modules-source-refs)))
        (check-equal?
         (if (member "src/module-system/poo-clos/config.ss" paths) #t #f)
         #t)
        (check-equal?
         (if (member "src/module-system/poo-method-combination/config.ss"
                     paths)
           #t #f)
         #f)))
    (poo-flow-test-case "descriptor declares native MOP ownership without runtime load"
      (check-equal? (poo-flow-module-descriptor? poo-clos-module) #t)
      (check-equal? (poo-flow-module-name poo-clos-module) 'poo-clos)
      (check-equal? (poo-flow-module-group poo-clos-module) 'core)
      (check-equal? (poo-flow-module-depth poo-clos-module)
                    (cons -110 -110))
      (check-equal?
       (poo-flow-module-interface-id
        (poo-flow-module-interface-object poo-clos-module))
       "PooClos")
      (check-equal? (poo-flow-module-extensions poo-clos-module) '()))
    (poo-flow-test-case "default selection is POO-native"
      (let (default (car poo-clos-module-default-selection))
        (check-equal? (poo-flow-modules-system-use-module-group 'poo-clos)
                      'core)
        (check-equal? (poo-flow-user-module-selection-flags default)
                      '(+native))))
    (poo-flow-test-case "Funflow references the sole method-combination owner"
      (check-equal?
       (poo-flow-module-source-ref-kind
        poo-flow-funflow-method-combination-module-ref)
       'standard-library)
      (check-equal?
       (poo-flow-module-source-ref-value
        poo-flow-funflow-method-combination-module-ref)
       'poo-clos))))
