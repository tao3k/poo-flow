((max_total . 100ms)
 (observed_total . 20ms)
 (target_total . 25ms)
 (regression_budget . 5ms)
 (expected_over_input_budget . 0ms)
 (observedTimings
  ((name . "selective-demand") (durationMs . 1))
  ((name . "shared-object-cache") (durationMs . 1))
  ((name . "explicit-boundary") (durationMs . 1)))
 (targetRationale .
  "Validate large POO composition demand behavior: request one object path, reuse peer objects, and avoid loading unrelated branches.")
 (maxCollectMs . 100)
 (maxParseMs . 75)
 (maxFileMs . 25)
 (maxPhaseMs . 25)
 (observedCollectMs . 3)
 (observedParseMs . 5)
 (observedFileMs . 1)
 (observedPhaseMs . 1)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1000)
 (unit . "ms")
 (purpose .
  "Guard real POO object composition against eager loading of unrelated profile, agent, model, sandbox, and library branches.")
 (sourcePath . "t/scenarios/performance/poo-composition-lazy-demand/benchmark.ss")
 (feature . poo-composition-lazy-demand)
 (rule . GERBIL-SCHEME-AGENT-R046)
 (optimizationFocus .
  "native POO object reuse plus computed slot demand; no policy descriptor registry in the hot path")
 (inputPath .
  "t/scenarios/performance/poo-composition-lazy-demand/input/src/composition/incident-response.ss")
 (expectedPath .
  "t/scenarios/performance/poo-composition-lazy-demand/expected/src/composition/incident-response.ss")
 (inputShape
  composition
  (agent pull-request model sandbox)
  (agent scheduled-audit model sandbox))
 (expectedOutcome
  composition
  (shared-object model)
  (shared-object sandbox)
  (demand-subgraph pull-request model route)
  (unforced-object unused-candidate)
  (unforced-object large-library))
 (expectedRepair
  "reuse peer POO objects across agent branches"
  "push expensive route/image facts behind native lazy slots"
  "materialize only the requested object path until an explicit boundary")
 (expectedQualitySignals
  (selected-route . triage-fast-path)
  (shared-model . eq?)
  (model-route-force-count-before-full . 1)
  (unused-route-force-count-before-full . 0)
  (unused-route-force-count-after-full . 1)
  (large-library-force-count . 0))
 (pooFormEvidence .o .def defpoo)
 (pooUsageCallEvidence .ref .get .mix .o .def .putdefault! .setslot! setslots! .all-slots)
 (nativePooPrimary . #t)
 (adapterBoundary . "benchmark descriptor is a harness boundary; runtime path stays POO-native")
 (hotPathExemption . "no object<-alist, descriptor registry, or global memo cache in demand traversal")
 (hotPathEvidence .
  "t/module-system-poo-performance-test-support/composition-large-library.ss")
 (styleRewriteBoundary .
  "do not model the composition as policy descriptors; compose peer POO objects and let .ref force demand subgraphs")
 (measurementPhases selective-demand shared-object-cache explicit-boundary scenario-load assert-time-gate assert-memory-gate)
 (tags module-system poo composition lazy-demand native-object performance scenario))
