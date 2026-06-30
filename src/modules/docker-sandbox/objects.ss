;;; -*- Gerbil -*-
;;; Boundary: Docker sandbox module objects.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/module-system/sandbox-backend-object-syntax
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/sandbox-core/resource-contract)

(export poo-flow-docker-sandbox-object
        poo-flow-docker-sandbox-backend-capability
        poo-flow-docker-sandbox-backend-capability-registry
        poo-flow-docker-sandbox-profile-object
        poo-flow-docker-sandbox-module-objects)

;;; Docker sandbox object data records container defaults only; image pulls,
;;; mounts, and process execution remain owned by runtime adapters.
(defpoo-sandbox-backend-object-family
  poo-flow-docker-sandbox-object
  poo-flow-docker-sandbox-backend-capability
  poo-flow-docker-sandbox-backend-capability-registry
  poo-flow-docker-sandbox-profile-object
  poo-flow-docker-sandbox-module-objects
  (sandbox objects.docker-sandbox.sandbox
           objects.docker-sandbox
           objects.shared.sandbox
           ((backend Symbol override 'docker '((scope . docker-sandbox)))
            (image String override "ubuntu:latest" '((scope . docker-sandbox)))))
  (backend docker
           poo-flow-sandbox-backend-capability/docker
           '((metadata . ((scope . docker-sandbox)
                          (runtime-executed . #f)))))
  (profile objects.docker-sandbox.profile
           docker-sandbox
           objects.sandbox-core.profile
           (poo-flow-sandbox-core-profile-object
            poo-flow-docker-sandbox-object)
           ((backend-kind Symbol override 'docker
                          '((scope . docker-sandbox)
                            (owned-by . module-config)))
            (backend-ref Symbol override 'docker-sandbox
                         '((scope . docker-sandbox)
                           (owned-by . module-config)))
            (capabilities List override
                          '(process-run filesystem-read filesystem-write tmpdir)
                          '((scope . docker-sandbox)
                            (dsl-row . capabilities)))
            (backend-capability Object override
                                poo-flow-docker-sandbox-backend-capability
                                '((scope . docker-sandbox)
                                  (owned-by . module-config)))
            (resource-policy List override
                             (poo-flow-sandbox-filesystem-prototype->resource-policy
                              poo-flow-runtime-volume-filesystem-prototype)
                             '((scope . docker-sandbox)
                               (dsl-row . resources))))))
