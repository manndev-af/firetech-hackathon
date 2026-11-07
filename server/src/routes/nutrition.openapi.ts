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
