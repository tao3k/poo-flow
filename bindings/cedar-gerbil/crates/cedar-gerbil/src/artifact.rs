// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

//! Map a validated Lean/Cedar candidate into the existing POO Flow policy
//! source type. The Gerbil POO owner still supplies the authority snapshot.

use cedar_poo_bridge::{ValidatedManifest, render_validated_policy_sources};
use poo_flow_cedar_authority::projection::PolicySource;
use poo_flow_cedar_authority::{Error, Result};

/// Preserve the Lean-exported policy identities after the bridge validates
/// the policies, schema, and entities with official Cedar.
pub fn policy_sources_from_validated_case(
    manifest: &ValidatedManifest,
    case_name: &str,
) -> Result<Vec<PolicySource>> {
    let sources = render_validated_policy_sources(manifest, case_name)
        .map_err(|detail| Error::new("cedar-artifact-invalid", detail))?;
    Ok(sources
        .into_iter()
        .map(|(identity, source)| PolicySource { identity, source })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn maps_checked_lean_policy_identity_without_creating_an_authority() {
        let manifest: ValidatedManifest = serde_json::from_value(json!({
            "schema": {"": {
                "entityTypes": {
                    "User": {"shape": {"type": "Record", "attributes": {}}},
                    "Document": {"shape": {"type": "Record", "attributes": {}}}
                },
                "actions": {"view": {"appliesTo": {
                    "principalTypes": ["User"], "resourceTypes": ["Document"],
                    "context": {"type": "Record", "attributes": {}}
                }}}
            }},
            "cases": [{
                "name": "view", "revision": "Published", "policy_ids": ["view-permit"],
                "policies": {"staticPolicies": {"view-permit": {
                    "effect": "permit",
                    "principal": {"op": "All"}, "action": {"op": "All"},
                    "resource": {"op": "All"}, "conditions": []
                }}, "templates": {}, "templateLinks": []},
                "entities": [],
                "request": {"principal": "User::\"alice\"",
                    "action": "Action::\"view\"",
                    "resource": "Document::\"one\"", "context": {}},
                "expected": "allow", "expected_reasons": ["view-permit"],
                "expected_error_policies": []
            }]
        }))
        .unwrap();
        let sources = policy_sources_from_validated_case(&manifest, "view").unwrap();
        assert_eq!(sources.len(), 1);
        assert_eq!(sources[0].identity, "view-permit");
        assert!(sources[0].source.starts_with("permit("));
    }
}
