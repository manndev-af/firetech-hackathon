# AGENTS.md

# Project Development Guidelines — Personalized Nutrition AI

## Hackathon MVP Development Constraints

This project is developed under a limited hackathon timeframe.

Follow these principles:

1. Prefer the simplest working implementation.
2. Do not create unnecessary folders, modules, or abstractions.
3. Do not create empty directories for hypothetical future features.
4. Do not implement enterprise-level architecture unless necessary.
5. Keep backend services simple and modular.
6. Avoid microservices. Use a single Node.js backend.
7. Node.js handles API requests, ONNX inference,
   nutrition calculations, and trade-off analysis.
8. Flutter handles mobile UI, camera, OCR, and TTS.
9. Do not implement authentication, database infrastructure,
   Docker, or CI/CD unless explicitly requested.
10. Prioritize a working end-to-end MVP.
11. Add complexity only when the current implementation
    genuinely requires it.

Do not create all planned directories immediately.
Create files and folders only when implementing their features.

## 1. Project Overview

This project is an AI-powered personalized nutrition application designed to help users understand the nutritional value of food and make better food choices based on their individual nutritional priorities.

The core concept is **Personalized Nutrition Trade-Off**.

The application must not simply identify food or recommend the food with the highest nutritional score. Instead, it should explain the nutritional advantages, disadvantages, and trade-offs of a food relative to the user's personal nutritional goals.

Examples of user priorities:

- Reduce sugar intake.
- Monitor sodium consumption.
- Increase protein intake.
- Manage calorie consumption.
- Improve dietary balance.

The application must provide transparent, evidence-based nutritional information and avoid unsupported health claims.

### Core Processing Pipeline

`Recognize → Verify → Analyze → Optimize → Explain`

1. Recognize the food or extract information from its nutrition label.
2. Verify serving size, portion, and nutritional information.
3. Analyze the nutritional profile against user preferences.
4. Calculate nutritional trade-offs using deterministic rules.
5. Generate an understandable explanation for the user.

---

## 2. Main Application Features

The application has two primary food input modes.

### A. Packaged Food Recognition

Users take a picture of a packaged food nutrition label.

Expected workflow:

1. User captures a nutrition facts label using the smartphone camera.
2. OCR extracts text from the image.
3. The application identifies relevant nutritional fields.
4. Extracted values are normalized into a structured format.
5. User can review and correct the extracted information.
6. The nutrition engine evaluates the product against user preferences.
7. The application displays nutritional trade-offs and recommendations.

Expected nutritional fields:

- Energy / Calories
- Total Fat
- Saturated Fat
- Carbohydrates
- Total Sugar
- Protein
- Sodium
- Fiber, when available
- Serving Size

Important:

- OCR results must not automatically be considered accurate.
- Allow users to verify and correct extracted values.
- Missing nutritional values must remain null, not be replaced with zero.
- Preserve the original serving-size information.
- Clearly distinguish per-serving values from per-100g values.

### B. Unpackaged Food Recognition

Users take a picture of prepared food or an individual food item.

Expected workflow:

1. User captures an image of food.
2. The backend receives the image.
3. The food classification model predicts the food category or dish.
4. The application returns the predicted class and confidence score.
5. User confirms whether the prediction is correct.
6. User confirms or adjusts the estimated portion size.
7. The application retrieves nutritional information from a verified nutrition database.
8. The nutrition engine evaluates the food against user preferences.
9. The application explains the nutritional trade-offs.

Important:

- Food classification and nutritional estimation are different tasks.
- Do not claim that image classification alone can accurately determine calories or nutrients.
- Do not assume that portion weight can be accurately inferred from a single image.
- Portion size must be confirmed by the user unless a separately validated portion-estimation system is implemented.
- Display uncertainty when multiple food classes have similar prediction scores.

---

## 3. Technology Stack

Use the following technologies unless an existing project structure or a documented technical constraint requires a justified alternative.

### Mobile Application

- Flutter
- Dart
- Camera integration
- Google ML Kit Text Recognition for OCR
- Android Text-to-Speech (TTS)
- HTTP client for backend communication

Responsibilities:

- User interface.
- Camera and image capture.
- Nutrition label OCR.
- User profile and nutritional preferences.
- Food prediction display.
- Portion confirmation.
- Nutrition comparison and explanation.
- Text-to-speech accessibility.

### Backend API

