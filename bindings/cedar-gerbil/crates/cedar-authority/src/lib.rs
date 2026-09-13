//! Native owner of strict, source-bound Cedar authorization.
//!
//! The normal public model is Gerbil POO. This crate receives its explicit
//! runtime projection; it does not own a second composition language.

#[cfg(all(feature = "aot-runtime-host", unix))]
pub mod aot_host;
pub mod authority;
pub mod canonical;
pub mod projection;
pub mod runtime;
pub mod wire;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, thiserror::Error)]
#[error("{code}: {detail}")]
pub struct Error {
    pub code: String,
    pub detail: String,
}

impl Error {
    pub fn new(code: impl Into<String>, detail: impl Into<String>) -> Self {
        Self {
            code: code.into(),
            detail: detail.into(),
        }
    }
}

pub type Result<T> = std::result::Result<T, Error>;
