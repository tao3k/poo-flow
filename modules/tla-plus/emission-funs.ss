;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Pure emission of the admitted finite hypothesis profile. No user Next,
;;; action execution, structural equations or general TLA+ evaluator.
(import (only-in :clan/poo/object .ref)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model-replay poo-flow-temporal-model-classify)
        (only-in :poo-flow/modules/temporal-causality/behavior/funs
                 poo-flow-temporal-behavior-model-replay poo-flow-temporal-behavior-explore
                 poo-flow-temporal-behavior-step-table)
        (only-in :poo-flow/modules/temporal-causality/behavior/objects poo-flow-temporal-behavior-query)
        (only-in "emission-types.ss" poo-flow-tla-temporal-emission?)
        (only-in "emission-objects.ss" poo-flow-tla-temporal-emission-value poo-flow-tla-behavior-emission-value))
(export poo-flow-tla-emit-temporal-model poo-flow-tla-temporal-emission-replay
        poo-flow-tla-emit-behavior-model)

(def (quoted value)
  ;; Match the literal admission profile exactly; never interpolate code or
  ;; silently replace a model identity to make a TLA module identifier.
  (unless (and (string? value)
               (every (lambda (c)
                        (and (>= (char->integer c) 32)
                             (not (memv c '(#\" #\\)))))
                      (string->list value)))
    (error "unsupported temporal TLA+ literal string" value))
  (string-append "\"" value "\""))
(def (joined values)
  (call-with-output-string
   (lambda (port)
     (let loop ((xs values))
       (unless (null? xs)
         (display (car xs) port)
         (unless (null? (cdr xs)) (display ", " port))
         (loop (cdr xs)))))))
(def (tuple values) (string-append "<<" (joined values) ">>"))
(def (rows values) (string-append "{" (joined (map tuple values)) "}"))
(def (fields value slots)
  (map (lambda (slot)
         (let (v (.ref value slot))
           (cond ((symbol? v) (quoted (symbol->string v)))
                 ((string? v) (quoted v))
                 ((exact-integer? v) (number->string v))
                 (else (error "unsupported temporal TLA+ field" slot))))) slots))

(def (poo-flow-tla-emit-temporal-model model query)
  (let* ((model (poo-flow-temporal-model-replay model))
         (answer (poo-flow-temporal-model-classify model query))
         (hypotheses (.ref model 'hypotheses))
         (data
          (string-append
           "---- MODULE TemporalComposition ----\n"
           "ModelIdentity == " (quoted (.ref model 'identity)) "\n"
           "ClockDomains == "
           (rows (map (lambda (d) (fields d '(identity clock-role)))
                      (.ref model 'domains))) "\n"
           "Observations == "
           (rows (map (lambda (o) (fields o '(identity domain-identity logical-position
                                                       provenance-identity modality)))
                      (.ref model 'observations))) "\n"
           "Hypotheses == "
           (rows (map (lambda (h) (fields h '(identity cause-observation-id effect-observation-id)))
                      hypotheses)) "\n"
           "Constraints == "
           (rows (apply append
                        (map (lambda (h)
                               (map (lambda (c)
                                      (append (fields c '(identity)) (fields h '(identity))
                                              (fields c '(relation left-observation-id right-observation-id))))
                                    (.ref h 'constraints))) hypotheses))) "\n"
           "FamilyComplete == " (if (.ref model 'family-complete?) "TRUE" "FALSE") "\n"
           "FamilySemantics == " (quoted (symbol->string (.ref model 'family-semantics))) "\n====\n"))
         (order (tuple (map (lambda (h) (quoted (.ref h 'identity))) hypotheses)))
         (limit (.ref query 'exploration-limit))
         (check
          (string-append
           "---- MODULE TemporalCompositionCheck ----\n"
           "EXTENDS TemporalComposition, Naturals, Sequences\n"
           "CONSTANTS ExplorationLimit, Target, ExpectedClassifications\n"
           "VARIABLES remaining, admitted, refuted, unknown\n"
           "vars == <<remaining, admitted, refuted, unknown>>\n"
           "Explorer == INSTANCE TemporalFamilyExplorer\n"
           "  WITH ClockDomains <- ClockDomains, Observations <- Observations,\n"
           "       Hypotheses <- Hypotheses, Constraints <- Constraints,\n"
           "       FamilyComplete <- FamilyComplete, FamilySemantics <- FamilySemantics,\n"
           "       ExplorationLimit <- ExplorationLimit, Target <- Target,\n"
           "       ExpectedClassifications <- ExpectedClassifications,\n"
           "       remaining <- remaining, admitted <- admitted,\n"
           "       refuted <- refuted, unknown <- unknown\n"
           "Order == " order "\n"
           "First == Order[CHOOSE i \\in 1..Len(Order):\n"
           "  Order[i] \\in remaining /\\ \\A j \\in 1..(i-1): Order[j] \\notin remaining]\n"
           ;; Full traversal checks all candidate orders. Bounded queries use
           ;; the canonical order in the Scheme model, so their frontiers agree.
           "Step == IF Explorer!Terminal THEN UNCHANGED vars ELSE "
           (if limit "Explorer!Explore(First)" "Explorer!ExploreAny") "\n"
           "Spec == Explorer!Init /\\ [][Step]_vars /\\ WF_vars(Step)\n"
           "InputInvariant == Explorer!InputInvariant\n"
           "PartitionInvariant == Explorer!PartitionInvariant\n"
           "StatusInvariant == Explorer!StatusInvariant\n"
           "BoundInvariant == Explorer!BoundInvariant\n"
           "TerminalAgreement == Explorer!TerminalAgreement\n"
           "EventuallyTerminal == Explorer!EventuallyTerminal\n====\n"))
         (config
          (string-append
           "SPECIFICATION Spec\nCONSTANTS ExplorationLimit = "
           (number->string (or limit 0)) "\n Target = "
           (quoted (.ref query 'hypothesis-identity)) "\n"
           " ExpectedClassifications = {" (quoted (symbol->string (.ref answer 'classification))) "}\n"
           "INVARIANT InputInvariant\nINVARIANT PartitionInvariant\n"
           "INVARIANT StatusInvariant\nINVARIANT BoundInvariant\n"
           "INVARIANT TerminalAgreement\nPROPERTY EventuallyTerminal\n")))
    (poo-flow-tla-temporal-emission-value model query data check config)))

(def (poo-flow-tla-temporal-emission-replay emission)
  (unless (poo-flow-tla-temporal-emission? emission)
    (error "invalid temporal TLA+ emission"))
  (let (expected (poo-flow-tla-emit-temporal-model
                 (.ref emission 'model) (.ref emission 'query)))
    (unless (every (lambda (slot) (equal? (.ref emission slot) (.ref expected slot)))
                   '(data-source check-source config-source model-digest))
      (error "temporal TLA+ emission differs from its model and query"))
    expected))

(def (trace-states-source trace-value)
  (if (not trace-value) "<<>>"
    (tuple (map (lambda (s)
                  (let (assignments (.ref s 'assignments))
                    (string-append "[id \\in {" (joined (map (lambda (a) (quoted (.ref a 'variable))) assignments))
                     "} |-> CASE "
                     (call-with-output-string
                       (lambda (port)
                         (let loop ((xs assignments))
                           (unless (null? xs)
                             (display (string-append "id = " (quoted (.ref (car xs) 'variable)) " -> "
                                                     (quoted (.ref (car xs) 'value))) port)
                             (unless (null? (cdr xs)) (display " [] " port))
                             (loop (cdr xs)))))) "]"))) (.ref trace-value 'states)))))
(def (trace-actions-source trace-value)
  (if trace-value (tuple (map quoted (.ref trace-value 'schedule))) "<<>>"))

;;; The complete finite behavior profile has its own interpretation. An
;;; emitted expectation is compared with TLC's independent transition kernel.
(def (poo-flow-tla-emit-behavior-model model property)
  (let* ((model (poo-flow-temporal-behavior-model-replay model))
         (query (poo-flow-temporal-behavior-query "source-correspondence" property #f node-limit: #f))
         (receipt (poo-flow-temporal-behavior-explore model query))
         (step-table (poo-flow-temporal-behavior-step-table model))
         (_ (unless (.ref step-table 'exhausted?) (error "incomplete native transition table cannot admit source correspondence")))
         (expected (case (.ref receipt 'classification)
                     ((necessary) "{TRUE}") ((refuted) "{FALSE}") ((possible) "{TRUE,FALSE}")
                     (else (error "incomplete behavior receipt cannot supply TLC expectation"))))
         (data
          (string-append
           "---- MODULE TemporalBehaviorComposition ----\n"
           "ModelIdentity == " (quoted (.ref model 'identity)) "\n"
           "StateVariables == "
           (rows (map (lambda (v) (list (quoted (.ref v 'identity))
                                       (string-append "{" (joined (map quoted (list-sort string<? (.ref v 'domain)))) "}")
                                       (quoted (.ref v 'initial)))) (.ref model 'variables))) "\n"
           "Mechanisms == "
           (rows (map (lambda (m) (list (quoted (.ref m 'identity))
                                       (rows (map (lambda (c) (fields c '(identity variable value))) (.ref m 'guards)))
                                       (rows (map (lambda (a) (fields a '(identity variable value))) (.ref m 'assignments)))
                                       (quoted (.ref m 'assumption)))) (.ref model 'mechanisms))) "\n"
           "Interventions == "
           (tuple (map (lambda (i) (tuple (list (quoted (.ref i 'identity)) (number->string (.ref i 'onset))
                                               (rows (map (lambda (a) (fields a '(identity variable value))) (.ref i 'assignments)))
                                               (string-append "{" (joined (map quoted (.ref i 'protected-variables))) "}")
                                               (quoted (.ref i 'assumption))))) (.ref model 'interventions))) "\n"
           "Horizon == " (number->string (.ref model 'horizon)) "\n"
           "PropertyIdentity == " (quoted (.ref property 'identity)) "\n"
           "PropertyKind == " (quoted (symbol->string (.ref property 'question))) "\n"
           "Conditions == " (rows (map (lambda (c) (fields c '(identity variable value))) (.ref property 'conditions))) "\n"
           "Deadline == " (number->string (.ref property 'deadline)) "\n"
           "ExpectedOutcomes == " expected "\n====\n"))
         (check
          (string-append
           "---- MODULE TemporalBehaviorCompositionCheck ----\n"
           "EXTENDS TemporalBehaviorComposition, Naturals, Sequences, FiniteSets\n"
           "VARIABLES state, step, held, reached, route\n"
           "Behavior == INSTANCE TemporalBehaviorSemantics\n"
           " WITH StateVariables <- StateVariables, Mechanisms <- Mechanisms,\n"
           " Interventions <- Interventions, Horizon <- Horizon, PropertyKind <- PropertyKind,\n"
           " Conditions <- Conditions, Deadline <- Deadline, ExpectedOutcomes <- ExpectedOutcomes,\n"
           " state <- state, step <- step, held <- held, reached <- reached\n"
           "NativeStepTableIdentity == " (quoted (.ref step-table 'identity)) "\n"
           "VariableOrder == " (tuple (map quoted (.ref step-table 'variable-order))) "\n"
           "NativeInitialValues == " (tuple (map quoted (.ref step-table 'initial-values))) "\n"
           "NativeSteps == "
           (rows (map (lambda (edge)
                        (list (number->string (.ref edge 'coordinate))
                              (tuple (map (lambda (a) (quoted (.ref a 'value))) (.ref (.ref edge 'before) 'assignments)))
                              (quoted (.ref edge 'action))
                              (tuple (map (lambda (a) (quoted (.ref a 'value))) (.ref (.ref edge 'after) 'assignments)))))
                      (.ref step-table 'steps))) "\n"
           "StateTuple(s) == [i \\in 1..Len(VariableOrder) |-> s[VariableOrder[i]]]\n"
           "StateFromTuple(values) == [id \\in Behavior!VariableIds |->\n"
           " values[CHOOSE i \\in 1..Len(VariableOrder): VariableOrder[i] = id]]\n"
           "NativeStepsSoundness == /\\ Len(VariableOrder) = Cardinality(Behavior!VariableIds)\n"
           " /\\ {VariableOrder[i]: i \\in 1..Len(VariableOrder)} = Behavior!VariableIds\n"
           " /\\ NativeInitialValues = StateTuple(Behavior!InitialState)\n"
           " /\\ \\A edge \\in NativeSteps:\n"
           "    /\\ edge[1] \\in 0..Horizon /\\ edge[1] < Horizon\n"
           "    /\\ Len(edge[2]) = Len(VariableOrder) /\\ Len(edge[4]) = Len(VariableOrder)\n"
           "    /\\ edge[3] \\in Behavior!MechanismIds \\cup {\"idle\"}\n"
           "    /\\ edge[4] = StateTuple(Behavior!Clamp(Behavior!Apply(StateFromTuple(edge[2]),edge[3]),edge[1]+1))\n"
           "StepAgreement == step < Horizon =>\n"
           " \\A action \\in Behavior!MechanismIds \\cup {\"idle\"}:\n"
           " <<step,StateTuple(state),action,StateTuple(Behavior!Clamp(Behavior!Apply(state,action),step+1))>> \\in NativeSteps\n"
           "WitnessActions == " (trace-actions-source (.ref receipt 'witness)) "\n"
           "WitnessStates == " (trace-states-source (.ref receipt 'witness)) "\n"
           "CounterActions == " (trace-actions-source (.ref receipt 'counterexample)) "\n"
           "CounterStates == " (trace-states-source (.ref receipt 'counterexample)) "\n"
           "Routes == {\"all\"}" (if (.ref receipt 'witness) " \\cup {\"witness\"}" "")
           (if (.ref receipt 'counterexample) " \\cup {\"counter\"}" "") "\n"
           "vars == <<state,step,held,reached,route>>\n"
           "Init == Behavior!Init /\\ route \\in Routes\n"
           "Next == /\\ UNCHANGED route\n"
           " /\\ IF route = \"all\" THEN Behavior!Next ELSE\n"
           "     IF step = Horizon THEN UNCHANGED <<state,step,held,reached>>\n"
           "     ELSE Behavior!Advance(IF route = \"witness\" THEN WitnessActions[step+1] ELSE CounterActions[step+1])\n"
           "Spec == Init /\\ [][Next]_vars\nInputInvariant == Behavior!InputInvariant /\\ NativeStepsSoundness\n"
           "TraceAgreement == /\\ (route = \"witness\" => state = WitnessStates[step+1])\n"
           " /\\ (route = \"counter\" => state = CounterStates[step+1])\n"
           " /\\ (step = Horizon /\\ route = \"witness\" => Behavior!Satisfied)\n"
           " /\\ (step = Horizon /\\ route = \"counter\" => ~Behavior!Satisfied)\n"
           "TypeInvariant == Behavior!TypeInvariant\nTerminalAgreement == Behavior!TerminalAgreement\n====\n")))
    (poo-flow-tla-behavior-emission-value model property data check
     "SPECIFICATION Spec\nINVARIANT InputInvariant\nINVARIANT TypeInvariant\nINVARIANT TerminalAgreement\nINVARIANT TraceAgreement\nINVARIANT StepAgreement\n")))
