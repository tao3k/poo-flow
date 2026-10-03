;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Owned finite profiles bind native emission to the entire checked bundle.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :std/list/list every find)
        (only-in :gerbil-parser/src/runtime/artifact sha256-text)
        (only-in :poo-flow/modules/temporal-causality/behavior/funs poo-flow-temporal-behavior-step-table)
        "emission-types.ss" "emission-funs.ss" "bundle-types.ss" "bundle-funs.ss"
        "correspondence-types.ss")
(export poo-flow-tla-correspondence-bundle poo-flow-tla-check-correspondence!
        poo-flow-tla-correspondence-replay)
;; These pins are part of the reviewed profile implementation, not caller input.
(def hypothesis-pins
  '(("TemporalFamilyExplorer.tla" . "sha256:2d7d587e453121b953a288d9e450a0c8593106f2d9a2b04cbb99c6d68c9458ae")
    ("TemporalFamilySemantics.tla" . "sha256:3d44305ebbe6ad0c6a1a8ee9f59331a8f6f3d9f57d6217c091fd41b011b1f059")
    ("TemporalOrder.tla" . "sha256:cf86364b93722e24a482f03feb85587926b7ee4bb0f216645803c8a527001b46")))
(def behavior-pins
  '(("TemporalBehaviorSemantics.tla" . "sha256:3be71943f607168a35666fc3506acc2e63f678e09165e06a91dc6206d899e4ef")))
(def (canonical-emission emission)
  (cond ((poo-flow-tla-temporal-emission? emission) (poo-flow-tla-temporal-emission-replay emission))
        ((poo-flow-tla-behavior-emission? emission)
         (let (fresh (poo-flow-tla-emit-behavior-model (.ref emission 'model) (.ref emission 'property)))
           (unless (every (lambda (s) (equal? (.ref emission s) (.ref fresh s)))
                           '(model-digest data-source check-source config-source))
             (error "behavior emission differs from native replay")) fresh))
        (else (error "unsupported native correspondence emission"))))
(def (poo-flow-tla-correspondence-bundle emission libraries tools)
  (let* ((emission (canonical-emission emission))
         (hyp? (poo-flow-tla-temporal-emission? emission))
         (pins (if hyp? hypothesis-pins behavior-pins))
         (data (if hyp? "TemporalComposition" "TemporalBehaviorComposition"))
         (root (string-append data "Check")))
    (unless (and (list? libraries) (= (length libraries) (length pins))
                 (every poo-flow-tla-source-file? libraries)
                 (every (lambda (pin)
                          (let (file (find (lambda (f) (equal? (.ref f 'identity) (car pin))) libraries))
                            (and file (equal? (sha256-text (.ref file 'content)) (cdr pin))
                                 (equal? (.ref file 'semantic-digest) (cdr pin))))) pins))
      (error "correspondence requires the complete owned semantic profile, with exact source pins"))
    (poo-flow-tla-bundle root
      (append libraries (list (poo-flow-tla-source-file (string-append data ".tla") (.ref emission 'data-source))
                              (poo-flow-tla-source-file (string-append root ".tla") (.ref emission 'check-source))
                              (poo-flow-tla-source-file (string-append root ".cfg") (.ref emission 'config-source)))) tools)))
(def (step-identity emission)
  (if (poo-flow-tla-behavior-emission? emission)
      (.ref (poo-flow-temporal-behavior-step-table (.ref emission 'model)) 'identity) ""))
(def (receipt-id emission bundle checked)
  (sha256-text (string-append "poo-flow.tla.native-correspondence.v1\n"
    (.ref emission 'model-digest) "\n" (symbol->string (.ref emission 'semantic-subset)) "\n"
    (step-identity emission) "\n" (.ref bundle 'semantic-digest) "\n" (.ref checked 'identity))))
(def (poo-flow-tla-check-correspondence! emission libraries tools python: (python "python3"))
  (let* ((emission-value (canonical-emission emission))
         (bundle-value (poo-flow-tla-correspondence-bundle emission-value libraries tools))
         (checked-value (poo-flow-tla-check-bundle! bundle-value python: python)))
    (validate PooFlowTlaCorrespondence
      (.o kind: 'tla/native-correspondence identity: (receipt-id emission-value bundle-value checked-value)
          emission: emission-value bundle: bundle-value checked-bundle: checked-value
          model-digest: (.ref emission-value 'model-digest) semantic-subset: (.ref emission-value 'semantic-subset)
          step-table-identity: (step-identity emission-value) bounded-differential?: #t
          semantic-refinement?: #f action-authorized?: #f))))
(def (poo-flow-tla-correspondence-replay receipt)
  (unless (poo-flow-tla-correspondence? receipt) (error "invalid native correspondence receipt"))
  (let* ((emission (canonical-emission (.ref receipt 'emission))) (bundle (.ref receipt 'bundle))
         (pins (if (poo-flow-tla-temporal-emission? emission) hypothesis-pins behavior-pins))
         (libraries (map (lambda (pin) (find (lambda (f) (equal? (.ref f 'identity) (car pin))) (.ref bundle 'sources))) pins))
         (canonical (poo-flow-tla-correspondence-bundle emission libraries (.ref bundle 'toolchain)))
         (checked (.ref receipt 'checked-bundle)))
    (poo-flow-tla-bundle-replay bundle)
    (poo-flow-tla-checked-bundle-replay checked canonical)
    (unless (and (equal? (.ref bundle 'semantic-digest) (.ref canonical 'semantic-digest))
                 (equal? (.ref receipt 'model-digest) (.ref emission 'model-digest))
                 (equal? (.ref receipt 'semantic-subset) (.ref emission 'semantic-subset))
                 (equal? (.ref receipt 'step-table-identity) (step-identity emission))
                 (equal? (.ref receipt 'identity) (receipt-id emission canonical checked)))
      (error "native correspondence differs from model/profile/step/source/tool/output replay")) receipt))
