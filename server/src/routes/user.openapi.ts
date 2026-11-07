import { createUserSchema, updateUserSchema } from '../validation/userSchema';
import { rateLimitResponse } from './health.openapi';

// OpenAPI 3.0 requires a non-empty required array; update fields are all optional.
const { required: _required, ...updateBodySchema } = updateUserSchema;

const user = {
  type: 'object', required: ['id', 'name', 'email'],
  properties: {
    id: { type: 'string' },
    ...updateUserSchema.properties,
  },
};
const response = (data: object) => ({
  description: 'Successful operation on demo users',
  content: { 'application/json': { schema: {
    type: 'object', required: ['success', 'message', 'data', 'timestamp'],
    properties: {
      success: { type: 'boolean', enum: [true] }, message: { type: 'string' },
      data, timestamp: { type: 'string', format: 'date-time' },
    },
  } } },
});
const error = {
  type: 'object', required: ['success', 'message'],
  properties: {
    success: { type: 'boolean', enum: [false] }, message: { type: 'string' },
    stack: { type: 'string', description: 'Development only' },
    error: { type: 'string', description: 'Development only' },
    errors: { type: 'array', items: {
      type: 'object', properties: { field: { type: 'string' }, message: { type: 'string' } },
    } },
  },
};
const notFound = { description: 'User not found', content: { 'application/json': { schema: error } } };
const badRequest = { description: 'Invalid JSON or request validation failed', content: { 'application/json': { schema: error } } };
const body = (schema: object) => ({
  required: true,
  description: 'Unknown fields are removed by validation; nullable fields accept null. PUT also accepts an empty object.',
  content: { 'application/json': { schema } },
});

export const userPaths = (prefix: string) => ({
  [`${prefix}/users`]: {
    get: {
      tags: ['Users (demo)'], operationId: 'getAllUsers', summary: 'List in-memory demo users',
      responses: { '200': response({ type: 'array', items: user }), '429': rateLimitResponse },
    },
    post: {
      tags: ['Users (demo)'], operationId: 'createUser', summary: 'Create an in-memory demo user',
      requestBody: body(createUserSchema),
      responses: { '201': response(user), '400': badRequest, '429': rateLimitResponse },
    },
  },
  [`${prefix}/users/{id}`]: {
    parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' }, example: '1' }],
    get: {
      tags: ['Users (demo)'], operationId: 'getUserById', summary: 'Get an in-memory demo user',
      responses: { '200': response(user), '404': notFound, '429': rateLimitResponse },
    },
    put: {
      tags: ['Users (demo)'], operationId: 'updateUser', summary: 'Update supplied fields of an in-memory demo user',
      requestBody: body(updateBodySchema),
      responses: { '200': response(user), '400': badRequest, '404': notFound, '429': rateLimitResponse },
    },
    delete: {
      tags: ['Users (demo)'], operationId: 'deleteUser', summary: 'Delete an in-memory demo user',
      responses: { '204': { description: 'Deleted; no response body' }, '404': notFound, '429': rateLimitResponse },
    },
  },
});