- Node.js
- TypeScript
- Express.js
- ONNX Runtime Node.js (`onnxruntime-node`)
- REST API

Responsibilities:

- API endpoints.
- Image upload and validation.
- Food classification inference.
- Nutrition database integration.
- Nutrition calculation.
- Personalized trade-off engine.
- LLM integration for explanations, if configured.
- Data validation and error handling.

### Machine Learning

- Python
- PyTorch
- Pandas
- NumPy
- Pillow
- Scikit-learn
- Torchvision

Responsibilities:

- Dataset exploration and auditing.
- Image preprocessing.
- Dataset splitting.
- Model training and fine-tuning.
- Model evaluation.
- ONNX export.
- Model validation.

### Machine Learning Deployment

The preferred deployment pipeline is:

`PyTorch → ONNX → ONNX Runtime Node.js`

Python is used for model development and training.

Node.js is used for model inference in the backend.

Do not implement model training directly inside the Node.js backend.

---

## 4. Machine Learning Dataset

The initial dataset is:

**Humanbased-AI/MM-Food-100K**

Hugging Face repository:

https://huggingface.co/datasets/Humanbased-AI/MM-Food-100K

The dataset contains approximately 100,000 records.

Expected metadata fields include:

- `image_url`
- `dish_name`
- `food_type`
- `ingredients`
- `portion_size`
- `nutritional_profile`
- `cooking_method`
- `food_prob`

The dataset must be audited before training.

### Dataset Preparation Requirements

1. Inspect the CSV schema.
2. Analyze the number of unique food classes.
3. Analyze class distribution.
4. Identify missing values.
5. Identify duplicate image URLs.
6. Validate downloaded images.
7. Identify corrupted or unreadable images.
8. Inspect label consistency.
9. Identify potential class imbalance.
10. Create reproducible train, validation, and test splits.

### Dataset Strategy

Do not immediately train using all 100,000 records.

Start with a manageable subset and expand based on actual evaluation results.

Recommended initial approach:

- Start with approximately 5,000 images for pipeline testing.
- Expand to 10,000–20,000 images for the initial training experiment.
- Expand further if the model benefits from additional data.

The number of classes must be selected based on dataset quality and class distribution.

Prefer a smaller number of well-represented classes with reliable evaluation results over a large number of poorly represented classes.

### Dataset Integrity

- Never silently modify original labels.
- Keep raw data separate from processed data.
- Keep a record of excluded images and the reasons for exclusion.
- Prevent data leakage between training, validation, and test sets.
- Do not assume `portion_size` or `nutritional_profile` represents verified ground truth.
- Verify the dataset license and usage restrictions before redistribution or commercial deployment.

---

## 5. Machine Learning Model Requirements

The initial objective is food image classification, not full multimodal nutritional estimation.

Use transfer learning rather than training a deep learning model from scratch.

Candidate architectures:

- MobileNetV3
- EfficientNet-B0
- ResNet50

Select the architecture based on:

- Classification performance.
- Model size.
- Inference latency.
- Memory consumption.
- ONNX compatibility.

### Model Evaluation

Every trained model must be evaluated using:

- Accuracy
- Precision
- Recall
- F1-score
- Confusion matrix
- Per-class performance

Do not report training accuracy as model performance.

Use the independent test set for final evaluation.

The model must also return confidence information.

Do not present low-confidence predictions as certain results.

### ONNX Export Requirements

The exported model must include:

- ONNX model file.
- Class label mapping.
- Input dimensions.
- Image preprocessing configuration.
- Normalization parameters.
- Model version.
- Evaluation metrics.

Ensure that Python and Node.js use identical preprocessing logic.

Validate ONNX predictions against the original PyTorch model using the same test images.

Do not assume that a successful ONNX export automatically guarantees correct inference.

---

## 6. Nutrition Data and Calculation Engine

The nutrition engine is a critical component of the application.

Use structured and traceable nutritional data.

Potential nutrition data sources:

- Open Food Facts
- USDA FoodData Central
- Indonesian food composition references (TKPI), where accessible and appropriately licensed.

Every nutrition record should preserve its source and reference basis.

Recommended nutritional data structure:

```json
{
  "food_name": "Example Food",
  "source": "nutrition_database",
  "serving_size": 100,
  "serving_unit": "g",
  "nutrients": {
    "calories_kcal": 150,
    "protein_g": 5,
    "total_fat_g": 4,
    "saturated_fat_g": 1,
    "carbohydrates_g": 24,
    "sugar_g": 8,
    "sodium_mg": 120,
    "fiber_g": 3
  }
}
```

