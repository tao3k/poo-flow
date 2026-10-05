// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Bounded Rust transport to the POO-owned native semantic engine.
//! All unsafe calls stay on one OS thread. No classification is implemented here.
#[cfg(feature = "orgize-source")]
pub mod org_source;
pub mod wire;
#[cfg(feature = "mrr-transport")]
pub mod mrr_support;
use crate::wire::Value;
use libloading::Library;
use sha2::{Digest, Sha256};
use std::{
    ffi::{CString, c_char},
    path::Path,
    sync::{Mutex, mpsc},
    thread::{self, JoinHandle},
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Error {
    InvalidInput,
    DigestMismatch,
    Closed,
    QueueFull,
    Native(i32, String),
    Transport(String),
}
impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for Error {}
fn trace(stage: &str) {
    if std::env::var_os("POO_FLOW_RUNTIME_TRACE").is_some() {
        eprintln!("NATIVE-PROGRESS {stage}");
    }
}
// One process-global native engine, even if the same artifact is copied to
// another path. 0 = unused, 1 = reserved/running, 2 = terminal.
static PROCESS_STATE: std::sync::atomic::AtomicU8 = std::sync::atomic::AtomicU8::new(0);
use std::sync::atomic::Ordering;
type Reply = mpsc::Sender<Result<Value, Error>>;
enum Command {
    Call(CString, Vec<u8>, Reply),
    Register(Vec<u8>, Reply),
    Close(mpsc::Sender<Result<(), Error>>),
}
struct State {
    sender: Option<mpsc::SyncSender<Command>>,
    worker: Option<JoinHandle<()>>,
}
pub struct SemanticRuntime {
    state: Mutex<State>,
}

impl SemanticRuntime {
    /// Verify the exact trusted native artifact before starting its owner thread.
    /// Native close is terminal for this process, including across Rust handles.
    pub fn open(
        path: impl AsRef<Path>,
        expected_sha256: &str,
        queue_capacity: usize,
    ) -> Result<Self, Error> {
        if PROCESS_STATE.load(Ordering::SeqCst) != 0 {
            return Err(Error::Closed);
        }
        if queue_capacity == 0 || queue_capacity > 64 {
            return Err(Error::InvalidInput);
        }
        let path = path
            .as_ref()
            .canonicalize()
            .map_err(|e| Error::Transport(e.to_string()))?;
        use std::io::Read;
        let mut file = std::fs::File::open(&path).map_err(|e| Error::Transport(e.to_string()))?;
        let mut hash = Sha256::new();
        let mut buffer = [0u8; 65_536];
        let mut hashed_bytes = 0usize;
        let mut reported_bytes = 0usize;
        loop {
            let length = file
                .read(&mut buffer)
                .map_err(|e| Error::Transport(e.to_string()))?;
            if length == 0 {
                break;
            }
            hash.update(&buffer[..length]);
            hashed_bytes += length;
            if hashed_bytes - reported_bytes >= 1_048_576 {
                trace(&format!("artifact-bytes-hashed={hashed_bytes}"));
                reported_bytes = hashed_bytes;
            }
        }
        if format!("{:x}", hash.finalize()) != expected_sha256 {
            return Err(Error::DigestMismatch);
        }
        PROCESS_STATE
            .compare_exchange(0, 1, Ordering::SeqCst, Ordering::SeqCst)
            .map_err(|_| Error::Closed)?;
        trace("artifact-digest-verified");
        let (sender, receiver) = mpsc::sync_channel(queue_capacity);
        let (ready_tx, ready_rx) = mpsc::channel();
        let worker = thread::Builder::new()
            .name("poo-semantic-owner".into())
            .spawn(move || {
                // SAFETY: artifact is explicitly selected and digest checked by the host.
                // Symbols implement semantic.h; no native pointers leave this thread.
                let native = unsafe { Native::load(&path) };
                match native {
                    Err(e) => {
                        PROCESS_STATE.store(0, Ordering::SeqCst);
                        let _ = ready_tx.send(Err(e));
                    }
                    Ok(native) => {
                        let status = unsafe { (native.open)() };
                        if status != 0 {
                            PROCESS_STATE.store(2, Ordering::SeqCst);
                            let _ = ready_tx.send(Err(Error::Native(status, "open".into())));
                            return;
                        }
                        trace("native-owner-opened");
                        let descriptor = native
                            .call(
                                &CString::new("descriptor").expect("static operation"),
                                b"(object)",
                            )
                            .and_then(|value| {
                                if value["schema"] != "poo-flow.semantic-descriptor"
                                    || value["abiVersion"] != 1_i32
                                    || value["wireFormat"] != "scheme-datum-v1"
                                {
                                    Err(Error::Transport("semantic v1 descriptor mismatch".into()))
                                } else {
                                    Ok(())
                                }
                            });
                        if let Err(error) = descriptor {
                            unsafe {
                                (native.close)();
                            }
                            PROCESS_STATE.store(2, Ordering::SeqCst);
                            let _ = ready_tx.send(Err(error));
                            return;
                        }
                        trace("native-v1-descriptor-verified");
                        let _ = ready_tx.send(Ok(()));
                        while let Ok(command) = receiver.recv() {
                            match command {
                                Command::Call(op, data, reply) => {
                                    let result = native.call(&op, &data);
                                    trace(&format!(
                                        "native-call-returned={}",
                                        op.to_string_lossy()
                                    ));
                                    let _ = reply.send(result);
                                }
                                Command::Register(data, reply) => {
                                    let result = native.register(&data);
                                    trace("source-registration-returned");
                                    let _ = reply.send(result);
                                }
                                Command::Close(reply) => {
                                    let status = unsafe { (native.close)() };
                                    PROCESS_STATE.store(2, Ordering::SeqCst);
                                    let _ = reply.send(if status == 0 {
                                        Ok(())
                                    } else {
                                        Err(Error::Native(status, "close".into()))
                                    });
                                    return;
                                }
                            }
                        }
                        unsafe {
                            (native.close)();
                        }
                        PROCESS_STATE.store(2, Ordering::SeqCst);
                    }
                }
            })
            .map_err(|e| {
                PROCESS_STATE.store(0, Ordering::SeqCst);
                Error::Transport(e.to_string())
            })?;
        match ready_rx
            .recv()
            .map_err(|e| Error::Transport(e.to_string()))?
        {
            Ok(()) => Ok(Self {
                state: Mutex::new(State {
                    sender: Some(sender),
                    worker: Some(worker),
                }),
            }),
            Err(e) => {
                let _ = worker.join();
                Err(e)
            }
        }
    }
    /// Queue a supported semantic operation. Queue saturation rejects immediately.
    /// Dropping a pending response does not interrupt an already running native call.
    pub fn submit(&self, operation: &str, payload: &Value) -> Result<Pending, Error> {
        if !matches!(
            operation,
            "descriptor"
                | "temporal.solve"
                | "temporal.verify"
                | "temporal.observe"
                | "temporal.family.classify"
                | "temporal.family.observe"
                | "temporal.family.admit"
                | "temporal.family.current"
                | "temporal.family.revision.root"
                | "temporal.family.revision.change"
                | "temporal.family.journal"
                | "temporal.family.archive.export"
                | "temporal.family.archive.replay"
                | "temporal.support.evaluate"
                | "temporal.fact.content"
        ) {
            return Err(Error::InvalidInput);
        }
        let op = CString::new(operation).map_err(|_| Error::InvalidInput)?;
        let data = wire::to_vec(payload).map_err(|_| Error::InvalidInput)?;
        if data.len() > 1_048_576 {
            return Err(Error::InvalidInput);
        }
        let (tx, rx) = mpsc::channel();
        let state = self.state.lock().map_err(|_| Error::Closed)?;
        let sender = state.sender.as_ref().ok_or(Error::Closed)?;
        sender
            .try_send(Command::Call(op, data, tx))
            .map_err(|e| match e {
                mpsc::TrySendError::Full(_) => Error::QueueFull,
                mpsc::TrySendError::Disconnected(_) => Error::Closed,
            })?;
        Ok(Pending(rx))
    }
    pub fn call(&self, operation: &str, payload: &Value) -> Result<Value, Error> {
        self.submit(operation, payload)?.wait()
    }
    /// Host control entrypoint: choose source state independently of model tools.
    /// This declares the host trust premise; it does not authenticate a provider.
    pub fn register_source(&self, payload: &Value) -> Result<Value, Error> {
        let data = wire::to_vec(payload).map_err(|_| Error::InvalidInput)?;
        if data.len() > 1_048_576 {
            return Err(Error::InvalidInput);
        }
        let (tx, rx) = mpsc::channel();
        {
            let state = self.state.lock().map_err(|_| Error::Closed)?;
            state
                .sender
                .as_ref()
                .ok_or(Error::Closed)?
                .try_send(Command::Register(data, tx))
                .map_err(|e| match e {
                    mpsc::TrySendError::Full(_) => Error::QueueFull,
                    mpsc::TrySendError::Disconnected(_) => Error::Closed,
                })?;
        }
        rx.recv().map_err(|_| Error::Closed)?
    }
    pub fn close(&self) -> Result<(), Error> {
        let mut state = self.state.lock().map_err(|_| Error::Closed)?;
        let Some(sender) = state.sender.take() else {
            return Ok(());
        };
        let (tx, rx) = mpsc::channel();
        let result = sender
            .send(Command::Close(tx))
            .map_err(|_| Error::Closed)
            .and_then(|_| rx.recv().map_err(|_| Error::Closed))
            .and_then(|r| r);
        if let Some(worker) = state.worker.take() {
            worker
                .join()
                .map_err(|_| Error::Transport("native owner panicked".into()))?;
        }
        result
    }
}
impl Drop for SemanticRuntime {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
pub struct Pending(mpsc::Receiver<Result<Value, Error>>);
impl Pending {
    pub fn wait(self) -> Result<Value, Error> {
        self.0.recv().map_err(|_| Error::Closed)?
    }
    /// Timeout bounds caller waiting only; native work is not asynchronously killed.
    pub fn wait_timeout(self, timeout: std::time::Duration) -> Result<Value, Error> {
        self.0
            .recv_timeout(timeout)
            .map_err(|e| Error::Transport(e.to_string()))?
    }
}
#[repr(C)]
struct NativeResult {
    status: i32,
    data: *mut u8,
    length: usize,
}
type Open = unsafe extern "C" fn() -> i32;
type Call = unsafe extern "C" fn(*const c_char, *const u8, usize, *mut NativeResult) -> i32;
type Register = unsafe extern "C" fn(*const u8, usize, *mut NativeResult) -> i32;
type Release = unsafe extern "C" fn(*mut NativeResult);
struct Native {
    _library: std::mem::ManuallyDrop<Library>,
    open: Open,
    close: Open,
    call: Call,
    register: Register,
    release: Release,
}
impl Native {
    unsafe fn load(path: &Path) -> Result<Self, Error> {
        let library = unsafe { Library::new(path) }.map_err(|e| Error::Transport(e.to_string()))?;
        trace("native-library-loaded");
        let symbol_error = |e: libloading::Error| Error::Transport(e.to_string());
        let open = unsafe {
            *library
                .get::<Open>(b"poo_flow_semantic_v1_open\0")
                .map_err(symbol_error)?
        };
        let close = unsafe {
            *library
                .get::<Open>(b"poo_flow_semantic_v1_close\0")
                .map_err(symbol_error)?
        };
        let call = unsafe {
            *library
                .get::<Call>(b"poo_flow_semantic_v1_call\0")
                .map_err(symbol_error)?
        };
        let release = unsafe {
            *library
                .get::<Release>(b"poo_flow_semantic_v1_result_release\0")
                .map_err(symbol_error)?
        };
        let register = unsafe {
            *library
                .get::<Register>(b"poo_flow_semantic_v1_source_register\0")
                .map_err(symbol_error)?
        };
        // Keep Gambit code mapped for process lifetime, including after terminal close.
        Ok(Self {
            _library: std::mem::ManuallyDrop::new(library),
            open,
            close,
            call,
            register,
            release,
        })
    }
    fn call(&self, op: &CString, input: &[u8]) -> Result<Value, Error> {
        self.response(|result| unsafe {
            (self.call)(op.as_ptr(), input.as_ptr(), input.len(), result)
        })
    }
    fn register(&self, input: &[u8]) -> Result<Value, Error> {
        self.response(|result| unsafe { (self.register)(input.as_ptr(), input.len(), result) })
    }
    // Both entrypoints execute only on the native owner with borrowed inputs.
    fn response(&self, invoke: impl FnOnce(&mut NativeResult) -> i32) -> Result<Value, Error> {
        let mut result = NativeResult {
            status: 0,
            data: std::ptr::null_mut(),
            length: 0,
        };
        // SAFETY: valid borrowed input and zero-initialized result, on native owner.
        let status = invoke(&mut result);
        let response = if result.data.is_null() {
            Err(Error::Native(status, "empty native result".into()))
        } else if result.length > 16_777_216 {
            Err(Error::Transport(
                "native result exceeds consumer bound".into(),
            ))
        } else {
            let bytes = unsafe { std::slice::from_raw_parts(result.data, result.length) };
            if status != 0 {
                Err(Error::Native(
                    status,
                    String::from_utf8_lossy(bytes).into_owned(),
                ))
            } else {
                wire::from_slice(bytes)
                    .map_err(|e| Error::Transport(e.to_string()))
                    .and_then(|value: Value| {
                        if value.as_object().is_some() {
                            Ok(value)
                        } else {
                            Err(Error::Transport("nonobject native result".into()))
                        }
                    })
            }
        };
        // SAFETY: release exactly once with the allocator that produced the result.
        unsafe {
            (self.release)(&mut result);
        }
        response
    }
}

#[cfg(feature = "mrr-transport")]
pub mod mrr;
