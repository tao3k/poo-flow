import assert from "node:assert/strict";
import test from "node:test";

const scenarios = [
  ["subagent-workflow", "subagent-workflow"],
  ["funflow", "funflow"],
];

for (const [workflowId, scenario] of scenarios) {
  test(`${workflowId} preserves compound scenario identity`, async () => {
    const { workflow, workflowTopology } = await import(
      `../generated/${workflowId}.generated.ts`
    );
    const ids = new Set(workflow.steps.map((step) => step.id));
    const root = workflow.steps.find((step) => step.id === workflow.rootId);
    const children = workflow.steps.filter((step) => step.parentId === workflow.rootId);

    assert.equal(workflow.id, workflowId);
    assert.equal(root?.scenario, scenario);
    assert.ok(children.length >= 2, "compound workflow must expose multiple direct children");
    assert.ok(
      workflow.steps.every((step) => !step.parentId || ids.has(step.parentId)),
      "every parentId must resolve inside the generated workflow",
    );
    assert.ok(
      workflow.edges.every((edge) => ids.has(edge.source) && ids.has(edge.target)),
      "every generated edge must resolve inside the generated workflow",
    );
    assert.deepEqual(Array.from(workflowTopology), [
      1,
      workflow.steps.length,
      workflow.edges.length,
    ]);
  });
}