This is an example schema, not actual nutritional data.

### Calculation Rules

- Implement nutritional calculations using deterministic TypeScript functions.
- Do not delegate arithmetic to an LLM.
- Normalize serving sizes before comparing products.
- Allow comparison per serving or per 100g.
- Preserve units consistently.
- Handle missing values explicitly.
- Do not interpret missing values as zero.
- Validate calculated values before returning them.

### Personalized Nutrition Trade-Off Engine

The engine must compare food nutritional values against user-defined priorities.

For example:

A user prioritizes:

- Lower sugar.
- Higher protein.
- Moderate calories.

The engine should identify:

- Nutritional advantages.
- Nutritional disadvantages.
- Which user priorities are satisfied.
- Which priorities are not satisfied.
- Relevant trade-offs.

Do not create a universal healthy-food score that ignores user preferences.

Keep scoring rules transparent, configurable, and testable.

Do not present the result as a medical diagnosis or individualized clinical prescription.

---

## 7. LLM Integration

An LLM may be used to explain nutritional analysis in natural language.

The LLM is not the source of truth for nutritional values.

The correct architecture is:

`Verified Nutrition Data → Deterministic Calculation → Trade-Off Results → LLM Explanation`

The LLM receives structured calculation results and converts them into understandable explanations.

Example input:

```json
{
  "user_priorities": ["low_sugar", "high_protein"],
  "food": {
    "name": "Example Food",
    "sugar_g": 12,
    "protein_g": 18
  },
  "analysis": {
    "advantages": ["high_protein"],
    "disadvantages": ["relatively_high_sugar"]
  }
}
```

The LLM must:

- Explain the supplied results.
- Avoid inventing nutritional values.
- Avoid changing calculated scores.
- Clearly mention missing data.
- Avoid unsupported medical claims.
- Use understandable language.
- Explain trade-offs instead of giving absolute judgments.

If the LLM service is unavailable, the application must still be able to display the deterministic nutritional analysis.

---

## 8. Recommended Project Structure

Use the repository's existing top-level `app/` and `server/` projects. Keep the Flutter app at `app/` and the Node.js backend at `server/`; each project has its own `README.md` for local setup and commands. Do not nest these projects under hypothetical `app/mobile/` or `app/api/` folders.

For tasks in either subproject, read its local README. If generated starter-template instructions conflict with this repository's MVP constraints or product requirements, follow this `AGENTS.md` and the project documentation.

```text
project-root/
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── app/                         # Flutter project; preserve generated layout
│   ├── README.md                # App-specific setup and run instructions
│   ├── android/                 # Currently enabled platform scaffold
│   ├── lib/
│   │   └── main.dart
│   ├── test/
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   └── pubspec.lock
├── server/                      # Node.js + TypeScript backend
│   ├── README.md                # Backend-specific setup and run instructions
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── types/
│   │   ├── utils/
│   │   ├── validation/
│   │   ├── app.ts
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
└── docs/
    ├── SUMMARY.md
    ├── PRD.md
    ├── FRD.md
    └── architecture.md
```

The `app/` and `server/` entries reflect the current repository layout. `app/` follows the generated Flutter project structure; retain its scaffold and place app-specific code under `lib/`. Do not invent platform folders or reorganize the scaffold without need. Nutrition-specific server modules and a separate ML training structure are future work; add them only when implementing those features.

Inspect the existing repository before creating directories or moving files. Preserve existing work and avoid unnecessary restructuring.

---
## 9. API Design

Use versioned REST endpoints.

Initial endpoint suggestions:

| Method | Endpoint                    | Purpose                                |
| ------ | --------------------------- | -------------------------------------- |
| GET    | `/api/v1/health`            | API health check                       |
| POST   | `/api/v1/food/classify`     | Classify food image                    |
| POST   | `/api/v1/nutrition/analyze` | Analyze nutritional values             |
| POST   | `/api/v1/nutrition/compare` | Compare food products                  |
| POST   | `/api/v1/label/parse`       | Process extracted nutrition label text |
| POST   | `/api/v1/tradeoff/analyze`  | Calculate personalized trade-offs      |

These are proposed interfaces and must be documented before implementation.

Use consistent response structures.

Example:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

