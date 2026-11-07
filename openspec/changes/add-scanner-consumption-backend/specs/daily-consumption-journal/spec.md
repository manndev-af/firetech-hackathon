# Spec Delta

## Purpose

Mencatat konsumsi dari scanner secara otomatis dan menyediakan perubahan porsi serta ringkasan harian yang mempertahankan sumber dan ketidaklengkapan nutrisi.

## ADDED Requirements

### Requirement: Automatic consumption recording
The system SHALL persist a valid completed scan as one consumption entry owned by the server-selected user. It MUST store consumption time, immutable analysis basis, quantity, source provenance, and scan-time context. Failed analysis SHALL NOT contribute to the journal or totals.

#### Scenario: Successful scan
- **WHEN** a relevant scan response passes validation and persistence succeeds
- **THEN** the response contains the saved entry ID and that entry appears in the owner's journal and daily summary

### Requirement: Durable scan deduplication
The system SHALL require an idempotency key scoped to the owner and compare request fingerprints. Repeated identical requests MUST return the existing outcome or processing status without another provider call. Reusing a key with different input MUST fail. Uncertain prior dispatch MUST NOT be automatically repeated.

#### Scenario: Concurrent duplicate upload
- **WHEN** two identical requests with the same owner and key arrive together
- **THEN** at most one request invokes DeepSeek and at most one consumption entry is created

#### Scenario: Process restarts during provider dispatch
- **WHEN** the previous attempt's delivery or completion is uncertain
- **THEN** the same key does not trigger another provider call and the API reports the unresolved attempt

### Requirement: Deterministic portion correction
The system SHALL accept finite positive quantity changes in the entry's existing portion unit and calculate nutrients from the stored base quantity and base values. It MUST preserve nulls and provenance and MUST NOT reinterpret ingredient composition or convert incompatible units as a quantity update.

#### Scenario: Repeated portion edits
- **WHEN** quantity changes from one to two then back to one
- **THEN** values are recalculated from the original basis without cumulative rounding or additional DeepSeek requests

#### Scenario: Missing nutrient
- **WHEN** quantity changes and the original sugar value is null
- **THEN** sugar remains null rather than becoming zero

### Requirement: Owned journal operations
The system SHALL expose bounded list, detail, quantity update, and deletion for the current owner. Other-owner identifiers SHALL return not found. Deletion MUST remove the entry from future summaries and retrieval without allowing the original scan key to recreate it.

#### Scenario: Deleted entry
- **WHEN** an entry is deleted and its original scan request is replayed
- **THEN** it remains absent and replay reports deletion without another provider call

### Requirement: Timezone-aware daily summary
The system SHALL aggregate entries within the requested local date using the owner's timezone. It MUST return known subtotals, missing-value counts, and completeness/provenance indicators per nutrient, without claiming recorded food represents the user's entire intake.

#### Scenario: Partial records around midnight
- **WHEN** entries cross local midnight and some nutrient values are missing
- **THEN** each entry belongs to the correct local day and unknown values remain visible in summary completeness

### Requirement: Documented backend contract
The system SHALL document each domain endpoint, validation constraint, success/error response, and development ownership behavior in route-local OpenAPI. Existing starter endpoints SHALL remain distinguishable from persistent nutrition endpoints.

#### Scenario: Frontend integration handoff
- **WHEN** a frontend developer reads the OpenAPI document
- **THEN** they can identify multipart scan fields, OCR requirements, idempotency behavior, portion updates, and error recovery without changes to frontend source in this change
