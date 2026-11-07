# Spec Delta

## Purpose

Memberi jawaban percakapan nutrisi berdasarkan profil, referensi dan catatan konsumsi pengguna, dengan konteks sesi terbatas dan batas bukti yang jelas tanpa menyimpan chat.

## ADDED Requirements

### Requirement: Text conversation endpoint
The system SHALL expose POST `{API_PREFIX}/v1/assistant/messages` accepting JSON with required mode general or pattern, a nonempty message and optional history. It MUST use the existing server-selected development owner and domain response envelope. It MUST reject unknown fields, owner overrides, compare mode or snapshots, images and client-supplied system instructions.

#### Scenario: Valid general question
- **WHEN** the owner submits a general nutrition question with empty or omitted history
- **THEN** the API returns HTTP 200 with reply, sources, warnings, contextSummary, model and promptVersion after successful generation

#### Scenario: Unsupported context
- **WHEN** a request includes mode compare, a comparison snapshot, userId or a system role
- **THEN** the API rejects it before provider dispatch

### Requirement: Bounded session history
The system SHALL accept at most ten history messages forming completed user/assistant pairs, with text at most 2000 characters each. The current message MUST be at most 2000 characters; total submitted text MUST be at most 12000 characters. Blank text MUST be rejected. History MUST remain untrusted conversational context rather than verified nutritional evidence or instructions.

#### Scenario: Follow-up question
- **WHEN** history contains completed pairs followed by a new current question
- **THEN** the provider receives bounded context to interpret the follow-up without relying on hidden provider memory

#### Scenario: Invalid history
- **WHEN** history includes another role, an incomplete pair or excessive text
- **THEN** the API returns HTTP 400 without silently dropping messages or contacting the provider

### Requirement: Request byte limit and private logging
The system SHALL bound assistant JSON requests to 64 KiB including transfers without Content-Length. It MUST omit assistant request bodies, query payloads, responses and retrieved context from development logs, including parser and validation failures. Operational status and duration MUST remain available without changing unrelated route logging.

#### Scenario: Parser failure
- **WHEN** malformed or oversized JSON reaches the assistant path, including case variants and trailing slash
- **THEN** the API returns HTTP 400 or 413 and logs no conversation payload

### Requirement: Read-only personal context
The system SHALL obtain preferences and reviewed references from server-owned data. It MUST exclude identity fields, credentials, height, weight and unrelated private data from provider context. General mode MUST NOT send consumption history or aggregates. All submitted text and retrieved content MUST be treated as data, never privileged instructions.

#### Scenario: General personalization
- **WHEN** a general request is analyzed
- **THEN** only the selected preferences and relevant reviewed references accompany the question and session history

#### Scenario: No source matches
- **WHEN** no reviewed reference matches the question
- **THEN** sources is empty and the response warns about unavailable references without inventing citations or precise unsupported nutrition claims

### Requirement: Complete seven-local-date pattern window
Pattern mode SHALL analyze the current local date and six previous local dates in the profile timezone, ending at the request snapshot time. The response MUST describe the period, timezone, entry count, days with entries and recorded-intake-only scope. It MUST exclude future entries and reject windows exceeding 1000 entries with HTTP 422 PATTERN_LIMIT_EXCEEDED, rather than present a truncated sample as complete.

#### Scenario: Local midnight and daylight saving
- **WHEN** entries occur near local midnight or a daylight-saving transition
- **THEN** each entry is assigned to its correct local date and exactly seven calendar dates are represented

#### Scenario: Large window
- **WHEN** the selected period contains more than 1000 entries
- **THEN** the API returns PATTERN_LIMIT_EXCEEDED before generation and does not claim a complete pattern

### Requirement: Deterministic pattern evidence
The system SHALL compute period and daily nutrient summaries, frequency counts and nutrient contributions for up to five most frequently recorded exact-title groups outside the LLM. It MUST apply stored quantities, preserve units and provenance, expose known and missing counts and keep unknown totals null. A day without records MUST NOT be represented as zero intake or evidence of a safe or complete diet.

#### Scenario: Partial nutrient data
- **WHEN** some records have sugar data and others do not
- **THEN** the known sugar total and missing count are exposed with incomplete status; unknown operands are not converted to zero

#### Scenario: Cold start
- **WHEN** no entries exist in the seven-date window
- **THEN** entry count and days with entries are zero, nutrient totals remain null and the assistant explains insufficient recorded data without inventing patterns

### Requirement: One bounded generation
The system SHALL use a separate assistant prompt and the configured DeepSeek provider for at most one text-only dispatch per accepted request. It MUST enforce a 45-second timeout and bounded output, share the existing two-operation provider capacity and perform no automatic retry or repair call. A new HTTP submission MAY cause a new paid operation; no durable idempotency or replay is promised.

#### Scenario: Provider failure
- **WHEN** the provider fails, times out, returns malformed, truncated or excessive output
- **THEN** the API returns the corresponding 502 or 504 error without a second dispatch

#### Scenario: Disconnect under load
- **WHEN** two provider operations are active and an assistant client disconnects
- **THEN** another operation receives HTTP 429 until an active operation actually finishes; disconnect does not trigger another dispatch

### Requirement: Grounded accessible response
The system SHALL return plain-language Indonesian reply of at most 4000 characters, server-owned cited sources, deterministic warnings and contextSummary. The prompt MUST forbid invented recorded patterns, model-derived food nutrient values, unsupported numeric health limits, diagnosis, treatment and clinical safety guarantees. Numerical nutrition analysis MUST come from supplied structured evidence rather than LLM arithmetic.

#### Scenario: Unsupported health question
- **WHEN** the user asks for a diagnosis, treatment or a safe clinical threshold unsupported by available references
- **THEN** the assistant explains the limitation without fabricating a personal prescription or asserting an intake is medically safe

#### Scenario: Invalid citations or core output
- **WHEN** generated output names an unknown source ID or violates the response schema
- **THEN** the API returns HTTP 502 without exposing raw provider output or issuing a repair call

### Requirement: Stateless compatibility
The system MUST NOT write chat, profiles, consumption, scan operations, comparison results or files. It SHALL return no persisted conversation or message identifier, expose no history CRUD and require no new database schema, AI model or dependency. Existing scanner, comparison, profile and journal contracts MUST remain unchanged; implementing Flutter navigation or chat integration is outside this capability.

#### Scenario: Conversation success or failure
- **WHEN** an assistant request succeeds or fails
- **THEN** existing application data remains unchanged and no chat result is stored or cached by the backend

#### Scenario: Session restart
- **WHEN** the client starts a new session without history
- **THEN** the backend does not claim knowledge of earlier chat turns and retrieves only the server data required by the selected mode
