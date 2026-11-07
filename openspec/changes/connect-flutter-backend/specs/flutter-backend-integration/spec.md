# Spec Delta: Flutter Backend Integration

## Purpose

Menghubungkan frontend Flutter secara langsung ke backend REST API Node.js yang sudah tersedia dengan mengikuti kontrak endpoint `/api/v1` secara persis, mempertahankan ketahanan offline lokal, dan menyajikan 8 nutrisi riil serta personalized pros/cons.

## ADDED Requirements

### Requirement: Validated multipart scan request dispatch
The Flutter frontend SHALL POST scans as multipart/form-data to /api/v1/scans with a UUID Idempotency-Key, image, mode, optional OCR, description and quantity. OCR MUST NOT exceed 20,000 characters and SHALL be required for label mode only when built with SCANNER_USE_RAW_OCR=true. Both 201 Created and 200 OK SHALL be accepted as success.

#### Scenario: Food scan dispatch
- **WHEN** the user takes a food photo and confirms the scan
- **THEN** Flutter sends a `POST /api/v1/scans` multipart request with binary JPEG under 5 MiB, mode "food", optional description, and a UUID Idempotency-Key
- **AND** a 201 response is parsed into a saved entry without triggering a secondary save request

#### Scenario: Label scan with OCR text
- **WHEN** the user scans a food package label with extracted nutrition text
- **THEN** Flutter sends a `POST /api/v1/scans` multipart request containing both the label photo and the raw OCR text string
- **AND** throws a local failure before dispatch if raw OCR text is empty only when built with SCANNER_USE_RAW_OCR=true

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


### Requirement: Image fallback when local OCR is optional
The Flutter frontend SHALL continue preparing label images when local OCR fails, is empty or lacks nutrition keywords unless built with SCANNER_USE_RAW_OCR=true. It MUST preserve image validation, the OCR length limit, and the food-mode gate. Backend vision SHALL read the image in its original single dispatch; quantity calculations SHALL remain deterministic in the backend.

#### Scenario: Local OCR failure
- **WHEN** label OCR fails with a recoverable ScanFailure and required OCR is disabled
- **THEN** Flutter prepares the same image for backend vision without inventing nutrient values or performing another provider request

#### Scenario: Required OCR and oversized text
- **WHEN** required OCR fails or is empty, or any OCR result exceeds 20,000 characters
- **THEN** Flutter rejects the scan locally before resizing or creating a draft
