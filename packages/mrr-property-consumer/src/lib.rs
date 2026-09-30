// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

//! POO Flow's typed handoff to MRR-owned source Query and MRR Data execution.
//!
//! The caller owns the source bytes, catalogs, and verified physical snapshot.
//! This layer chooses neither a GQL parser nor semantic admission rules.
#![forbid(unsafe_code)]

use meta_relational_reasoning::{
    CandidateQueryResult, CatalogBoundQuery, EntityCatalog, QueryResultBinding, QueryResultLimits,
    RelationCatalog,
};
use mrr_data_content::RestoredSnapshot;
use mrr_data_datafusion::{
    DataFusionQueryError, PropertyQueryLimits, RestoredPropertyQuery,
    execute_restored_property_path_query,
};
use mrr_property_source::{
    ExecutedPropertySourceQuery, PropertyQueryExecutor, PropertySourceExecutionError,
    compile_property_source_query,
};

/// One verified physical closure and bounded executor for a source-bound query.
pub struct RestoredPropertyExecutor<'a> {
    pub restored: &'a RestoredSnapshot,
    pub relation_catalog: &'a RelationCatalog,
    pub entity_catalog: &'a EntityCatalog,
    pub limits: PropertyQueryLimits,
}

impl PropertyQueryExecutor for RestoredPropertyExecutor<'_> {
    type Error = DataFusionQueryError;

    async fn execute<'a>(
        &'a self,
        query: &'a CatalogBoundQuery,
    ) -> Result<CandidateQueryResult, Self::Error> {
        let output = execute_restored_property_path_query(RestoredPropertyQuery {
            query,
            restored: self.restored,
            relation_catalog: self.relation_catalog,
            entity_catalog: self.entity_catalog,
            limits: self.limits,
        })
        .await?;
        Ok(CandidateQueryResult::new(
            QueryResultBinding::for_query(query),
            output.columns().to_vec(),
            output.rows().to_vec(),
        ))
    }
}

/// Compile the exact original source before physical execution, then let MRR
/// bind, execute through the supplied DataFusion adapter, and admit the result.
///
/// # Errors
/// Source drift, semantic rejection, and physical failures remain distinct.
pub async fn execute_property_source(
    source_name: &str,
    source_text: &str,
    expected_source_digest: &str,
    executor: &RestoredPropertyExecutor<'_>,
    result_limits: QueryResultLimits,
) -> Result<ExecutedPropertySourceQuery, PropertySourceExecutionError<DataFusionQueryError>> {
    let compiled = compile_property_source_query(source_name, source_text, expected_source_digest)
        .map_err(PropertySourceExecutionError::Semantic)?;
    compiled
        .execute_with(
            executor.relation_catalog,
            executor.entity_catalog,
            executor.restored.snapshot().manifest().semantic_snapshot(),
            executor,
            result_limits,
        )
        .await
}