For errors:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_IMAGE",
    "message": "The uploaded image could not be processed."
  }
}
```

Validate all incoming data.

Apply file size limits, MIME-type validation, and safe image decoding.

Do not expose stack traces, API keys, or internal server details in production responses.

---

## 10. Development Principles

All AI agents working on this project must follow these rules.

### Before Making Changes

1. Inspect the existing project structure.
2. Read this AGENTS.md file.
3. Identify existing dependencies and configurations.
4. Identify completed and incomplete components.
5. Explain the proposed implementation plan.
6. Avoid overwriting existing files without inspection.

### During Development

- Use modular and maintainable code.
- Prefer TypeScript for backend development.
- Use clear naming conventions.
- Separate business logic from controllers.
- Keep ML training code separate from inference code.
- Use environment variables for configuration.
- Implement proper error handling.
- Add meaningful comments where necessary.
- Avoid unnecessary dependencies.
- Avoid duplicated business logic.
- Keep API contracts consistent.
- Implement logging without exposing sensitive information.

### Testing

Every important feature must have tests.

Prioritize:

- Nutrition calculation tests.
- Serving-size conversion tests.
- Missing-value handling tests.
- Trade-off engine tests.
- API validation tests.
- Image preprocessing tests.
- PyTorch versus ONNX inference consistency tests.

Do not claim a feature is complete without testing it.

### Documentation

Update documentation when:

- Adding a new module.
- Changing API contracts.
- Changing model architecture.
- Changing dataset preparation.
- Changing environment variables.
- Changing setup or deployment procedures.

---

## 11. Security and Data Management

- Never commit `.env` files.
- Never hardcode API keys.
- Keep `.env.example` updated.
- Add datasets, downloaded images, temporary files, and large model artifacts to `.gitignore`.
- Do not upload the entire dataset to Git.
- Do not expose development API ports publicly without authorization.
- Validate uploaded images before processing.
- Set appropriate upload and request limits.
- Do not store personal information unnecessarily.
- Do not send user-sensitive information to an external LLM without an explicit and documented need.

---

## 12. Performance Requirements

The application should prioritize a responsive user experience.

- Avoid loading the entire dataset into memory unnecessarily.
- Use batch processing during model training.
- Use asynchronous I/O for backend operations where appropriate.
- Avoid blocking the Node.js event loop with CPU-intensive operations.
- Benchmark ONNX inference performance.
- Keep image preprocessing consistent.
- Resize images before inference according to the model configuration.
- Avoid unnecessarily large API responses.
- Cache suitable static nutrition reference data when appropriate.

Do not optimize prematurely without profiling.

---

## 13. Implementation Roadmap

AI agents should implement the project incrementally.

### Phase 1 — Project Foundation

- Inspect the repository.
- Initialize the monorepo structure.
- Set up Flutter application.
- Set up Node.js TypeScript backend.
- Set up Python ML environment.
- Configure environment variables.
- Create README and initial architecture documentation.
- Verify that all components can run independently.

### Phase 2 — Dataset Preparation

- Inspect MM-Food-100K metadata.
- Validate image downloads.
- Analyze class distribution.
- Clean and organize the dataset.
- Create reproducible data splits.
- Generate dataset statistics.

### Phase 3 — Food Classification Model

- Select a pretrained architecture.
- Implement training and validation pipelines.
- Fine-tune on selected food categories.
- Evaluate the model.
- Export the best model to ONNX.
- Validate ONNX inference.

### Phase 4 — Backend Integration

- Implement API foundation.
- Integrate ONNX Runtime.
- Implement image preprocessing.
- Implement food classification endpoint.
- Integrate nutrition reference data.
- Implement deterministic nutrition calculations.
- Implement trade-off engine.

### Phase 5 — Mobile Integration

- Implement camera functionality.
- Integrate OCR.
- Connect Flutter to backend APIs.
- Implement food prediction confirmation.
- Implement serving-size confirmation.
- Display nutrition analysis.
- Integrate text-to-speech.

### Phase 6 — LLM Explanation and Finalization

- Integrate LLM explanation service.
- Implement fallback explanations.
- Test the complete user workflow.
- Fix integration issues.
- Measure inference latency.
- Document limitations and evaluation results.
- Prepare the final demonstration.

Do not attempt to implement every phase in one large operation.

Complete and test each phase before moving to the next.

---

## 14. Hackathon Development Priorities

This project is intended to be developed within a limited hackathon timeframe.

Prioritize a functional end-to-end MVP over excessive features.

The most important demonstration flow is:

1. User scans a food image.
2. AI recognizes the food.
3. User confirms the food and portion size.
4. Application retrieves nutritional information.
5. User selects personal nutritional priorities.
6. The nutrition engine calculates trade-offs.
7. The application explains the result.
8. The user can listen to the explanation using TTS.

A working vertical slice is more valuable than multiple incomplete modules.

If a feature is too complex for the available time, implement a clearly documented simplified version.

Never fake model accuracy, nutritional data, or completed functionality for demonstration purposes.

---

## 15. Instructions for AI Coding Agents

When asked to set up or develop this project:

1. Treat this document as the primary project guideline.
2. Inspect the existing code before making changes.
3. Follow the defined technology stack unless there is a technical reason to change it.
4. Explain major architectural decisions.
5. Work incrementally.
6. Do not generate unnecessary boilerplate.
7. Do not replace working components without justification.
8. Do not fabricate dataset contents, model metrics, or nutritional references.
9. Do not assume that downloaded images are all valid.
10. Do not assume that a model is production-ready simply because it runs.
11. Run relevant tests after implementation.
12. Report completed tasks, modified files, test results, and remaining issues.

If requirements are ambiguous, ask for clarification before making irreversible decisions.

If a technical limitation is discovered, explain it and propose the simplest viable alternative.

**Primary objective: Build a functional, reliable, explainable, and demonstrable Personalized Nutrition Trade-Off application.**

---

## NutriLens AI Documentation Context

Before any NutriLens AI development task, read this `AGENTS.md` and the relevant project documents. Use [docs/SUMMARY.md](docs/SUMMARY.md) as the primary product context (including its dated addendum), [docs/PRD.md](docs/PRD.md) for product goals/scope, [docs/FRD.md](docs/FRD.md) for functional requirements and acceptance criteria, and [docs/architecture.md](docs/architecture.md) for component responsibilities and data flow. Consult [README.md](README.md) for the documentation index. Do not assume a proposed API, class list, dataset size/split, nutrient value, or metric is finalized unless the documents explicitly say so.

### Changelog workflow

- Read [CHANGELOG.md](CHANGELOG.md) before making changes that may need an entry.
- For each task that changes product behavior, user-facing functionality, API/contracts, data/model behavior, setup/dependencies, security/privacy, or material project documentation, add a concise entry under `## [Unreleased]` in `CHANGELOG.md` in the same task.
- Use the categories `Added`, `Changed`, `Fixed`, `Removed`, and `Security` as applicable. Create only categories that have entries, except that the initial template may show empty categories.
- Describe the user or project impact, not implementation minutiae. Do not claim work is complete if it is only proposed; distinguish implemented changes from planned work.
- Keep newest unreleased items at the top. Do not invent release versions or dates. When the team makes a release, move the relevant entries into a dated version section and follow Semantic Versioning.
- Skip trivial formatting, typo-only, and purely internal refactors with no observable effect. Do not add an entry solely because `CHANGELOG.md` itself was edited.
- Before finishing a qualifying task, verify the changelog entry matches the actual diff and mention the changelog update in the completion report.

### Current Nutrition Profile direction

- Profile information may include age/age range, food preferences, and multiple nutrition priorities: Sugar Awareness, Sodium Awareness, Protein Intake, Calorie Awareness, and Balanced Nutrition.
- Height and weight are optional; food allergy information may be optional; physical activity is a later enhancement.
- Medical history and medications are outside the MVP. Do not build diagnosis, doctor consultation, treatment recommendations, or medication/dosage changes.
- Profile personalization can change explanation focus, comparisons, and alternatives. It must not modify the source nutrient values of a food.
- Use verifiable nutrition sources and deterministic Nutrition Engine calculations. Missing values remain unknown, not zero. An LLM may explain structured results only; it is neither the nutrition calculator nor a medical authority.
- The current model direction is MobileNetV3-Large trained/fine-tuned with PyTorch on an audited subset of MM-Food-100K. Its output is food class/top-k/confidence only. Users confirm food identity and portion; portion units and conversions come from structured configuration, not free-form LLM output.

If this current direction conflicts with earlier brainstorming elsewhere in the summary, preserve the historical text, identify the conflict, and ask the team to settle product or implementation decisions before encoding assumptions. Prioritize an end-to-end MVP and do not silently promote recommendations into commitments.
