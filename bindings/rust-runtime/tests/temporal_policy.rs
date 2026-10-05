// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
use poo_flow_rust_runtime::{SemanticRuntime, datum, wire::Value};
fn instant(n: i64) -> Value {
    datum!({"identity":format!("at-{n}"),"domain":"policy-clock","coordinate":n,"provenance":"host-observation","modality":"observed"})
}
fn refresh(generation: i64, now: i64) -> Value {
    datum!({"schema":"poo-flow.temporal-policy-refresh-request.v1","policy":datum!({"identity":"rust-policy","revision":"r1","start":instant(1),"end":instant(4)}),"generation":generation,"effectiveAt":instant(now)})
}
fn task() -> Value {
    datum!({"schema":"poo-flow.temporal-support-request.v1",
    "program":datum!({"identity":"p","policy":"rust-policy","complete":true,"supports":vec![datum!({"identity":"s","conclusion":"claim","proof":"declared","premises":vec![datum!({"subject":"source","revision":"r1"})],"parents":Vec::<Value>::new()})]}),
    "journal":datum!({"identity":"j","admissionDomain":"txn","validDomain":"valid","revisions":vec![datum!({"identity":"r1","subject":"source","operation":"assert","predecessor":false,"admitted":1,"validRange":vec![Value::from(0),Value::from(10)],"content":"declared"})]}),"asOf":1,"validAt":false,"budget":128})
}
fn guard(reg: &Value) -> Value {
    datum!({"schema":"poo-flow.temporal-support-guard-request.v1","expectedGeneration":reg["generation"].clone(),"expectedPolicyDigest":reg["policyDigest"].clone(),"task":task()})
}
#[test]
fn actual_native_host_policy_control_and_failure_atomicity() {
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY").unwrap(),
        &std::env::var("POO_FLOW_SEMANTIC_SHA256").unwrap(),
        64,
    )
    .unwrap();
    assert!(
        runtime
            .call("$host.temporal.policy.refresh", &refresh(1, 1))
            .is_err()
    );
    let fake = datum!({"generation":1,"policyDigest":"none"});
    assert!(
        runtime
            .call("temporal.support.guard", &guard(&fake))
            .is_err()
    );
    let registered = runtime.refresh_policy(&refresh(1, 1)).unwrap();
    assert_eq!(runtime.refresh_policy(&refresh(1, 1)).unwrap(), registered);
    let query = guard(&registered);
    let first = runtime.call("temporal.support.guard", &query).unwrap();
    assert_eq!(first["policyStatus"], "applicable");
    assert_eq!(
        first["evaluation"]["conclusions"].as_array().unwrap()[0]["status"],
        "supported"
    );
    for flag in [
        "proofAdmitted",
        "sourceAuthenticated",
        "selectionAdmitted",
        "actionAuthorized",
        "durable",
    ] {
        assert_eq!(first[flag], false);
    }
    println!("CASE trusted policy register and guard use actual native owner, no effect grant");
    let current = runtime.refresh_policy(&refresh(2, 4)).unwrap();
    assert!(runtime.call("temporal.support.guard", &query).is_err());
    let query = guard(&current);
    let expired = runtime.call("temporal.support.guard", &query).unwrap();
    assert_eq!(expired["policyStatus"], "expired-policy");
    assert_eq!(expired["policyApplicable"], false);
    for bad in [refresh(3, 2), refresh(1, 4)] {
        assert!(runtime.refresh_policy(&bad).is_err());
        assert_eq!(
            runtime.call("temporal.support.guard", &query).unwrap(),
            expired
        );
    }
    let mut conflict = refresh(3, 4);
    conflict["policy"]["end"] = instant(6);
    assert!(runtime.refresh_policy(&conflict).is_err());
    assert_eq!(
        runtime.call("temporal.support.guard", &query).unwrap(),
        expired
    );
    let mut forged = query.clone();
    forged["effectiveAt"] = instant(0);
    assert!(runtime.call("temporal.support.guard", &forged).is_err());
    let mut stale = query.clone();
    stale["expectedPolicyDigest"] = "wrong".into();
    assert_eq!(
        runtime.call("temporal.support.guard", &stale).unwrap()["policyStatus"],
        "stale-policy"
    );
    println!(
        "CASE expiry, stale generation/digest, clock rollback, immutable revision and clock injection reject"
    );
    let descriptor = runtime.call("descriptor", &datum!({})).unwrap();
    assert_eq!(descriptor["abiVersion"], 1);
    if let Ok(path) = std::env::var("POO_FLOW_POLICY_ORACLE") {
        std::fs::write(path,poo_flow_rust_runtime::wire::to_vec(&datum!({"refresh":refresh(1,1),"registered":registered,"currentRefresh":refresh(2,4),"current":current.clone(),"query":guard(&current),"expired":expired})).unwrap()).unwrap();
    }
}
