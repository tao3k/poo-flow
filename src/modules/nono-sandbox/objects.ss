;;; -*- Gerbil -*-
;;; Boundary: nono sandbox module objects.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/module-system/sandbox-backend-object-syntax
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/sandbox-core/resource-contract)

(export poo-flow-nono-sandbox-object
        poo-flow-nono-sandbox-backend-capability
        poo-flow-nono-sandbox-backend-capability-registry
        poo-flow-nono-sandbox-profile-object
        poo-flow-nono-sandbox-module-objects)

;;; Nono sandbox object data names the backend family and native binding
;;; default; native calls remain in their dedicated owner.
(defpoo-sandbox-backend-object-family
  poo-flow-nono-sandbox-object
  poo-flow-nono-sandbox-backend-capability
  poo-flow-nono-sandbox-backend-capability-registry
  poo-flow-nono-sandbox-profile-object
  poo-flow-nono-sandbox-module-objects
  (sandbox objects.nono-sandbox.sandbox
           objects.nono-sandbox
           objects.shared.sandbox
           ((backend Symbol override 'nono '((scope . nono-sandbox)))
            (binding Symbol override 'native-ffi '((scope . nono-sandbox)))))
  (backend nono
           poo-flow-sandbox-backend-capability/nono
           '((metadata . ((scope . nono-sandbox)
                          (runtime-executed . #f)))))
  (profile objects.nono-sandbox.profile
           nono-sandbox
           objects.nono-sandbox.sandbox
           (poo-flow-sandbox-core-profile-object
            poo-flow-nono-sandbox-object)
           ((profile-name Symbol override 'default
                          '((scope . nono-sandbox)
                            (dsl-row . profile-name)))
            (backend-kind Symbol override 'nono
                          '((scope . nono-sandbox)
                            (owned-by . module-config)))
            (backend-ref Symbol override 'nono-sandbox
                         '((scope . nono-sandbox)
                           (owned-by . module-config)))
            (network-policy List override '(deny-by-default)
                            '((scope . nono-sandbox)
                              (dsl-row . network)))
            (capabilities List override '(process filesystem tmpdir)
                          '((scope . nono-sandbox)
                            (dsl-row . capabilities)))
            (backend-capability Object override
                                poo-flow-nono-sandbox-backend-capability
                                '((scope . nono-sandbox)
                                  (owned-by . module-config)))
            (resource-policy List override
                             (poo-flow-sandbox-filesystem-prototype->resource-policy
                              poo-flow-runtime-filesystem-prototype)
                             '((scope . nono-sandbox)
                               (dsl-row . resources)))
            (metadata List append '()
                      '((scope . nono-sandbox)
                        (dsl-row . metadata))))))
