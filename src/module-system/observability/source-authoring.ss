;;; -*- Gerbil -*-
;;; Boundary: native POO projection of reader-owned authoring observations.
;;; Invariant: source datums are discarded before a public receipt is returned.

(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in "module-source-observation.ss"
                 poo-flow-scheme-inline-prototype-datum-observations
                 poo-flow-scheme-inline-prototype-port-observations
                 poo-flow-scheme-inline-prototype-file-observations)
        (only-in "types.ss" PooFlowAuthoringObservationContract))

(export PooFlowAuthoringObservationContract
        poo-flow-authoring-inline-prototype-datum-observations
        poo-flow-authoring-inline-prototype-port-observations
        poo-flow-authoring-inline-prototype-file-observations
        poo-flow-authoring-observation-sexp)

;;; Resolve the stable Contract prototype once when this owner loads.  Receipt
;;; construction then exposes object composition as its only cold operation.
(def PooFlowAuthoringObservation.
  (.ref PooFlowAuthoringObservationContract 'proto))

;; : (-> Alist Symbol Value)
(def (poo-flow-authoring-row-ref row key)
  (let (entry (assq key row))
    (if entry
      (cdr entry)
      (error "missing source authoring observation field" key))))

;; : (-> Alist PooFlowAuthoringObservation)
(def (poo-flow-authoring-observation-from-row row)
  (let (detail (poo-flow-authoring-row-ref row 'detail))
    (validate PooFlowAuthoringObservationContract
      (.o (:: @ PooFlowAuthoringObservation.)
          scope: (poo-flow-authoring-row-ref row 'scope)
          owner: (poo-flow-authoring-row-ref row 'owner)
          form: (poo-flow-authoring-row-ref row 'form)
          phase: (poo-flow-authoring-row-ref row 'phase)
          status: (poo-flow-authoring-row-ref row 'status)
          code: (poo-flow-authoring-row-ref detail 'code)
          recommendation: (poo-flow-authoring-row-ref detail 'recommendation)
          accepted?: #f
          runtime-executed?: #f))))

;; : (-> [Alist] [PooFlowAuthoringObservation])
(def (poo-flow-authoring-observations-from-rows rows)
  (map poo-flow-authoring-observation-from-row rows))

;; : (-> Symbol Value [PooFlowAuthoringObservation])
(def (poo-flow-authoring-inline-prototype-datum-observations scope datum)
  (poo-flow-authoring-observations-from-rows
   (poo-flow-scheme-inline-prototype-datum-observations scope datum)))

;; : (-> Symbol InputPort [PooFlowAuthoringObservation])
(def (poo-flow-authoring-inline-prototype-port-observations scope port)
  (poo-flow-authoring-observations-from-rows
   (poo-flow-scheme-inline-prototype-port-observations scope port)))

;; : (-> Symbol PathString [PooFlowAuthoringObservation])
(def (poo-flow-authoring-inline-prototype-file-observations scope path)
  (poo-flow-authoring-observations-from-rows
   (poo-flow-scheme-inline-prototype-file-observations scope path)))

;;; The final projection is closed over symbolic fields and cannot reconstruct
;;; the discarded source datum or claim runtime execution.
;; : (-> PooFlowAuthoringObservation Sexp)
(def (poo-flow-authoring-observation-sexp observation)
  (validate PooFlowAuthoringObservationContract observation)
  (list 'poo-authoring-observation
        (list 'scope (.ref observation 'scope))
        (list 'owner (.ref observation 'owner))
        (list 'form (.ref observation 'form))
        (list 'phase (.ref observation 'phase))
        (list 'status (.ref observation 'status))
        (list 'code (.ref observation 'code))
        (list 'recommendation (.ref observation 'recommendation))
        (list 'accepted? (.ref observation 'accepted?))
        (list 'runtime-executed? (.ref observation 'runtime-executed?))))
