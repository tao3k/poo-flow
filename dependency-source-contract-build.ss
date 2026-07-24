#!/usr/bin/env gxi

(import :std/make
        :clan/base
        :clan/building)

(def (dependency-source-contract-spec)
  '("src/contract/dependency-source-identity"))

(init-build-environment!
  name: "POO Flow dependency source contract"
  deps: '("clan/poo")
  spec: dependency-source-contract-spec)

(displayln "POO_FLOW_DEPENDENCY_SOURCE_CONTRACT_BUILD_RECEIPT {\"status\":\"ok\"}")
