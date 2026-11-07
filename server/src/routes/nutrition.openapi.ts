import { nutrients } from '../validation/nutrition';
import { analysisSchema } from '../services/deepseek.service';
export function openapiSchema(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(openapiSchema);
  if (!value || typeof value !== 'object') return value;
  const result = Object.fromEntries(Object.entries(value).map(([key, child]) => [key, openapiSchema(child)]));
  if (Array.isArray(result.anyOf) && result.anyOf.length === 2) {
    const branches = result.anyOf as Record<string, unknown>[];
    if (branches.some(branch => branch.type === 'null')) return { ...branches.find(branch => branch.type !== 'null'), nullable: true };
  }
  if (Array.isArray(result.type)) { result.nullable = result.type.includes('null'); result.type = result.type.find(type => type !== 'null'); }
  if (typeof result.exclusiveMinimum === 'number') { result.minimum = result.exclusiveMinimum; result.exclusiveMinimum = true; }
  return result;
}
export const errorResponse = (description: string) => ({ description, content: { 'application/json': { schema: {
  type: 'object', required: ['success', 'message', 'data', 'timestamp'], properties: {
    success: { type: 'boolean', enum: [false] }, message: { type: 'string' }, timestamp: { type: 'string', format: 'date-time' },
    data: { type: 'object', required: ['code'], properties: { code: { type: 'string' } } },
  },
} } } });
export const errors = {
  '400': errorResponse('Invalid input, unknown/contradictory fields or ownership override.'),
  '404': errorResponse('Domain disabled outside explicit development/test mode, or record not found.'),
  '429': { description: 'Rate limit (starter text response) or scan concurrency limit (domain JSON error).' },
  '503': errorResponse('Development identity, configuration or database unavailable.'),
};
export const success = (schema: object, description = 'Success') => ({ description, content: { 'application/json': { schema: {
  type: 'object', required: ['success', 'data', 'timestamp'], properties: {
    success: { type: 'boolean', enum: [true] }, message: { type: 'string' }, data: schema, timestamp: { type: 'string', format: 'date-time' },
  },
} } } });
export const jsonBody = (schema: object, example?: object) => ({ required: true, content: { 'application/json': { schema: openapiSchema(schema), ...(example ? { example } : {}) } } });
export const dateParameter = { name: 'date', in: 'query', required: false, schema: { type: 'string', format: 'date' }, description: 'Local date in profile timezone, 2000-01-01 through 2100-12-30.' };
export const nutrientValues = { type: 'object', required: [...nutrients], properties: Object.fromEntries(nutrients.map(key => [key, { type: 'number', nullable: true, minimum: 0 }])) };
export const entrySchema = { type: 'object', required: ['id', 'consumedAt', 'mode', 'title', 'quantity', 'baseQuantity', 'baseNutrients', 'nutrients', 'provenance', 'analysis', 'context', 'ttsSummary', 'ttsSummarySource'], properties: {
  id: { type: 'string', format: 'uuid' }, consumedAt: { type: 'string', format: 'date-time' }, mode: { type: 'string', enum: ['food', 'label'] },
  title: { type: 'string' }, description: { type: 'string' }, rawOcrText: { type: 'string', nullable: true },
  quantity: { type: 'number', minimum: 0.000001, maximum: 10000 }, baseQuantity: { type: 'number', minimum: 0.000001 },
  baseNutrients: nutrientValues, nutrients: nutrientValues,
  provenance: { type: 'string', enum: ['model_estimate', 'label_extracted_unverified'] },
  analysis: openapiSchema({ ...analysisSchema, required: [...analysisSchema.required, 'ttsSummary', 'ttsSummarySource'], properties: {
    ...analysisSchema.properties, ttsSummary: { type: 'string', maxLength: 450 }, ttsSummarySource: { type: 'string', enum: ['model', 'template'] },
  } }),
  context: { type: 'object', description: 'Scan-time retrieved profile allowlist, recordedDaily with completeness, bounded history and cited references. Not a live assessment.' },
  ttsSummary: { type: 'string', maxLength: 450, description: 'Indonesian plain speech, 2-3 sentences, <=60 words. No serving totals; available with audio off.' },
  ttsSummarySource: { type: 'string', enum: ['model', 'template'] }, model: { type: 'string' }, promptVersion: { type: 'string' },
  createdAt: { type: 'string', format: 'date-time' }, updatedAt: { type: 'string', format: 'date-time' },
} };
const summaryNutrient = { type: 'object', required: ['knownTotal', 'knownCount', 'missingCount', 'complete', 'provenanceCounts'], properties: {
  knownTotal: { type: 'number', nullable: true }, knownCount: { type: 'integer' }, missingCount: { type: 'integer' }, complete: { type: 'boolean' },
  provenanceCounts: { type: 'object', additionalProperties: { type: 'integer' } },
} };
export const nutritionPaths = (prefix: string) => ({ [`${prefix}/v1/nutrition/daily`]: { get: {
  tags: ['Nutrition (development)'], operationId: 'getDailyNutrition', summary: 'Recorded daily totals, not total actual food intake',
  parameters: [dateParameter], responses: { '200': success({ type: 'object', required: ['date', 'timezone', 'entryCount', 'recordedIntakeOnly', 'nutrients'], properties: {
    date: { type: 'string', format: 'date' }, timezone: { type: 'string' }, entryCount: { type: 'integer' }, recordedIntakeOnly: { type: 'boolean', enum: [true] },
    nutrients: { type: 'object', properties: Object.fromEntries(nutrients.map(key => [key, summaryNutrient])) },
  } }), ...errors },
} } });
