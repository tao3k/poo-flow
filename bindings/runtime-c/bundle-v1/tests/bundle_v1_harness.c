#include "poo_flow/bundle_v1.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef union aligned_arena {
  max_align_t alignment;
  uint8_t bytes[4096];
} aligned_arena;

static int failures = 0;

static void expect_status(const char *name,
                          poo_flow_bundle_v1_status actual,
                          poo_flow_bundle_v1_status expected) {
  if (actual != expected) {
    fprintf(stderr, "%s: expected %s, got %s\n", name,
            poo_flow_bundle_v1_status_name(expected),
            poo_flow_bundle_v1_status_name(actual));
    failures += 1;
  }
}

static poo_flow_bundle_v1_compact_id compact_id(uint64_t value) {
  poo_flow_bundle_v1_compact_id result = {0u, value};
  return result;
}

static poo_flow_bundle_v1_region region(uint64_t offset,
                                        uint64_t length,
                                        uint32_t stride,
                                        uint32_t alignment) {
  poo_flow_bundle_v1_region result = {offset, length, stride, alignment};
  return result;
}

static poo_flow_bundle_v1_descriptor make_descriptor(
    const poo_flow_bundle_v1_component_entry *components,
    size_t component_count,
    aligned_arena *arena) {
  poo_flow_bundle_v1_descriptor descriptor;
  const uint64_t component_offset = 64u;
  memset(&descriptor, 0, sizeof(descriptor));
  memset(arena, 0, sizeof(*arena));
  memcpy(&arena->bytes[component_offset], components,
         component_count * sizeof(*components));
  descriptor.struct_size = (uint32_t)sizeof(descriptor);
  descriptor.flags = POO_FLOW_BUNDLE_V1_DESCRIPTOR_F_SORTED |
                     POO_FLOW_BUNDLE_V1_DESCRIPTOR_F_ZERO_COPY;
  descriptor.schema_major = POO_FLOW_BUNDLE_V1_SCHEMA_MAJOR;
  descriptor.schema_minor = POO_FLOW_BUNDLE_V1_SCHEMA_MINOR;
  descriptor.bundle_id = compact_id(1u);
  descriptor.digest[0] = 0x7fu;
  descriptor.bundle_epoch = 9u;
  descriptor.arena_bytes = sizeof(arena->bytes);
  descriptor.symbols = region(0u, 0u,
                              (uint32_t)sizeof(poo_flow_bundle_v1_symbol_entry),
                              (uint32_t)_Alignof(poo_flow_bundle_v1_symbol_entry));
  descriptor.components = region(
      component_offset, component_count * sizeof(*components),
      (uint32_t)sizeof(*components),
      (uint32_t)_Alignof(poo_flow_bundle_v1_component_entry));
  descriptor.edges = region(
      0u, 0u, (uint32_t)sizeof(poo_flow_bundle_v1_edge_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_edge_entry));
  descriptor.evidence_obligations = region(
      0u, 0u, (uint32_t)sizeof(poo_flow_bundle_v1_evidence_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_evidence_entry));
  descriptor.metadata_bytes = region(0u, 0u, 1u, 1u);
  return descriptor;
}

