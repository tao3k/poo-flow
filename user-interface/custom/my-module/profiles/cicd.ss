;;; -*- Gerbil -*-
;;; Boundary: CI/CD downstream sandbox profile declarations.
;;; Invariant: included by ../config.ss; it does not execute workflows.

(use-module nono-sandbox
  :config
  (profiles
   (ci/check
    (network deny-by-default)
    (capabilities process-run filesystem-read tmpdir)
    (resources (cpu . 1) (memory . "1Gi") (timeout-ms . 90000))
    (metadata (intent . ci-check)
              (scope . cicd)
              (stage . check)))
   (ci/build
    (network allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (capabilities :append cache-mount)
    (resources (cpu . 4) (memory . "8Gi") (timeout-ms . 600000))
    (metadata (intent . ci-build)
              (scope . cicd)
              (stage . build)
              (artifacts . export)))
   (cd/release
    (network allowlisted "github.com" "ghcr.io")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (cpu . 2) (memory . "4Gi") (timeout-ms . 300000))
    (metadata (intent . cd-release)
              (scope . cicd)
              (stage . release)
              (manual-gate . required)))
   (cicd/artifact-promote
    (network allowlisted "artifact-store.internal" "github.com")
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (cpu . 1) (memory . "2Gi") (timeout-ms . 180000))
    (metadata (intent . artifact-promote)
              (scope . cicd)
              (stage . promote)
              (artifacts . consume)))))
