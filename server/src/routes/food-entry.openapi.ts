import { quantitySchema } from '../validation/nutrition';
import { dateParameter, entrySchema, errors, jsonBody, success } from './nutrition.openapi';
const parameters = [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }];
export const foodEntryPaths = (prefix: string) => ({
  [`${prefix}/v1/food-entries`]: { get: {
    tags: ['Consumption (development)'], operationId: 'listFoodEntries', summary: 'List owned consumption entries',
    parameters: [dateParameter, ...['page', 'limit'].map(name => ({ name, in: 'query', schema: { type: 'integer', minimum: 1, maximum: name === 'page' ? 10000 : 100, default: name === 'page' ? 1 : 20 } }))],
    responses: { '200': success({ type: 'object', properties: { entries: { type: 'array', items: entrySchema }, total: { type: 'integer' }, page: { type: 'integer' }, limit: { type: 'integer' } } }), ...errors },
  } },
  [`${prefix}/v1/food-entries/{id}`]: { parameters,
    get: { tags: ['Consumption (development)'], operationId: 'getFoodEntry', summary: 'Read entry with sources and speech summary', responses: { '200': success(entrySchema), ...errors } },
    delete: { tags: ['Consumption (development)'], operationId: 'deleteFoodEntry', summary: 'Delete consumption and retain scan tombstone',
      description: 'Removed from future retrieval and daily totals. Prior scan-time insight snapshots are historical and do not get regenerated.', responses: { '204': { description: 'Deleted; empty body' }, ...errors } },
  },
  [`${prefix}/v1/food-entries/{id}/quantity`]: { parameters, patch: {
    tags: ['Consumption (development)'], operationId: 'updateFoodQuantity', summary: 'Recalculate from original basis, no DeepSeek call',
    description: 'Same portion unit only; composition/identity/unit changes require a new scan. Null remains null. ttsSummary remains quantity-independent.',
    requestBody: jsonBody(quantitySchema, { quantity: 2 }), responses: { '200': success(entrySchema), ...errors },
  } },
});
