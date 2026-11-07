# Spec Delta: Flutter Backend Integration

## Purpose

Menghubungkan frontend Flutter secara langsung ke backend REST API Node.js yang sudah tersedia dengan mengikuti kontrak endpoint `/api/v1` secara persis, mempertahankan ketahanan offline lokal, dan menyajikan 8 nutrisi riil serta personalized pros/cons.

## ADDED Requirements

### Requirement: Validated multipart scan request dispatch
The Flutter frontend SHALL dispatch scan requests to `POST /api/v1/scans` as `multipart/form-data` with an `Idempotency-Key` UUID header. The request MUST include the image binary as field `image`, `mode` (`food` or `label`), `rawOcrText` (mandatory for label mode), optional `description` (user note), and optional `quantity`. The client MUST accept both `201 Created` (new entry) and `200 OK` (idempotent replay) as successful responses.

#### Scenario: Food scan dispatch
- **WHEN** the user takes a food photo and confirms the scan
- **THEN** Flutter sends a `POST /api/v1/scans` multipart request with binary JPEG under 5 MiB, mode "food", optional description, and a UUID Idempotency-Key
- **AND** a 201 response is parsed into a saved entry without triggering a secondary save request

#### Scenario: Label scan with OCR text
- **WHEN** the user scans a food package label with extracted nutrition text
- **THEN** Flutter sends a `POST /api/v1/scans` multipart request containing both the label photo and the raw OCR text string
- **AND** throws a local failure before dispatch if raw OCR text is empty

### Requirement: Explicit 8-nutrient and personalized insight mapping
The Flutter frontend SHALL map the backend `entrySchema` response into `ScanHistoryEntry`, including all 8 nutrients (`calories_kcal`, `protein_g`, `total_fat_g`, `saturated_fat_g`, `carbohydrates_g`, `sugar_g`, `sodium_mg`, `fiber_g`), `pros`, `cons`, `ttsSummary`, `ttsSummarySource`, and `provenance`. Null nutrient values MUST be preserved as null ("Belum diketahui") and MUST NOT be converted to zero. Synthetic regex heuristics and hardcoded placeholder texts in the UI MUST NOT be used when backend data is available.

#### Scenario: Mapping nutrients and qualitative insight
- **WHEN** the backend returns a successful scan response
- **THEN** Flutter populates `ScanHistoryEntry` with `data.title`, structured portion display label, all 8 nullable nutrients, `data.pros`, `data.cons`, and `data.ttsSummary`
- **AND** the UI renders the advantages card from `pros.join('\n')` and trade-offs card from `cons.join('\n')`

### Requirement: Deterministic portion quantity update
When the user adjusts portion servings on an analyzed food entry, Flutter SHALL invoke `PATCH /api/v1/food-entries/:id/quantity` with the updated quantity value and update the local state with the returned recalculated nutrients and portion basis.

#### Scenario: Quantity adjustment
- **WHEN** the user changes the portion stepper from 1 to 2
- **THEN** Flutter sends `PATCH /api/v1/food-entries/{id}/quantity` with `{"quantity": 2.0}`
- **AND** updates the displayed nutrients with the backend-recalculated totals

### Requirement: Two-way profile & audio setting synchronization
The Flutter frontend SHALL synchronize user nutrition profile data and audio preference with `GET /api/v1/profile` and `PATCH /api/v1/profile`. Profile edits MUST be sent as partial group updates (identity, personalization, or settings) matching backend validation rules, while updating the local cache.

#### Scenario: Profile edit sync
- **WHEN** the user saves changes in Nutrition Profile Screen
- **THEN** Flutter sends a `PATCH /api/v1/profile` JSON request with only the modified fields
- **AND** persists the updated profile to local storage

#### Scenario: Audio toggle sync
- **WHEN** the user toggles the audio analysis switch in Profile
- **THEN** Flutter sends `PATCH /api/v1/profile` with `{"audioAnalysisEnabled": true/false}` and updates `analysisAudioSession`

### Requirement: Journal and daily summary backend synchronization with offline resilience
The Flutter frontend SHALL synchronize consumption history with `GET /api/v1/food-entries` and daily nutrition totals with `GET /api/v1/nutrition/daily`. When deletion is requested, Flutter SHALL invoke `DELETE /api/v1/food-entries/:id` (expecting 204 No Content). When network connectivity is unavailable, the application MUST seamlessly fall back to local storage without crashing.

#### Scenario: Daily summary retrieval
- **WHEN** the user opens Dashboard
- **THEN** Flutter requests `GET /api/v1/nutrition/daily?date=YYYY-MM-DD` in the user's local profile timezone
- **AND** displays the recorded intake metrics and completeness indicators
