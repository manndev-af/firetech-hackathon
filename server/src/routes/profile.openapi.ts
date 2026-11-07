import { profilePatchSchema, profileProperties } from '../validation/nutrition';
import { errors, jsonBody, openapiSchema, success } from './nutrition.openapi';
const profile = openapiSchema({ type: 'object', required: [...Object.keys(profileProperties), 'userId', 'createdAt', 'updatedAt'], properties: {
  ...profileProperties, userId: { type: 'string', format: 'uuid', readOnly: true },
  createdAt: { type: 'string', format: 'date-time', readOnly: true }, updatedAt: { type: 'string', format: 'date-time', readOnly: true },
} }) as object;
export const profilePaths = (prefix: string) => ({ [`${prefix}/v1/profile`]: {
  get: { tags: ['Profile (development)'], operationId: 'getNutritionProfile', summary: 'Read server-selected seeded profile', responses: { '200': success(profile), ...errors } },
  patch: { tags: ['Profile (development)'], operationId: 'patchNutritionProfile', summary: 'Save only edited profile fields',
    description: 'Omitted fields survive. Identity/audio/timezone updates allow empty priorities; personalization requires at least one. listed allergies require an ingredient. Switching to unknown/noneKnown clears omitted old allergy details; explicit contradictory nonempty details fail. Empty strings clear name/otherAllergies, null clears optional scalar fields. Audio storage does not implement playback.',
    requestBody: jsonBody(profilePatchSchema, { name: 'Naya', age: null }), responses: { '200': success(profile), ...errors },
  },
} });
