# Spec Delta

## Purpose

Menyediakan pemilik tetap dan profil nutrisi untuk pengujian backend scanner pada development tanpa mengimplementasikan login produksi.

## ADDED Requirements

### Requirement: Repeatable development seed
The system SHALL seed one development user with a unique email, salted password hash, and nutrition profile. Development seed passwords MUST contain 5-128 characters. Repeating the seed MUST preserve existing profile edits and journal records. Plaintext passwords MUST NOT enter database records, API responses, or logs. Confidential credentials MUST NOT enter tracked configuration; .env.example MAY contain explicitly public development-only dummy credentials.

#### Scenario: Seed repeated
- **WHEN** development seed runs twice with the same email
- **THEN** exactly one user and profile exist and existing journal entries and profile preferences remain intact

#### Scenario: Seed credentials absent or production
- **WHEN** required seed credentials are missing or the seed runs in production
- **THEN** the seed fails before changing the database

#### Scenario: Development password boundaries
- **WHEN** the configured password has fewer than 5 or more than 128 characters
- **THEN** seed fails before database access, while passwords of 5 and 128 characters pass length validation

### Requirement: Server-selected development owner
The system SHALL resolve the configured dummy user on the server and reject client-supplied ownership selectors. Dummy identity routes MUST be disabled outside explicit development/test mode and SHALL NOT expose login endpoints or production authentication claims.

#### Scenario: Client selects another user
- **WHEN** a scanner or profile request supplies another user ID or ownership header
- **THEN** the request is rejected without reading or writing another user's data

#### Scenario: Dummy identity disabled
- **WHEN** dummy mode is disabled or the selected user does not exist
- **THEN** domain requests fail without calling DeepSeek or falling back to an arbitrary user

### Requirement: Persistent nutrition profile
The system SHALL expose the current owner's name, age, heightCm, weightKg, preference, priorities, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies, audioAnalysisEnabled, and valid IANA timezone. Frontend field names and supported option values MUST round-trip without loss. No medical history, medication advice, or inferred clinical targets SHALL be introduced.

#### Scenario: Profile update affects future context
- **WHEN** the owner's sugar priority is changed
- **THEN** subsequent scans use the updated priority and previously recorded source nutrient values remain unchanged

#### Scenario: Complete frontend profile round-trip
- **WHEN** a profile containing every supported field is saved and subsequently fetched
- **THEN** numeric values, nullable choices, multiple priorities/allergens, custom allergy text and audio settings are preserved with the frontend's field names

### Requirement: Optional identity validation
The system SHALL accept a trimmed name of at most 60 characters, nullable integer age from 1 to 120, nullable finite heightCm greater than zero up to 300, and nullable finite weightKg greater than zero up to 700. Empty identity fields MUST remain empty or null and MUST NOT become invented numeric zeros.

#### Scenario: Clear optional information
- **WHEN** name is set to an empty string and age, heightCm and weightKg to null
- **THEN** the fields clear successfully while personal preferences, allergies and audio settings remain unchanged

#### Scenario: Invalid identity values
- **WHEN** age is fractional, heightCm is zero or above 300, weightKg exceeds 700, or a numeric input is not finite
- **THEN** the patch is rejected without partially changing the profile

### Requirement: Frontend choice vocabulary
The system SHALL accept only the existing frontend choices for priorities, preference, eatingPattern and allergies, with unique items for arrays. Preference and eatingPattern MUST remain independent nullable single choices. PrefersHalal MUST be a boolean preference, not a halal certification claim.

#### Scenario: Distinct food choices
- **WHEN** preference is Masakan rumahan and eatingPattern is Vegetarian
- **THEN** both values survive independently and clearing preference does not clear eatingPattern

#### Scenario: Unsupported or duplicated choice
- **WHEN** a request contains an unknown priority or duplicate allergy choices
- **THEN** the entire patch is rejected with a validation error

### Requirement: Section-preserving partial updates
The system SHALL preserve omitted PATCH fields. Identity-only and settings-only updates MUST succeed without nutrition priorities. Updates containing personalization fields MUST leave at least one valid priority after merging. Initial profiles SHALL be allowed to have no priorities, and scanning MUST NOT invent a default priority.

#### Scenario: Identity saved before personalization
- **WHEN** name and age are updated on a profile with empty priorities
- **THEN** the update succeeds and priorities remain empty

#### Scenario: Invalid personalization update
- **WHEN** a personalization patch leaves priorities empty
- **THEN** the patch fails atomically without changing identity, personalization or settings

### Requirement: Three-state allergy information
The system SHALL preserve unknown, noneKnown and listed allergy states. Listed MUST contain at least one supported allergen or trimmed otherAllergies text of at most 120 characters. Changing to unknown or noneKnown MUST clear stored allergy details atomically; explicit contradictory nonempty details MUST be rejected.

#### Scenario: Clear previously listed allergies
- **WHEN** a patch switches listed to noneKnown and omits ingredient fields
- **THEN** allergies becomes an empty array and otherAllergies an empty string, without changing priorities

#### Scenario: Only custom allergen supplied
- **WHEN** the merged profile has listed, no predefined allergens, otherAllergies set to Wijen, and a valid priority
- **THEN** it is accepted without requiring a predefined allergen

#### Scenario: Unknown is not allergy free
- **WHEN** allergyStatus is unknown or food ingredient information is incomplete
- **THEN** the API and generated context do not represent the food as allergen-free

### Requirement: Independent audio preference and complete demo seed
The system SHALL persist audioAnalysisEnabled independently of nutritional personalization, with the schema default remaining false. Development seed profiles MUST contain explicitly fictional demo values for all editable profile fields, without null values, including body information, food priorities, allergy details, audio preference and a documented timezone. These fixture values MUST NOT be inferred for real users. Persisting audio SHALL NOT imply server TTS support.

#### Scenario: Complete development fixture
- **WHEN** seed creates a new dummy profile
- **THEN** every editable profile field is populated with a valid non-null demo value, and the fixture is documented as fictional

#### Scenario: Audio toggle on an incomplete profile
- **WHEN** only audioAnalysisEnabled is changed to true while priorities is empty
- **THEN** it persists across backend restarts and other profile fields remain unchanged

#### Scenario: Seed preserves edited audio and identity
- **WHEN** seed is rerun after a user updates name, measurements and audio
- **THEN** those fields are not reset to initial defaults
