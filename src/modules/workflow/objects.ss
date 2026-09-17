;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: workflow CI/CD POO check and check-map values.
;;; Invariant: constructors admit declared values but never execute commands.

(import (only-in :clan/poo/object .o .ref object? object<-alist)
        (only-in :poo-flow/src/modules/memory-core/durable/policy
                 +poo-flow-durable-action-classes+)
        (only-in :std/srfi/1 every)
        "types.ss"
        "cicd-projection-syntax.ss")

(export poo-flow-cicd-check
        poo-flow-cicd-check?
        poo-flow-cicd-check-map
        poo-flow-cicd-check-map?
        poo-flow-cicd-check-name
        poo-flow-cicd-check-profile
        poo-flow-cicd-check-command
        poo-flow-cicd-check-dependency-refs
        poo-flow-cicd-check-durable-task-id
        poo-flow-cicd-check-action-class
        poo-flow-cicd-check-compensation-refs
        poo-flow-cicd-check-artifact-retention
        poo-flow-cicd-check-artifacts
        poo-flow-cicd-check-cache
        poo-flow-cicd-check-secrets
        poo-flow-cicd-check-runtime
        poo-flow-cicd-check-map-name
        poo-flow-cicd-check-map-checks)

(def (poo-flow-cicd-require-list field value)
  (poo-flow-cicd-require
   (string-append "cicd check " field " must be a list")
   (list? value)
   value))

(def (poo-flow-cicd-check name profile command inputs config artifacts cache
                          secrets result runtime . maybe-metadata)
  (poo-flow-cicd-require "cicd check name must be a symbol" (symbol? name) name)
  (poo-flow-cicd-require
   "cicd check profile must be a symbol, POO object, or non-empty list of refs"
   (poo-flow-cicd-profile-ref? profile) profile)
  (poo-flow-cicd-require "cicd check command must be a non-empty string list"
                         (poo-flow-cicd-command-vector? command) command)
  (poo-flow-cicd-require-list "inputs" inputs)
  (poo-flow-cicd-require-list "config" config)
  (poo-flow-cicd-require-list "artifacts" artifacts)
  (poo-flow-cicd-require-list "cache" cache)
  (poo-flow-cicd-require-list "secrets" secrets)
  (poo-flow-cicd-require-list "result" result)
  (poo-flow-cicd-require "cicd check runtime must be a symbol"
                         (symbol? runtime) runtime)
  (object<-alist
   (poo-flow-cicd-field-rows
    (kind (poo-flow-cicd-check-kind))
    (schema +poo-flow-cicd-check-map-schema+)
    (check-name name)
    (profile-ref profile)
    (command-vector command)
    (input-bindings inputs)
    (config-sources config)
    (artifact-outputs artifacts)
    (cache-intents cache)
    (secret-requirements secrets)
    (result-protocol result)
    (runtime-mode runtime)
    (runtime-executed #f)
    (metadata (if (null? maybe-metadata) '() (car maybe-metadata))))))

(def (poo-flow-cicd-check? value)
  (and (object? value)
       (eq? (.ref value 'kind) (poo-flow-cicd-check-kind))))
(def (poo-flow-cicd-check-name check) (.ref check 'check-name))
(def (poo-flow-cicd-check-profile check) (.ref check 'profile-ref))
(def (poo-flow-cicd-check-command check) (.ref check 'command-vector))

(def (poo-flow-cicd-check-metadata-ref check key default)
  (let (entry (assoc key (.ref check 'metadata)))
    (if entry (cdr entry) default)))

(def (poo-flow-cicd-check-dependency-refs check)
  (let (refs (poo-flow-cicd-check-metadata-ref check 'dependency-refs '()))
    (poo-flow-cicd-require
     "cicd check dependency-refs must be a list of symbols"
     (poo-flow-cicd-symbol-list? refs) refs)
    refs))

(def (poo-flow-cicd-check-durable-task-id check)
  (let (task-id (poo-flow-cicd-check-metadata-ref
                 check 'durable-task-id (poo-flow-cicd-check-name check)))
    (poo-flow-cicd-require "cicd check durable-task-id must be a symbol"
                           (symbol? task-id) task-id)
    task-id))

(def (poo-flow-cicd-check-action-class check)
  (let (action-class
        (poo-flow-cicd-check-metadata-ref check 'action-class 'idempotent))
    (poo-flow-cicd-require
     "cicd check action-class must be a known durable action class"
     (and (symbol? action-class)
          (member action-class +poo-flow-durable-action-classes+))
     action-class)
    action-class))

(def (poo-flow-cicd-check-compensation-refs check)
  (let (refs (poo-flow-cicd-check-metadata-ref check 'compensation-refs '()))
    (poo-flow-cicd-require
     "cicd check compensation-refs must be a list of symbols"
     (poo-flow-cicd-symbol-list? refs) refs)
    refs))

(def (poo-flow-cicd-check-artifact-retention check)
  (let (retention
        (poo-flow-cicd-check-metadata-ref
         check 'artifact-retention 'workflow-retained))
    (poo-flow-cicd-require "cicd check artifact-retention must be a symbol"
                           (symbol? retention) retention)
    retention))

(def (poo-flow-cicd-check-artifacts check) (.ref check 'artifact-outputs))
(def (poo-flow-cicd-check-cache check) (.ref check 'cache-intents))
(def (poo-flow-cicd-check-secrets check) (.ref check 'secret-requirements))
(def (poo-flow-cicd-check-runtime check) (.ref check 'runtime-mode))

(def (poo-flow-cicd-check-map name checks . maybe-metadata)
  (poo-flow-cicd-require "cicd check-map name must be a symbol"
                         (symbol? name) name)
  (poo-flow-cicd-require "cicd check-map checks must be a list"
                         (list? checks) checks)
  (poo-flow-cicd-require "cicd check-map checks must contain only cicd checks"
                         (every poo-flow-cicd-check? checks) checks)
  (.o kind: (poo-flow-cicd-check-map-kind)
      schema: +poo-flow-cicd-check-map-schema+
      map-name: name
      check-objects: checks
      runtime-executed: #f
      metadata: (if (null? maybe-metadata) '() (car maybe-metadata))))

(def (poo-flow-cicd-check-map? value)
  (and (object? value)
       (eq? (.ref value 'kind) (poo-flow-cicd-check-map-kind))))
(def (poo-flow-cicd-check-map-name check-map) (.ref check-map 'map-name))
(def (poo-flow-cicd-check-map-checks check-map) (.ref check-map 'check-objects))