int main(void) {
  aligned_arena arena;
  poo_flow_bundle_v1_component_entry components[4];
  poo_flow_bundle_v1_edge_entry edges[2];
  poo_flow_bundle_v1_evidence_entry evidence[2];
  poo_flow_bundle_v1_descriptor descriptor;
  const poo_flow_bundle_v1_component_entry *found = NULL;
  size_t index = 0u;

  memset(components, 0, sizeof(components));
  for (; index < 4u; ++index) {
    components[index].case_id = compact_id(index < 2u ? 10u : 20u);
    components[index].component_id = compact_id((uint64_t)(index % 2u) + 1u);
    components[index].object_id = compact_id(100u + (uint64_t)index);
    components[index].type_id = compact_id(200u);
    components[index].contract_id = compact_id(300u);
    components[index].role_id = compact_id(400u);
    components[index].capability_id = compact_id(500u);
    components[index].policy_id = compact_id(600u);
    components[index].strategy_id = compact_id(700u);
    components[index].adapter_id = compact_id(800u);
    components[index].projection_id = compact_id(900u);
    components[index].composition_order = (uint64_t)index;
    components[index].flags = POO_FLOW_BUNDLE_V1_COMPONENT_F_ENABLED;
  }

  descriptor = make_descriptor(components, 4u, &arena);
  expect_status("valid descriptor",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_OK);
  expect_status("binary lookup",
                poo_flow_bundle_v1_find_component(
                    &descriptor, arena.bytes, compact_id(20u), compact_id(2u),
                    &found),
                POO_FLOW_BUNDLE_V1_OK);
  if (found == NULL || found->object_id.low != 103u ||
      (const uint8_t *)found < arena.bytes ||
      (const uint8_t *)found >= arena.bytes + sizeof(arena.bytes)) {
    fprintf(stderr, "binary lookup did not return an arena-backed row\n");
    failures += 1;
  }

  found = NULL;
  expect_status("missing component",
                poo_flow_bundle_v1_find_component(
                    &descriptor, arena.bytes, compact_id(20u), compact_id(99u),
                    &found),
                POO_FLOW_BUNDLE_V1_NOT_FOUND);

  descriptor.schema_major = 0u;
  expect_status("draft schema rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_INCOMPATIBLE_SCHEMA);
  descriptor.schema_major = POO_FLOW_BUNDLE_V1_SCHEMA_MAJOR;

  descriptor.components.length = sizeof(arena.bytes);
  expect_status("out of bounds rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_REGION_BOUNDS);
  descriptor = make_descriptor(components, 4u, &arena);

  components[1].component_id = compact_id(0u);
  descriptor = make_descriptor(components, 4u, &arena);
  expect_status("unsorted table rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_UNSORTED_TABLE);

  components[1].component_id = compact_id(2u);
  descriptor = make_descriptor(components, 4u, &arena);
  descriptor.reserved[3] = 1u;
  expect_status("reserved data rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_MALFORMED_DESCRIPTOR);

  descriptor = make_descriptor(components, 4u, &arena);
  memset(edges, 0, sizeof(edges));
  edges[0].case_id = compact_id(10u);
  edges[0].source_component_id = compact_id(1u);
  edges[0].target_component_id = compact_id(2u);
  edges[0].relation_id = compact_id(3u);
  edges[1] = edges[0];
  memcpy(&arena.bytes[1024], edges, sizeof(edges));
  descriptor.edges = region(
      1024u, sizeof(edges), (uint32_t)sizeof(poo_flow_bundle_v1_edge_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_edge_entry));
  expect_status("duplicate edge rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_DUPLICATE_KEY);

  descriptor = make_descriptor(components, 4u, &arena);
  memset(evidence, 0, sizeof(evidence));
  evidence[0].case_id = compact_id(10u);
  evidence[0].obligation_id = compact_id(2u);
  evidence[1].case_id = compact_id(10u);
  evidence[1].obligation_id = compact_id(1u);
  memcpy(&arena.bytes[1280], evidence, sizeof(evidence));
  descriptor.evidence_obligations = region(
      1280u, sizeof(evidence),
      (uint32_t)sizeof(poo_flow_bundle_v1_evidence_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_evidence_entry));
  expect_status("unsorted evidence rejected",
                poo_flow_bundle_v1_validate(&descriptor, arena.bytes,
                                            sizeof(arena.bytes)),
                POO_FLOW_BUNDLE_V1_UNSORTED_TABLE);

  if (failures != 0) {
    return 1;
  }
  printf("schema=poo-flow.bundle-v1.harness.1\n");
  printf("layout=typed-native-regions\n");
  printf("lookup=binary-search\n");
  printf("payload-zero-copy=true\n");
  printf("json-in-hot-path=false\n");
  return 0;
}
