import { compareMetadataSchema, maxCompareBytes, maxMetadataBytes } from '../middleware/compareUpload';
import { analysisSchema } from '../services/deepseek.service';
import { nutrients } from '../validation/nutrition';
import { openapiSchema, errorResponse, errors, success } from './nutrition.openapi';

const text = { type: 'string' };
const list = { type: 'array', items: text };
const values = { type: 'object', additionalProperties: false, required: [...nutrients],
  properties: Object.fromEntries(nutrients.map(key => [key, { type: 'number', nullable: true, description: key === 'calories_kcal' ? 'kcal' : key === 'sodium_mg' ? 'mg' : 'g' }])) };
const item = { type: 'object', additionalProperties: false,
  required: ['title', 'mode', 'quantity', 'portion', 'baseNutrients', 'nutrients', 'evidence', 'provenance', 'pros', 'cons', 'warnings'],
  properties: { title: text, mode: { type: 'string', enum: ['food', 'label'] }, quantity: { type: 'number', minimum: 0.000001, maximum: 10000 },
    portion: openapiSchema(analysisSchema.properties.portion), baseNutrients: values, nutrients: values,
    evidence: openapiSchema(analysisSchema.properties.evidence),
    provenance: { type: 'string', enum: ['model_estimate', 'label_extracted_unverified'] }, pros: list, cons: list, warnings: list } };
const reference = { type: 'object', additionalProperties: false, required: ['quantity', 'displayLabel', 'weightG', 'volumeMl'], properties: {
  quantity: { type: 'number' }, displayLabel: text, weightG: { type: 'number', nullable: true }, volumeMl: { type: 'number', nullable: true },
} };
const fixtureValues = (sugar: number, protein: number) => ({ ...Object.fromEntries(nutrients.map(key => [key, null])), sugar_g: sugar, protein_g: protein });
const fixturePortion = { baseQuantity: 1, unitCode: 'porsi', displayLabel: '1 porsi (100 g)', basis: 'per_serving', basisSource: 'model_estimate', originalServingText: null, referenceWeightG: 100, referenceVolumeMl: null };
const fixtureItem = (title: string, sugar: number, protein: number) => ({ title, mode: 'food', quantity: 1, portion: fixturePortion,
  baseNutrients: fixtureValues(sugar, protein), nutrients: fixtureValues(sugar, protein), evidence: Object.fromEntries(nutrients.map(key => [key, null])),
  provenance: 'model_estimate', pros: ['Pertimbangkan sesuai kebutuhanmu.'], cons: ['Periksa kembali data yang belum jelas.'], warnings: ['Contoh sintetis, bukan nutrisi produk nyata.'] });
