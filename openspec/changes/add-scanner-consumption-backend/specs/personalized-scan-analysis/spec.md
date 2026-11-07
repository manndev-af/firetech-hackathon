# Spec Delta

## Purpose

Menghasilkan analisis scan personal melalui retrieval konteks yang dapat ditelusuri dan satu panggilan multimodal dengan batas input/output yang jelas.

## ADDED Requirements

### Requirement: Validated multimodal scan input
The system SHALL accept food or label mode, one decodable bounded image, optional description, and raw OCR required for label mode only when SCANNER_USE_RAW_OCR=true (default false). It MUST reject unsupported files, invalid metadata, excessive bytes/pixels, and ownership overrides before any provider call. Remote image URLs SHALL NOT be accepted as uploads.

#### Scenario: Label scan
- **WHEN** SCANNER_USE_RAW_OCR=true and a valid label image and nonempty raw OCR are submitted
- **THEN** the same provider request includes the image, OCR, and optional description

#### Scenario: Image-only label analysis
- **WHEN** SCANNER_USE_RAW_OCR is false or absent and a valid label image is submitted
- **THEN** OCR is optional and excluded from retrieval text, provider input and evidence matching; supplied OCR remains stored and fingerprinted, and the prompt requests image-origin evidence

#### Scenario: Invalid upload
- **WHEN** an image is oversized, undecodable, or misrepresented as an accepted type
- **THEN** the API returns a documented input error with no provider call and no consumption entry

#### Scenario: Bounded provider image dimensions
- **WHEN** a valid image is accepted in either mode
- **THEN** the backend corrects orientation and creates a 1600 x 1600 JPEG preserving aspect ratio with white padding and no cropping, while including label OCR text in the same provider request only when SCANNER_USE_RAW_OCR=true

### Requirement: Relevant bounded retrieval
The system SHALL retrieve the owner's current profile, prior consumption context, and relevant reviewed references before generation. It MUST retain source identifiers, time boundaries, and missing-data counts. Retrieval MUST exclude other owners and the current scan and MUST NOT require another generative-model call.

#### Scenario: Personalized context
- **WHEN** a user with sugar priority scans a drink described in OCR or additional text
- **THEN** context includes that priority, prior recorded sugar with completeness information, and matching reviewed references within the configured context budget

#### Scenario: Cold start
- **WHEN** no history or matching reference exists
- **THEN** context explicitly reports the absence without fabricated history, citations, or retrieval results

#### Scenario: Profile context follows actual application fields
- **WHEN** the owner has food preferences, an eating pattern, halal preference and listed allergy ingredients
- **THEN** retrieval preserves their distinct meanings and only supplies relevant personalization fields, without converting preferences into certifications or ingredient safety guarantees

### Requirement: Single provider invocation
The system SHALL make at most one DeepSeek request per unique accepted scan operation, combining image, text, and retrieved context. It MUST NOT perform automatic retries, repair calls, follow-up tool calls, or invoke the provider when only the consumed quantity changes.

#### Scenario: Invalid provider response or timeout
- **WHEN** the provider times out or returns unusable structured output
- **THEN** the API returns a documented failure without a second provider call or fabricated consumption entry

#### Scenario: Configured compatible provider
- **WHEN** a valid DEEPSEEK_BASE_URL is configured with a provider key and vision model
- **THEN** the backend appends /chat/completions to that base URL, preserving its optional base path, and never requires Flutter to receive provider credentials

### Requirement: Explicit nutritional provenance
The system SHALL validate output schema, relevance, finite nonnegative nullable nutrients, portion basis, units, and cited source IDs. Photo-derived nutrients MUST be labeled model estimates; label-derived values MUST remain unverified extraction until reviewed. Personal priorities MUST NOT alter source nutrient values.

#### Scenario: Missing or conflicting label information
- **WHEN** the label or OCR omits a nutrient or contains unresolved contradictory values
- **THEN** the nutrient remains null with an uncertainty warning, not a guessed value or zero

#### Scenario: Invalid citations or nonfood
- **WHEN** output cites a reference not supplied or cannot establish relevant food/nutrition-label content
- **THEN** it is rejected or returned as requiring rescan without creating a consumption entry

### Requirement: Portion-independent generated insight
The system SHALL treat generated insight as qualitative context at scan time and keep quantity-dependent totals and statements in deterministic calculations. It MUST NOT present an old daily-context observation as a continuously updated assessment or claim a universal healthy-food score.

