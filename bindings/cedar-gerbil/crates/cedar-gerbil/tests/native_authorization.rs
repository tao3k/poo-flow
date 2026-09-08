use gerbil_scheme::{GerbilRuntime, LinkedGerbilProgram};
use gerbil_scheme_sys::{GerbilGlobalState, GerbilModuleOrLink};
use poo_flow_cedar_authority::{
    canonical,
    runtime::Deployment,
    wire::{CEDAR_VERSION, LEAN_REVISION},
};
use poo_flow_cedar_gerbil::NativeAuthority;
use std::path::PathBuf;

unsafe extern "C" {
    fn ___LNK_poo__flow__cedar__linker(state: *mut GerbilGlobalState) -> *mut GerbilModuleOrLink;
    fn poo_flow_cedar_snapshot_root() -> i64;
    fn poo_flow_cedar_allow_root() -> i64;
    fn poo_flow_cedar_deny_root() -> i64;
    fn poo_flow_cedar_forbid_root() -> i64;
}

#[test]
fn native_poo_projection_dual_authorization_and_single_use_consumption() {
    let output = PathBuf::from(env!("OUT_DIR"));
    let program_c = std::fs::read_to_string(output.join("program_link.c")).unwrap();
    let bridge_c =
        std::fs::read_to_string(output.join("gerbil-scheme-rust__scheme__native.c")).unwrap();
    let program_id = "#define ___LINKER_ID ___LNK_poo__flow__cedar__linker";
    assert!(program_c.contains(program_id));
    assert!(
        !bridge_c.contains(program_id),
        "module linker identity was overwritten"
    );
    // SAFETY: build.ss and the generated linker include the bridge, POO module,
    // and the four exception-contained conformance exports declared above.
    let program = unsafe { LinkedGerbilProgram::from_linker(___LNK_poo__flow__cedar__linker) };
    let runtime = GerbilRuntime::initialize_program(program).unwrap();
    assert!(GerbilRuntime::initialize().is_err());
    let snapshot = unsafe { runtime.bind_string_export(poo_flow_cedar_snapshot_root) }.unwrap();
    let allow = unsafe { runtime.bind_string_export(poo_flow_cedar_allow_root) }.unwrap();
    let deny = unsafe { runtime.bind_string_export(poo_flow_cedar_deny_root) }.unwrap();
    let forbid = unsafe { runtime.bind_string_export(poo_flow_cedar_forbid_root) }.unwrap();
    let deployment = Deployment {
        runtime_endpoint: PathBuf::from(
            std::env::var_os("POO_FLOW_CEDAR_RUNTIME_SOCKET")
                .expect("qualification requires an independently launched Runtime Host"),
        ),
        runtime_artifact_digest: canonical::raw_digest(
            &std::fs::read(
                std::env::var_os("POO_FLOW_CEDAR_RUNTIME_HOST")
                    .expect("qualification requires the AOT Runtime Host artifact"),
            )
            .expect("read AOT Runtime Host artifact"),
        ),
        rust_component_digest: canonical::raw_digest(CEDAR_VERSION.as_bytes()),
        lean_component_digest: canonical::raw_digest(LEAN_REVISION.as_bytes()),
        timeout_ms: 10000,
        grant_lifetime_ms: 30000,
    };
    let mut authority = NativeAuthority::new(&runtime, &snapshot, deployment, [42; 32]).unwrap();
    let result = authority.issue(&allow).unwrap();
    assert_eq!(result.status, "authorized");
    assert!(
        result
            .receipt
            .payload
            .rust
            .payload
            .outcome
            .agrees_with(&result.receipt.payload.lean.payload.outcome)
    );
    assert_eq!(
        result.receipt.payload.provenance.composition_identity,
        "native.composition"
    );
    println!(
        "native-cedar decision={} rust_policies={:?} lean_policies={:?} input_digest={}",
        result.receipt.payload.rust.payload.outcome.decision,
        result
            .receipt
            .payload
            .rust
            .payload
            .outcome
            .determining_policies,
        result
            .receipt
            .payload
            .lean
            .payload
            .outcome
            .determining_policies,
        result.receipt.payload.rust.payload.input_artifact_digest,
    );
    let grant = result.grant.unwrap();
    assert_eq!(
        authority.consume(grant.clone(), &deny).unwrap_err().code,
        "grant-request-binding-mismatch"
    );
    assert_eq!(authority.info().pending_grants, 1);
    let consumed = authority.consume(grant.clone(), &allow).unwrap();
    assert_eq!(consumed.handoff.payload_hex, "0a141e");
    let replay = authority.consume(grant, &allow).unwrap_err();
    assert_eq!(replay.code, "grant-consumed-or-unknown");
    println!(
        "native-consume payload={} replay={}",
        consumed.handoff.payload_hex, replay.code
    );
    assert!(authority.issue(&deny).unwrap().grant.is_none());
    let denied = authority.issue(&forbid).unwrap();
    assert!(denied.grant.is_none());
    assert_eq!(
        denied
            .receipt
            .payload
            .rust
            .payload
            .outcome
            .determining_policies,
        ["forbid-blocked"]
    );
    authority.close();
}
