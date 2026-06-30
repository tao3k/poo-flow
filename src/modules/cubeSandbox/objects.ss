;;; -*- Gerbil -*-
;;; Boundary: CubeSandbox module objects.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/module-system/sandbox-backend-object-syntax
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/sandbox-core/resource-contract)

(export poo-flow-cubeSandbox-object
        poo-flow-cubeSandbox-backend-capability
        poo-flow-cubeSandbox-backend-capability-registry
        poo-flow-cubeSandbox-profile-object
        poo-flow-cubeSandbox-module-objects)

;;; CubeSandbox object data names backend defaults only; adapter execution and
;;; snapshot materialization stay outside this module.
(defpoo-sandbox-backend-object-family
  poo-flow-cubeSandbox-object
  poo-flow-cubeSandbox-backend-capability
  poo-flow-cubeSandbox-backend-capability-registry
  poo-flow-cubeSandbox-profile-object
  poo-flow-cubeSandbox-module-objects
  (sandbox objects.cubeSandbox.sandbox
           objects.cubeSandbox
           objects.shared.sandbox
           ((backend Symbol override 'cube '((scope . cubeSandbox)))
            (profile Symbol override 'default '((scope . cubeSandbox)))))
  (backend cube
           poo-flow-sandbox-backend-capability/cube
           '((aliases . ((cubeSandbox . cube)))
             (metadata . ((scope . cubeSandbox)
                          (runtime-executed . #f)))))
  (profile objects.cubeSandbox.profile
           cubeSandbox
           objects.sandbox-core.profile
           (poo-flow-sandbox-core-profile-object
            poo-flow-cubeSandbox-object)
           ((backend-kind Symbol override 'cube
                          '((scope . cubeSandbox)
                            (owned-by . module-config)))
            (backend-ref Symbol override 'cubeSandbox
                         '((scope . cubeSandbox)
                           (owned-by . module-config)))
            (capabilities List override
                          '(process-run filesystem-read cache-mount)
                          '((scope . cubeSandbox)
                            (dsl-row . capabilities)))
            (backend-capability Object override
                                poo-flow-cubeSandbox-backend-capability
                                '((scope . cubeSandbox)
                                  (owned-by . module-config)))
            (resource-policy List override
                             (poo-flow-sandbox-filesystem-prototype->resource-policy
                              poo-flow-snapshot-filesystem-prototype)
                             '((scope . cubeSandbox)
                               (dsl-row . resources))))))
