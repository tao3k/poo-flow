//! Independent Host protocol: typed admission, pinned children, and recovery.

use cedar_policy::{Context, Entities, Policy, PolicyId, PolicySet, Request};
use poo_flow_cedar_authority::runtime::{HOST_SCHEMA, RuntimeClient};
use poo_flow_cedar_authority::{canonical, wire};
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

fn artifact(path: &std::path::Path) -> String {
    canonical::raw_digest(&std::fs::read(path).unwrap())
}

fn valid_input() -> Vec<u8> {
    let mut policies = PolicySet::new();
    policies
        .add(
            Policy::parse(
                Some(PolicyId::new("permit-run")),
                "permit(principal, action, resource) when { context.approved };",
            )
            .unwrap(),
        )
        .unwrap();
    let request = Request::new(
        "User::\"alice\"".parse().unwrap(),
        "Action::\"run\"".parse().unwrap(),
        "Job::\"demo\"".parse().unwrap(),
        Context::from_json_value(serde_json::json!({"approved": true}), None).unwrap(),
        None,
    )
    .unwrap();
    wire::AuthorizationRequest::encode(&request, &policies, &Entities::empty())
}

#[test]
fn host_rejects_component_identity_not_bound_to_linked_revisions() {
    let host = std::path::PathBuf::from(
        std::env::var_os("POO_FLOW_CEDAR_RUNTIME_HOST")
            .expect("qualification requires the AOT Runtime Host artifact"),
    );
    let deployment = tempfile::tempdir().unwrap();
    let endpoint = deployment.path().join("runtime.sock");
    let runtime_digest = artifact(&host);
    let wrong_rust_digest = canonical::raw_digest(b"not-the-linked-cedar-version");
    let lean_digest = canonical::raw_digest(wire::LEAN_REVISION.as_bytes());
    let output = Command::new(&host)
        .args([
            "serve-unix",
            endpoint.to_str().unwrap(),
            &runtime_digest,
            &wrong_rust_digest,
            &lean_digest,
            "10000",
        ])
        .output()
        .unwrap();
    assert_eq!(output.status.code(), Some(2));
    assert!(
        String::from_utf8(output.stderr)
            .unwrap()
            .contains("cedar-runtime-component-mismatch")
    );
    assert!(!endpoint.exists());
}

#[test]
fn long_lived_host_rejects_bad_input_then_authorizes_with_pinned_witnesses() {
    let source = std::path::PathBuf::from(
        std::env::var_os("POO_FLOW_CEDAR_RUNTIME_HOST")
            .expect("qualification requires the AOT Runtime Host artifact"),
    );
    let deployment = tempfile::tempdir().unwrap();
    let host = deployment.path().join("cedar-runtime-host");
    std::fs::copy(&source, &host).unwrap();
    let runtime_digest = artifact(&host);
    let rust_digest = canonical::raw_digest(wire::CEDAR_VERSION.as_bytes());
    let lean_digest = canonical::raw_digest(wire::LEAN_REVISION.as_bytes());
    let endpoint = deployment.path().join("runtime.sock");
    let mut child = Command::new(&host)
        .args([
            "serve-unix",
            endpoint.to_str().unwrap(),
            &runtime_digest,
            &rust_digest,
            &lean_digest,
            "10000",
        ])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::inherit())
        .spawn()
        .unwrap();
    let deadline = Instant::now() + Duration::from_secs(10);
    while !endpoint.exists() {
        assert!(
            Instant::now() < deadline,
            "Runtime Host readiness timed out"
        );
        assert!(
            child.try_wait().unwrap().is_none(),
            "Runtime Host exited early"
        );
        std::thread::sleep(Duration::from_millis(2));
    }
    let mut runtime = RuntimeClient::connect(
        &endpoint,
        &runtime_digest,
        &rust_digest,
        &lean_digest,
        10000,
    )
    .unwrap();
    let hello = runtime.hello();
    assert_eq!(hello.schema_id, HOST_SCHEMA);
    assert_eq!(hello.timeout_ms, 10000);
    assert_eq!(hello.runtime_artifact_digest, runtime_digest);
    assert_eq!(hello.rust_component_digest, rust_digest);
    assert_eq!(hello.lean_component_digest, lean_digest);
    assert_eq!(hello.generation.len(), 64);

    // The admitted process keeps a private AOT copy for isolated workers.
    std::fs::write(&host, b"mutated after runtime admission").unwrap();

    assert_eq!(
        runtime.evaluate(&[0xff]).unwrap_err().code,
        "cedar-input-invalid"
    );

    let input = valid_input();
    let (rust, lean) = runtime.evaluate(&input).unwrap();
    assert_eq!(rust.outcome.decision, "allow");
    assert_eq!(rust.outcome.determining_policies, ["permit-run"]);
    assert!(rust.outcome.agrees_with(&lean.outcome));
    println!(
        "runtime-host generation={} sequence=2 rust_ms={} lean_ms={} input_digest={}",
        runtime.hello().generation,
        rust.elapsed_ms,
        lean.elapsed_ms,
        canonical::raw_digest(&input)
    );

    drop(runtime);
    assert!(child.wait().unwrap().success());
}
