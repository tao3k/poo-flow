;;; Real POO object construction used only by native conformance qualification.
(import (only-in :std/foreign begin-ffi c-define)
        (only-in :std/text/json json-object->string)
        (only-in :clan/poo/object .o)
        :poo-flow/src/policy/cedar-authority
        (only-in :gerbil-scheme-rust/scheme/native gerbil-rs-root-string))
(export main snapshot-root allow-root deny-root forbid-root)

;; : (-> [String] Void)
(def (main . _) (void))
;; : (-> Char Digest)
(def (digest digit) (string-append "sha256:" (make-string 64 digit)))
;; : CedarSchemaDocument
(def schema-document
  "{\"\":{\"entityTypes\":{\"User\":{},\"Job\":{}},\"actions\":{\"run\":{\"appliesTo\":{\"principalTypes\":[\"User\"],\"resourceTypes\":[\"Job\"],\"context\":{\"type\":\"Record\",\"attributes\":{\"approved\":{\"type\":\"Boolean\"},\"blocked\":{\"type\":\"Boolean\"}}}}}}}}")

;; : (-> Unit CedarAuthoritySnapshot)
(def (snapshot)
  (poo-flow-cedar-authority-snapshot
   (poo-flow-cedar-authority-context "native.authority" "native.context" 1 (digest #\2) 7 1 0)
   (poo-flow-cedar-proof-binding "native.composition" (digest #\1) (digest #\3)
     (digest #\4) (digest #\5)
     ["PooFlowProof.Runtime.CedarNative" "PooFlowProof.Runtime.CedarRuntimeHost"])
   [(poo-flow-cedar-policy "permit-run"
      "permit(principal == User::\"alice\", action == Action::\"run\", resource == Job::\"demo\") when { context.approved };")
    (poo-flow-cedar-policy "forbid-blocked" "forbid(principal, action, resource) when { context.blocked };")]
   (poo-flow-cedar-schema schema-document)
   (poo-flow-cedar-entities "[]")
   [(poo-flow-cedar-runtime-capability "Action::\"run\"" 1)]))

;; : (-> CedarPrincipal Boolean CedarAuthorizationRequest)
(def (request principal blocked?)
  (poo-flow-cedar-authorization-request principal "Action::\"run\"" "Job::\"demo\""
   (.o (approved #t) (blocked blocked?)) (digest #\6)
   (poo-flow-cedar-runtime-handoff 1 #u8(10 20 30) (digest #\7) (digest #\0) (digest #\8) (digest #\9))))

;; : (-> Unit NativeRoot)
(def (project-snapshot)
  (with-catch (lambda (_) 0)
    (lambda ()
      (gerbil-rs-root-string
       (json-object->string (poo-flow-cedar-authority-snapshot->runtime (snapshot)))))))
;; : (-> CedarPrincipal Boolean NativeRoot)
(def (project-request principal blocked?)
  (with-catch (lambda (_) 0)
    (lambda ()
      (gerbil-rs-root-string (json-object->string
        (poo-flow-cedar-authorization-request->runtime (request principal blocked?)))))))

;; begin-ffi bodies are raw Gambit forms, not Gerbil-expanded references.
;; Keep exception handling in the ordinary Gerbil functions and qualify them.
(begin-ffi (snapshot-root allow-root deny-root forbid-root)
  (c-define (snapshot-root) () int64 "poo_flow_cedar_snapshot_root" "extern"
    (poo-flow/bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance#project-snapshot))
  (c-define (allow-root) () int64 "poo_flow_cedar_allow_root" "extern"
    (poo-flow/bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance#project-request "User::\"alice\"" #f))
  (c-define (deny-root) () int64 "poo_flow_cedar_deny_root" "extern"
    (poo-flow/bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance#project-request "User::\"bob\"" #f))
  (c-define (forbid-root) () int64 "poo_flow_cedar_forbid_root" "extern"
    (poo-flow/bindings/cedar-gerbil/crates/cedar-gerbil/scheme/conformance#project-request "User::\"alice\"" #t)))
