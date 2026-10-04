// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
use poo_flow_rust_runtime::{Error, SemanticRuntime};
use serde_json::{Value, json};
use std::{sync::Arc, time::Duration};

#[test]
fn native_python_differential_and_lifetime() {
    let path = std::env::var("POO_FLOW_SEMANTIC_LIBRARY").expect("native artifact required");
    let digest = std::env::var("POO_FLOW_SEMANTIC_SHA256").expect("artifact digest required");
    let fixture = std::env::var("POO_FLOW_RUST_DIFFERENTIAL").expect("Python oracle required");
    assert!(matches!(
        SemanticRuntime::open(&path, &"0".repeat(64), 64),
        Err(Error::DigestMismatch)
    ));
    let runtime = Arc::new(SemanticRuntime::open(&path, &digest, 64).unwrap());
    let descriptor = runtime.call("descriptor", &json!({})).unwrap();
    assert_eq!(descriptor["threading"], "single-owner-thread");
    let cases: Value = serde_json::from_slice(&std::fs::read(fixture).unwrap()).unwrap();
    for case in cases.as_array().unwrap() {
        println!("DIFFERENTIAL {}", case["name"]);
        let result = runtime
            .submit(case["operation"].as_str().unwrap(), &case["payload"])
            .unwrap()
            .wait_timeout(Duration::from_secs(5))
            .unwrap();
        assert_eq!(result, case["expected"]);
    }
    assert!(matches!(
        runtime.call("$host.temporal.source.register", &json!({})),
        Err(Error::InvalidInput)
    ));
    assert!(
        runtime
            .call("temporal.family.classify", &json!({}))
            .is_err()
    );
    assert!(runtime.call("descriptor", &json!({})).is_ok());
    assert_eq!(
        runtime
            .call("descriptor", &json!({"padding": "x".repeat(1_048_576)}))
            .unwrap_err(),
        Error::InvalidInput
    );
    // Direct ABI control confirms the consumer owner is not this test thread.
    #[repr(C)]
    struct RawResult {
        status: i32,
        data: *mut u8,
        length: usize,
    }
    unsafe {
        let library = libloading::Library::new(&path).unwrap();
        let call =
            library
                .get::<unsafe extern "C" fn(
                    *const std::ffi::c_char,
                    *const u8,
                    usize,
                    *mut RawResult,
                ) -> i32>(b"poo_flow_semantic_call\0")
                .unwrap();
        let release = library
            .get::<unsafe extern "C" fn(*mut RawResult)>(b"poo_flow_semantic_result_release\0")
            .unwrap();
        let mut result = RawResult {
            status: 0,
            data: std::ptr::null_mut(),
            length: 0,
        };
        let operation = std::ffi::CString::new("descriptor").unwrap();
        assert_eq!(call(operation.as_ptr(), b"{}".as_ptr(), 2, &mut result), 2);
        release(&mut result);
    }
    println!("INPUT-AND-OWNER-GUARDS verified");
    let mut pending = Vec::new();
    let mut rejected = 0;
    for _ in 0..8192 {
        match runtime.submit("descriptor", &json!({})) {
            Ok(call) => pending.push(call),
            Err(Error::QueueFull) => rejected += 1,
            Err(e) => panic!("unexpected queue error: {e}"),
        }
    }
    assert!(
        rejected > 0,
        "saturation must reject without blocking producer"
    );
    for call in pending {
        assert_eq!(call.wait().unwrap(), descriptor);
    }
    println!("QUEUE-BOUNDED {rejected} rejected requests");
    let handles: Vec<_> = (0..8)
        .map(|_| {
            let r = runtime.clone();
            std::thread::spawn(move || r.call("descriptor", &json!({})).unwrap())
        })
        .collect();
    for handle in handles {
        assert_eq!(handle.join().unwrap(), descriptor);
    }
    runtime.close().unwrap();
    runtime.close().unwrap();
    assert_eq!(
        runtime.call("descriptor", &json!({})).unwrap_err(),
        Error::Closed
    );
    assert!(matches!(
        SemanticRuntime::open(&path, &digest, 64),
        Err(Error::Closed)
    ));
}
