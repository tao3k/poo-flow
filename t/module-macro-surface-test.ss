;;; -*- Gerbil -*-
;;; Boundary: executable contracts for the public module/profile macro surface.
;;; Invariant: syntax lowers to ordinary POO objects and pure projection values.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :poo-flow/src/module-system/init-syntax
                 poo-flow-profile-extend)
        (only-in :poo-flow/src/module-system/load-syntax
                 poo-flow-load-profile-module-binding)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-bundle)
        (only-in :poo-flow/src/module-system/profile-composition-profile-syntax
                 poo-flow-composition-profile-module)
        (only-in :poo-flow/src/module-system/profile-config
                 poo-flow-user-profile-module-bundles
                 poo-flow-user-profile-name)
        (only-in :poo-flow/src/module-system/profiles/kernel
                 poo-flow-kernel-profile)
        (only-in :poo-flow/src/module-system/projection-syntax
                 poo-flow-module-field-rows/tail)
        :poo-flow/src/modules/cubeSandbox/config
        :poo-flow/src/modules/docker-sandbox/config
        :poo-flow/src/modules/nono-sandbox/config
        (only-in :poo-flow/src/modules/sandbox-core/profile
                 poo-flow-sandbox-profile-backend-kind
                 poo-flow-sandbox-profile-name))

(export module-macro-surface-test)

;;; Both identifier macros must preserve the call-site binding while sharing
;;; the canonical fallback module name outside a custom/<name> source tree.
(def poo-flow-custom-module-syntax-probe-module 'syntax-probe-binding)

(def load-profile-binding
  (poo-flow-load-profile-module-binding syntax-probe))

(def composition-profile-binding
  (poo-flow-composition-profile-module syntax-probe))

;;; Profile extension remains a POO-native declaration and appends complete
;;; module bundles without flattening individual module selection rows.
(def macro-extra-module-bundles
  (list
   (poo-flow-user-module-bundle
    (custom macro-surface "/tmp/poo-flow-macro-surface" +contract))))

(poo-flow-profile-extend macro-extended-profile
                         macro-extended
                         poo-flow-kernel-profile
  (bundles macro-extra-module-bundles))

;;; Each backend macro is called directly so its public shorthand is covered,
;;; while the collection forms exercise the shared ordered build recursion.
(def cube-direct-profile
  (poo-flow-cubeSandbox-profile cube/direct
    (metadata (declared-by . macro-surface-test))))

(def cube-derived-profile
  (poo-flow-cubeSandbox-profile-derive
   cube-direct-profile
   cube/derived
   ((scope . session))
   (metadata (derived-by . macro-surface-test))))

(def cube-profile-list
  (poo-flow-cubeSandbox-profiles
   (cube/list (metadata (declared-by . collection)))
   (cube/list-derived
    (:derive cube/list (scope . task))
    (metadata (derived-by . collection)))))

(def docker-direct-profile
  (poo-flow-docker-sandbox-profile docker/direct
    (metadata (declared-by . macro-surface-test))))

(def docker-derived-profile
  (poo-flow-docker-sandbox-profile-derive
   docker-direct-profile
   docker/derived
   ((scope . session))
   (metadata (derived-by . macro-surface-test))))

(def docker-profile-list
  (poo-flow-docker-sandbox-profiles
   (docker/list (metadata (declared-by . collection)))
   (docker/list-derived
    (:derive docker/list (scope . task))
    (metadata (derived-by . collection)))))

(def nono-direct-profile
  (poo-flow-nono-sandbox-profile nono/direct
    (metadata (declared-by . macro-surface-test))))

(def nono-derived-profile
  (poo-flow-nono-sandbox-profile-derive
   nono-direct-profile
   nono/derived
   ((scope . session))
   (metadata (derived-by . macro-surface-test))))

(def nono-profile-list
  (poo-flow-nono-sandbox-profiles
   (nono/list (metadata (declared-by . collection)))
   (nono/list-derived
    (:derive nono/list (scope . task))
    (metadata (derived-by . collection)))))

;; : (-> [PooSandboxProfile] [Symbol])
(def (profile-names profiles)
  (map poo-flow-sandbox-profile-name profiles))

;; : TestSuite
(def module-macro-surface-test
  (test-suite "poo-flow public module macro surface"
    (test-case "identifier macros preserve the generated binding"
      (check-equal? load-profile-binding 'syntax-probe-binding)
      (check-equal? composition-profile-binding 'syntax-probe-binding))
    (test-case "profile extension appends bundles to a POO profile"
      (check-equal? (poo-flow-user-profile-name macro-extended-profile)
                    'macro-extended)
      (check-equal?
       (length (poo-flow-user-profile-module-bundles macro-extended-profile))
       (+ (length (poo-flow-user-profile-module-bundles
                   poo-flow-kernel-profile))
          (length macro-extra-module-bundles))))
    (test-case "field-row tail projection preserves fixed-first ordering"
      (check-equal?
       (poo-flow-module-field-rows/tail
        '((tail . value))
        (kind 'module)
        (name 'syntax-surface))
       '((kind . module) (name . syntax-surface) (tail . value))))
    (test-case "backend profile macros construct and derive POO profiles"
      (check-equal? (poo-flow-sandbox-profile-backend-kind
                     cube-direct-profile)
                    'cube)
      (check-equal? (poo-flow-sandbox-profile-name cube-derived-profile)
                    'cube/derived)
      (check-equal? (poo-flow-sandbox-profile-backend-kind
                     docker-direct-profile)
                    'docker)
      (check-equal? (poo-flow-sandbox-profile-name docker-derived-profile)
                    'docker/derived)
      (check-equal? (poo-flow-sandbox-profile-backend-kind
                     nono-direct-profile)
                    'nono)
      (check-equal? (poo-flow-sandbox-profile-name nono-derived-profile)
                    'nono/derived))
    (test-case "backend profile collections preserve declaration order"
      (check-equal? (profile-names cube-profile-list)
                    '(cube/list cube/list-derived))
      (check-equal? (profile-names docker-profile-list)
                    '(docker/list docker/list-derived))
      (check-equal? (profile-names nono-profile-list)
                    '(nono/list nono/list-derived)))))
