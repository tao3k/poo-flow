;;; -*- Gerbil -*-
;;; Owner: Docker tutorial alignment lives in this extension module.
;;; Boundary: core provides descriptor, strategy, runner, and adapter protocols.
;;; Import contract: users opt in through =:extensions/docker= exports.
;;; Runtime contract: this module emits request data only.
;;; Runtime contract: image pulls and mounts stay behind runtime commands.
;;; Runtime contract: process control and CAS writes stay out of Scheme.
;;; Policy evidence: tests should trust the installed extension registry.

(import :core/api)

(export docker-task-family-descriptor
        make-docker-task-family-registry
        docker-enable-strategy
        make-docker-enabled-strategy
        make-docker-enabled-adapter
        make-docker-run-config
        make-docker-task
        task-docker-config
        task-docker-image
        task-docker-command
        task-docker-args
        task-docker-volumes
        task-docker-output-policy
        docker-flow)

;; TaskFamilyDescriptor <- Unit
(def docker-task-family-descriptor
  (make-task-family-descriptor 'docker 'docker 'adapter 'rust-or-external-runtime 'submit))

;; TaskFamilyRegistry <- [TaskFamilyRegistry]
(def (make-docker-task-family-registry . maybe-registry)
  (task-family-registry-extend (if (null? maybe-registry)
                                 default-task-family-registry
                                 (car maybe-registry))
                               docker-task-family-descriptor))

;;; Docker-aware strategies are opt-in wrappers over core strategy policy. Core
;;; stays unaware of Docker while extension users still get normal validation.
;; Strategy <- Strategy
(def (docker-enable-strategy strategy)
  (make-strategy (strategy-name strategy)
                 (append (strategy-capabilities strategy) '(docker))
                 (strategy-cache-policy strategy)
                 (strategy-failure-policy strategy)
                 (strategy-planner strategy)))

;;; The default constructor starts from local eager policy; composition helpers
;;; can reuse docker-enable-strategy when Docker is only one workflow capability.
;; Strategy <- Unit
(def (make-docker-enabled-strategy)
  (docker-enable-strategy (make-local-eager-strategy)))

;; RuntimeAdapter <- RuntimeAdapter
(def (make-docker-enabled-adapter adapter)
  (make-runtime-adapter (runtime-adapter-name adapter)
                        (append (runtime-adapter-capabilities adapter) '(docker))
                        (runtime-adapter-submitter adapter)
                        (runtime-adapter-fetcher adapter)
                        (runtime-adapter-store-putter adapter)
                        (runtime-adapter-store-getter adapter)))

;; Value <- Alist Symbol Value
(def (docker-option options key default)
  (let (entry (assoc key options))
    (if entry
      (cdr entry)
      default)))

;;; The configured Docker run entrypoint installs the extension task registry
;;; and adapter capability while preserving core run-config behavior.
;; RunConfig <- [Alist]
(def (make-docker-run-config . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (command (docker-option options 'runtime-command #f)))
    (make-run-config 'docker-runtime
                     (make-docker-enabled-strategy)
                     (make-docker-enabled-adapter (make-rust-adapter command))
                     (append '((runtime . rust)
                               (extension . docker))
                             options)
                     (make-docker-task-family-registry)
                     default-flow-declaration-registry)))

;;; Docker tasks are first-class extension request data for the runtime
;;; boundary. Rust owns image pulls, mounts, process control, and CAS output.
;; Task <- Symbol Image Command [Arg] [VolumeBinding] OutputPolicy Contract Contract
(def (make-docker-task name image command args volumes output-policy input-contract output-contract)
  (make-task name
             'docker
             (list 'docker
                   (list (cons 'image image)
                         (cons 'command command)
                         (cons 'args args)
                         (cons 'volumes volumes)
                         (cons 'output-policy output-policy)))
             input-contract
             output-contract
             #f))

;; DockerConfig | #f <- Task
(def (task-docker-config task)
  (if (eq? (task-kind task) 'docker)
    (cadr (task-request task))
    #f))

;; Value <- Task Symbol Value
(def (task-docker-config-ref task key default)
  (let ((config (task-docker-config task)))
    (if config
      (let (entry (assoc key config))
        (if entry
          (cdr entry)
          default))
      default)))

;; Image | #f <- Task
(def (task-docker-image task)
  (task-docker-config-ref task 'image #f))

;; Command | #f <- Task
(def (task-docker-command task)
  (task-docker-config-ref task 'command #f))

;; [Arg] <- Task
(def (task-docker-args task)
  (task-docker-config-ref task 'args '()))

;; [VolumeBinding] <- Task
(def (task-docker-volumes task)
  (task-docker-config-ref task 'volumes '()))

;; OutputPolicy | #f <- Task
(def (task-docker-output-policy task)
  (task-docker-config-ref task 'output-policy #f))

;; Flow <- Symbol Image Command [Arg] [VolumeBinding] OutputPolicy Contract Contract
(def (docker-flow name image command args volumes output-policy input-contract output-contract)
  (task-flow name
             (make-docker-task name
                               image
                               command
                               args
                               volumes
                               output-policy
                               input-contract
                               output-contract)))
