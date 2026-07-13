#include "poo_flow/bundle_v1.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define COMPONENT_COUNT UINT64_C(65536)
#define LOOKUP_COUNT UINT64_C(1000000)

static poo_flow_bundle_v1_compact_id compact_id(uint64_t value) {
  poo_flow_bundle_v1_compact_id result = {0u, value};
  return result;
}

int main(void) {
  const uint64_t arena_bytes =
      COMPONENT_COUNT * sizeof(poo_flow_bundle_v1_component_entry);
  poo_flow_bundle_v1_component_entry *components =
      (poo_flow_bundle_v1_component_entry *)calloc(1u, (size_t)arena_bytes);
  poo_flow_bundle_v1_descriptor descriptor;
  const poo_flow_bundle_v1_component_entry *found = NULL;
  clock_t start = 0;
  clock_t finish = 0;
  uint64_t index = 0u;
  uint64_t checksum = 0u;

  if (components == NULL) {
    return 2;
  }
  for (; index < COMPONENT_COUNT; ++index) {
    components[index].case_id = compact_id(1u);
    components[index].component_id = compact_id(index);
    components[index].object_id = compact_id(index + UINT64_C(1000000));
    components[index].flags = POO_FLOW_BUNDLE_V1_COMPONENT_F_ENABLED;
  }
  memset(&descriptor, 0, sizeof(descriptor));
  descriptor.struct_size = (uint32_t)sizeof(descriptor);
  descriptor.flags = POO_FLOW_BUNDLE_V1_DESCRIPTOR_F_SORTED |
                     POO_FLOW_BUNDLE_V1_DESCRIPTOR_F_ZERO_COPY;
  descriptor.schema_major = POO_FLOW_BUNDLE_V1_SCHEMA_MAJOR;
  descriptor.schema_minor = POO_FLOW_BUNDLE_V1_SCHEMA_MINOR;
  descriptor.bundle_id = compact_id(1u);
  descriptor.digest[0] = 1u;
  descriptor.arena_bytes = arena_bytes;
  descriptor.symbols = (poo_flow_bundle_v1_region){
      0u, 0u, (uint32_t)sizeof(poo_flow_bundle_v1_symbol_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_symbol_entry)};
  descriptor.components = (poo_flow_bundle_v1_region){
      0u, arena_bytes, (uint32_t)sizeof(*components),
      (uint32_t)_Alignof(poo_flow_bundle_v1_component_entry)};
  descriptor.edges = (poo_flow_bundle_v1_region){
      0u, 0u, (uint32_t)sizeof(poo_flow_bundle_v1_edge_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_edge_entry)};
  descriptor.evidence_obligations = (poo_flow_bundle_v1_region){
      0u, 0u, (uint32_t)sizeof(poo_flow_bundle_v1_evidence_entry),
      (uint32_t)_Alignof(poo_flow_bundle_v1_evidence_entry)};
  descriptor.metadata_bytes =
      (poo_flow_bundle_v1_region){0u, 0u, 1u, 1u};

  if (poo_flow_bundle_v1_validate(&descriptor, components, arena_bytes) !=
      POO_FLOW_BUNDLE_V1_OK) {
    free(components);
    return 3;
  }

  start = clock();
  for (index = 0u; index < LOOKUP_COUNT; ++index) {
    const uint64_t key =
        (index * UINT64_C(11400714819323198485)) & (COMPONENT_COUNT - 1u);
    if (poo_flow_bundle_v1_find_component(
            &descriptor, components, compact_id(1u), compact_id(key),
            &found) != POO_FLOW_BUNDLE_V1_OK) {
      free(components);
      return 4;
    }
    checksum ^= found->object_id.low;
  }
  finish = clock();

  printf("schema=poo-flow.bundle-v1.lookup-benchmark.1\n");
  printf("entries=%llu\n", (unsigned long long)COMPONENT_COUNT);
  printf("lookups=%llu\n", (unsigned long long)LOOKUP_COUNT);
  printf("elapsed-seconds=%.9f\n",
         (double)(finish - start) / (double)CLOCKS_PER_SEC);
  printf("lookup-complexity=O(log-n)\n");
  printf("payload-zero-copy=true\n");
  printf("checksum=%llu\n", (unsigned long long)checksum);
  free(components);
  return 0;
}