export const comparisonExample = {
  items: { a: fixtureItem('Fixture A (sintetis)', 12, 4), b: fixtureItem('Fixture B (sintetis)', 6, 2) },
  comparisonBasis: { requested: 'per_serving', status: 'common_basis', reason: 'Kedua pilihan memakai acuan massa yang sama.', references: {
    a: { quantity: 1, displayLabel: '1 porsi (100 g)', weightG: 100, volumeMl: null }, b: { quantity: 1, displayLabel: '1 porsi (100 g)', weightG: 100, volumeMl: null } } },
  comparedNutrients: { a: fixtureValues(12, 4), b: fixtureValues(6, 2) }, differences: fixtureValues(-6, -2),
  prioritySignals: [{ priority: 'Gula', nutrient: 'sugar_g', direction: 'lower', preferredDirection: 'lower' }, { priority: 'Protein', nutrient: 'protein_g', direction: 'lower', preferredDirection: 'higher' }],
  summary: 'Pilihan B punya gula lebih sedikit, tapi proteinnya juga lebih sedikit. Ini masih perkiraan yang perlu diperiksa.',
  ttsSummary: 'Pilihan B punya gula lebih sedikit, tapi proteinnya juga lebih sedikit. Ini masih perkiraan yang perlu diperiksa.',
  ttsSummarySource: 'model', warnings: ['Contoh sintetis, bukan nutrisi produk nyata.'], model: 'configured-provider-model', promptVersion: 'compare-2026-11-v1',
};
export const comparisonResponseSchema = { type: 'object', additionalProperties: false,
  example: comparisonExample,
  required: ['items', 'comparisonBasis', 'comparedNutrients', 'differences', 'prioritySignals', 'summary', 'ttsSummary', 'ttsSummarySource', 'warnings', 'model', 'promptVersion'],
  properties: {
    items: { type: 'object', additionalProperties: false, required: ['a', 'b'], properties: { a: item, b: item } },
    comparisonBasis: { type: 'object', additionalProperties: false, required: ['requested', 'status', 'references', 'reason'], properties: {
      requested: { type: 'string', enum: ['per_serving', 'per_100g', 'per_100ml'] },
      status: { type: 'string', enum: ['common_basis', 'as_portioned', 'unavailable'] },
      references: { type: 'object', additionalProperties: false, required: ['a', 'b'], properties: { a: reference, b: reference } }, reason: text,
    } },
    comparedNutrients: { type: 'object', additionalProperties: false, required: ['a', 'b'], properties: { a: values, b: values } },
    differences: values,
    prioritySignals: { type: 'array', maxItems: 5, items: { type: 'object', additionalProperties: false,
      required: ['priority', 'nutrient', 'direction', 'preferredDirection'], properties: {
        priority: text, nutrient: { type: 'string', nullable: true, enum: [...nutrients, null] },
        direction: { type: 'string', enum: ['lower', 'higher', 'equal', 'unknown'] },
        preferredDirection: { type: 'string', nullable: true, enum: ['lower', 'higher', null] },
      } } },
    summary: { type: 'string', maxLength: 1000 }, ttsSummary: { type: 'string', maxLength: 450 },
    ttsSummarySource: { type: 'string', enum: ['model', 'template'] }, warnings: list, model: text, promptVersion: text,
  },
};
export const comparePaths = (prefix: string) => ({ [`${prefix}/v1/comparisons`]: { post: {
  tags: ['Comparison (development)'], operationId: 'compareFoodOptions', summary: 'Compare two options without recording consumption',
  description: 'One vision dispatch with two images and read-only personalization. No saved comparison, consumption, cache or replay. Each HTTP resubmission is a new potentially billable operation; no Idempotency-Key required. SCANNER_USE_RAW_OCR=false ignores optional OCR; true requires it for each label option. Numeric differences are B minus A, calculated by the backend. Unknown operands stay null. Body logging omitted, including validation failures. Both operations share the scanner concurrency capacity of two.',
  requestBody: { required: true, content: { 'multipart/form-data': { schema: { type: 'object', additionalProperties: false,
    required: ['imageA', 'imageB', 'metadata'], properties: {
      imageA: { type: 'string', format: 'binary', description: 'JPEG/PNG, <=5 MiB/20 MP, MIME must match; normalized to 1600-square JPEG without crop.' },
      imageB: { type: 'string', format: 'binary', description: 'Same constraints as imageA; exactly one of each.' },
      metadata: { type: 'string', maxLength: maxMetadataBytes,
        description: `JSON string conforming to ${JSON.stringify(compareMetadataSchema)}. Byte limit ${maxMetadataBytes} UTF-8; total multipart <=${maxCompareBytes} bytes including chunked uploads. Defaults: quantity=1 for each option, basis=per_serving. Per-100 requires compatible mass/volume references; no g/ml conversion.`,
        example: JSON.stringify({ a: { mode: 'food', quantity: 1 }, b: { mode: 'label', description: 'Pilihan B', rawOcrText: 'Energi Total 100 kkal' }, basis: 'per_serving' }) },
    } } } } },
  responses: { '200': success(comparisonResponseSchema, 'Transient result; unavailable basis returns null compared values with original analyses intact'), ...errors,
    '400': errorResponse('Invalid metadata/JSON, unknown/duplicate upload or ownership fields, invalid quantity/basis, or OCR_REQUIRED when enabled.'),
    '413': errorResponse('File, total multipart, metadata byte, field or part limit exceeded.'),
    '415': errorResponse('Non-multipart request or invalid/MIME-mismatched/corrupt/oversized decoded image.'),
    '422': errorResponse('RESCAN_REQUIRED: food identity or core portion unclear; message identifies A/B.'),
    '429': errorResponse('SCAN_BUSY: shared scanner/comparison capacity is full.'),
    '502': errorResponse('Provider failed, invalid/truncated/oversized output; no automatic retry.'),
    '504': errorResponse('Provider exceeded 45-second timeout; no automatic retry.'),
  },
} } });
