# Spec Delta

## Purpose

Membandingkan dua pilihan makanan berdasarkan data gambar, basis yang dijelaskan dan prioritas pengguna, tanpa menganggap keduanya sudah dikonsumsi atau menyimpan hasil perbandingan.

## ADDED Requirements

### Requirement: Two-image comparison request
The system SHALL expose POST /api/v1/comparisons under the configured API prefix. It MUST accept exactly one imageA, one imageB and a validated metadata JSON field describing modes food or label, optional descriptions, OCR and positive quantities per option. It MUST reject extra or duplicate fields and caller-supplied ownership.

#### Scenario: Mixed inputs
- **WHEN** a request contains a food image for A and a label image for B with matching explicit modes
- **THEN** both options are analyzed within the same comparison request

#### Scenario: Invalid upload
- **WHEN** an image is missing, corrupt, MIME-mismatched, over 5 MiB or over 20 megapixels, or total multipart exceeds 11 MiB
- **THEN** the request is rejected before any provider dispatch

#### Scenario: Metadata boundaries
- **WHEN** metadata contains an unknown field, description over 1,000 characters, OCR over 20,000 characters or quantity outside 0.000001 to 10000
- **THEN** the request fails validation before generation

### Requirement: One vision dispatch per accepted request
The system SHALL send both validated images and bounded personalization context in one provider dispatch per accepted HTTP request. It MUST NOT call the scanner consumption endpoint, retry automatically, or issue repair/explanation calls. It SHALL reject requests when the shared inference capacity is full.

#### Scenario: Successful dispatch
- **WHEN** both images and metadata are valid and capacity is available
- **THEN** both labeled options and one retrieved context are sent in one provider request

#### Scenario: Provider failure
- **WHEN** the provider times out, truncates output or returns invalid core structure
- **THEN** the API returns an appropriate error without another provider call

#### Scenario: Separate submissions
- **WHEN** a client explicitly submits the same images in another HTTP request
- **THEN** this is a new operation that can incur another provider call; no durable idempotency or replay is promised

### Requirement: Read-only personalized comparison
The system SHALL read the existing server-selected development user's profile, relevant consumption history and reviewed references. It MUST NOT write comparison results, consumption, scan operations, profile changes or daily totals. It MUST NOT persist images, comparison payloads or result bodies in application logs or a result cache.

#### Scenario: Successful comparison leaves consumption unchanged
- **WHEN** a comparison succeeds or fails
- **THEN** existing journal, scan request and profile records remain unchanged, and no comparison record is created

#### Scenario: Logging
- **WHEN** comparison logging is enabled, including upload or validation failures
- **THEN** only operational metadata is recorded; request bodies, result bodies, images, OCR and retrieved context are omitted

### Requirement: Evidence and source preservation
The system SHALL validate each option independently, preserve model_estimate or label_extracted_unverified provenance and keep missing nutrients null. OCR SHALL follow the existing SCANNER_USE_RAW_OCR policy. Image-confirmed corrections MUST use image evidence rather than claim corrected text occurred in raw OCR.

#### Scenario: OCR disabled
- **WHEN** a label request has no OCR and raw OCR usage is disabled
- **THEN** its image remains eligible for analysis without invented nutrient values

#### Scenario: OCR enabled
- **WHEN** a label request lacks OCR while raw OCR usage is enabled
- **THEN** the request is rejected before provider dispatch

#### Scenario: Conflicting or unsupported nutrient
- **WHEN** a proposed nutrient lacks acceptable evidence or conflicts with supplied evidence
- **THEN** that nutrient remains unknown and affected comparison narrative is replaced with a limitation

### Requirement: Explicit comparison basis
The system SHALL support requested basis per_serving, per_100g or per_100ml, defaulting to per_serving. It MUST normalize only from validated compatible references, preserve each option's original serving and distinguish common_basis, as_portioned and unavailable. It MUST NOT infer density, force equal serving mass or invent conversion factors.

#### Scenario: Different servings
- **WHEN** per_serving compares portions with different or unknown mass or volume
- **THEN** both actual portion labels and quantities are shown with as_portioned status and a warning; equal weight or volume is not claimed

#### Scenario: Missing conversion
- **WHEN** per_100g is requested and an option has no validated mass reference
- **THEN** comparison status is unavailable, comparable nutrient values and differences are null, and the original option analyses remain visible

### Requirement: Deterministic nutrient differences
The system SHALL calculate normalized values and B-minus-A differences outside the model for all eight nutrients. Any difference with an unknown operand MUST be null; a real zero MUST remain zero. For per_serving, quantities apply to each chosen serving; per-100 results MUST remain per 100 units regardless of quantities.

#### Scenario: Numeric differences
- **WHEN** normalized A sugar is 12 g and B sugar is 6 g
- **THEN** the returned sugar difference B-minus-A is -6 g

#### Scenario: Unknown and zero
- **WHEN** either protein value is unknown
- **THEN** protein difference is null, while a known zero in either option remains valid numeric data

### Requirement: Personalized explanation without universal winner
The system SHALL return a bounded qualitative summary, advantages/tradeoffs for each option, priority signals, warnings and concise Indonesian ttsSummary. It MUST base numeric differences and directional priority signals on validated calculations, avoid medical or universal healthy-food claims, and replace affected narrative locally without another provider call.

#### Scenario: Conflicting priorities
- **WHEN** B has less sugar but also less protein and both priorities are selected
- **THEN** both directions are shown without assigning an overall universal winner

#### Scenario: Unsafe or invalid summary
- **WHEN** speech exceeds 60 words or 450 characters, contains unsupported claims, or depends on rejected nutrients or unavailable basis
- **THEN** a concise local fallback is returned with ttsSummarySource template

### Requirement: Session-only consumer contract
The response SHALL use the existing success/error envelope and return a complete transient snapshot with no persisted comparison ID or server photo URL. The documented client handoff MUST allow retaining the result during a session for discussion, without claiming an assistant endpoint exists or treating a client-returned snapshot as verified evidence.

#### Scenario: Discuss comparison later in the same session
- **WHEN** the client navigates from comparison to its assistant screen
- **THEN** the documented integration passes the session snapshot, not a database lookup ID; implementing the assistant API remains outside this capability

### Requirement: Scanner compatibility
The system MUST preserve existing scanner requests, idempotency, automatic consumption recording, nutrient validation, portion arithmetic and response schemas when sharing implementation with comparison.

#### Scenario: Existing scan after shared refactor
- **WHEN** an existing valid scanner request is processed
- **THEN** its behavior remains unchanged and its recorded consumption is independent from any comparison
