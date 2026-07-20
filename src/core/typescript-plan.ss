(import :std/format
        ./plan)

(export execution-plan->typescript-string
        execution-plan->typescript-file!)

(def (typescript-string value)
  (format "~s" (cond
                 ((symbol? value) (symbol->string value))
                 ((string? value) value)
                 (else (format "~a" value)))))

(def (node-id->typescript-id node)
  (format "~a-~a"
          (plan-node-ordinal node)
          (plan-node-name node)))

(def (dependency-id->typescript-id dependency)
  (format "~a-~a" (list-ref dependency 2) (list-ref dependency 4)))

(def (display-separated values separator display-value output)
  (let loop ((rest values) (first? #t))
    (unless (null? rest)
      (unless first? (display separator output))
      (display-value (car rest) output)
      (loop (cdr rest) #f))))

(def (display-typescript-step node output)
  (display "    { id: " output)
  (display (typescript-string (node-id->typescript-id node)) output)
  (display ", ordinal: " output)
  (display (plan-node-ordinal node) output)
  (display ", name: " output)
  (display (typescript-string (plan-node-name node)) output)
  (display ", kind: " output)
  (display (typescript-string (plan-node-kind node)) output)
  (display ", dependencies: [" output)
  (display-separated
   (plan-node-dependencies node)
   ", "
   (lambda (dependency out)
     (display (typescript-string (dependency-id->typescript-id dependency)) out))
   output)
  (display "] },\n" output))

(def (display-typescript-edge source-id target-id output)
  (display "    { source: " output)
  (display (typescript-string source-id) output)
  (display ", target: " output)
  (display (typescript-string target-id) output)
  (display " },\n" output))

(def (execution-plan-edge-count nodes)
  (let loop ((rest nodes) (count 0))
    (if (null? rest)
        count
        (loop (cdr rest) (+ count (length (plan-node-dependencies (car rest))))))))

(def (display-typescript-topology nodes output)
  (let (edge-count (execution-plan-edge-count nodes))
    (display "export const workflowTopology = new Uint32Array([\n  1, " output)
    (display (length nodes) output)
    (display ", " output)
    (display edge-count output)
    (display ",\n  " output)
    (display-separated
     nodes
     ", "
     (lambda (node out) (display (plan-node-ordinal node) out))
     output)
    (display ",\n" output)
    (for-each
     (lambda (node)
       (for-each
        (lambda (dependency)
          (display "  " output)
          (display (list-ref dependency 2) output)
          (display ", " output)
          (display (plan-node-ordinal node) output)
          (display ",\n" output))
        (plan-node-dependencies node)))
     nodes)
    (display "]);\n" output)))

(def (execution-plan->typescript-string plan)
  (unless (execution-plan? plan)
    (error "POO-FLOW-TS-E001 expected execution-plan" plan))
  (let ((nodes (execution-plan-nodes plan))
        (output (open-output-string)))
    (display "// Generated from POO Flow Scheme. Do not edit.\n" output)
    (display "export type WorkflowStepState = \"pending\" | \"running\" | \"completed\" | \"failed\";\n" output)
    (display "export type WorkflowStep<Id extends string = string, Kind extends string = string> = {\n" output)
    (display "  readonly id: Id;\n  readonly ordinal: number;\n  readonly name: string;\n  readonly kind: Kind;\n  readonly dependencies: readonly string[];\n};\n" output)
    (display "export type WorkflowDefinition<Steps extends readonly WorkflowStep[] = readonly WorkflowStep[]> = {\n" output)
    (display "  readonly id: string;\n  readonly steps: Steps;\n  readonly edges: readonly { readonly source: string; readonly target: string }[];\n};\n\n" output)
    (display "export const workflow = {\n  id: " output)
    (display (typescript-string (execution-plan-flow-name plan)) output)
    (display ",\n  steps: [\n" output)
    (for-each (lambda (node) (display-typescript-step node output)) nodes)
    (display "  ],\n  edges: [\n" output)
    (for-each
     (lambda (node)
       (for-each
        (lambda (dependency)
          (display-typescript-edge
           (dependency-id->typescript-id dependency)
           (node-id->typescript-id node)
           output))
        (plan-node-dependencies node)))
     nodes)
    (display "  ],\n} as const satisfies WorkflowDefinition;\n\n" output)
    (display "export type Workflow = typeof workflow;\n" output)
    (display "export type WorkflowStepId = Workflow[\"steps\"][number][\"id\"];\n" output)
    (display "export type WorkflowStepKind = Workflow[\"steps\"][number][\"kind\"];\n\n" output)
    (display-typescript-topology nodes output)
    (get-output-string output)))

(def (execution-plan->typescript-file! plan path)
  (call-with-output-file path
    (lambda (output)
      (display (execution-plan->typescript-string plan) output))))