#### Scenario: Consumer reads personalized pros and cons
- **WHEN** an entry is serialized for scan, list, detail or quantity correction
- **THEN** pros and cons arrays expose the stored advantages and tradeoffs, with prompt instructions to relate them to the supplied user priorities and available retrieval; insufficient evidence is explained without inventing benefits or drawbacks

#### Scenario: Portion quantity changes
- **WHEN** consumption quantity is updated
- **THEN** totals change without another DeepSeek call and no stale quantity-specific generated claim is presented as current

### Requirement: Minimal external disclosure
The system SHALL send only the image, supplied scan text, relevant preferences, bounded history context, and selected references required for analysis. It MUST exclude passwords, email, unrelated personal data, and raw private payloads from logs. Uploaded images SHALL be temporary and inputs SHALL be treated as untrusted data, not instructions.

#### Scenario: Prompt instructions inside OCR
- **WHEN** OCR text contains instructions to override the system prompt or invent nutrients
- **THEN** it is treated as label data and the response remains subject to the same schema, source, and relevance validation

#### Scenario: Stored identity is excluded from generation
- **WHEN** the profile has name, age, heightCm, weightKg and audioAnalysisEnabled populated
- **THEN** those fields are excluded from the provider payload and no BMI, calorie target or weight target is inferred from them

### Requirement: Concise spoken summary

The system SHALL request an Indonesian plain-text ttsSummary within the same DeepSeek analysis response. It MUST contain 2-3 short sentences, at most 60 words and 450 characters, emphasizing one supported personalized insight and a relevant trade-off when available. It MUST preserve material uncertainty and avoid exhaustive nutrient lists, markup, medical claims and quantity-dependent totals.

#### Scenario: Speech understandable to nonexperts
- **WHEN** the prompt requests a summary for audio playback
- **THEN** it requests friendly everyday Indonesian, short sentences and kamu rather than formal report wording, explaining relevant nutritional terms without jargon or invented user goals/benefits

#### Scenario: Speech summarizes personalized pros and cons
- **WHEN** a scan has supported advantages and tradeoffs for the retrieved user context
- **THEN** the prompt requests speech summarizing the main pro and con for that user, with brief nutrient context if useful, without adding unsupported claims; invalid speech attempts an insight-derived local summary before the uncertainty template

#### Scenario: Successful analysis with audio disabled
- **WHEN** a valid food or label scan completes while audioAnalysisEnabled is false
- **THEN** the saved entry still contains ttsSummary and ttsSummarySource so later audio playback requires no new provider call

#### Scenario: Limited evidence
- **WHEN** the analysis cannot support a benefit or trade-off
- **THEN** the summary briefly explains the uncertainty instead of inventing an advantage or filling a required praise/criticism pair

### Requirement: Local summary fallback
The system SHALL use a concise local template if an otherwise valid analysis has a missing, empty, oversized or invalid-format ttsSummary. It MUST mark ttsSummarySource as template, preserve the valid consumption entry, and avoid a second model call. Invalid core analysis SHALL still fail the scan.

#### Scenario: Summary alone exceeds limits
- **WHEN** valid analysis returns a summary longer than the documented limits
- **THEN** the backend substitutes a complete short template rather than truncating speech mid-sentence or invoking DeepSeek again

### Requirement: Spoken summary survives portion changes
The system SHALL persist ttsSummary and its source with the entry and return them in scan, detail and quantity-update responses. The summary MUST avoid serving totals and daily-limit judgments that become stale after quantity edits. Backend audio generation and playback SHALL remain outside this capability.

#### Scenario: User corrects the portion
- **WHEN** the entry quantity is updated
- **THEN** the response includes recalculated nutrient totals and the quantity-independent summary without another provider call


### Requirement: Label serving and evidence normalization
The system SHALL normalize new per_serving label portions expressed in grams or millilitres to one porsi, preserving the original serving text and reference mass/volume. Existing stored entries and per-100 bases SHALL remain unchanged.

#### Scenario: Twenty-gram serving
- **WHEN** the provider returns 100 kcal per serving with baseQuantity 20 and unitCode g
- **THEN** the backend returns baseQuantity 1 and unitCode porsi with referenceWeightG 20, and quantity 2 yields 200 kcal deterministically

#### Scenario: Energy and OCR evidence
- **WHEN** a label contains total energy 100 kcal, energy from fat 45 kcal and daily reference 2150 kcal
- **THEN** the backend retains supported total energy 100, accepts whitespace-only OCR variations, and invalidates unsupported nutrients and their generated insights/speech on actual conflicts
