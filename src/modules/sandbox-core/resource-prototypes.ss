;;; -*- Gerbil -*-
;;; Boundary: canonical POO resource prototypes shared by sandbox contracts.

(import (only-in :clan/poo/object .def))

(export #t)

;;; Runtime resources are modeled as a first-class POO object so backend
;;; profiles can extend concrete slots without reintroducing ad hoc alists.
;; : PooSandboxFilesystemPrototype
(.def poo-flow-runtime-filesystem-prototype
  scope: 'runtime
  materialized-by: 'runtime
  mounts: 'runtime)

;; : PooSandboxFilesystemPrototype
(.def poo-flow-runtime-volume-filesystem-prototype
  scope: 'volume
  materialized-by: 'runtime
  mounts: 'runtime)

;; : PooSandboxFilesystemPrototype
(.def poo-flow-snapshot-filesystem-prototype
  scope: 'snapshot
  snapshot: 'clone)

;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-filesystem-resources-prototype
  filesystem: poo-flow-runtime-filesystem-prototype
  cpu: 2
  memory: "4Gi")
;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-volume-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def poo-flow-snapshot-resources-prototype
  filesystem: poo-flow-snapshot-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-volume-ports-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  ports: '((scope . runtime)
           (published-by . runtime))
  cpu: 2
  memory: "4Gi")
