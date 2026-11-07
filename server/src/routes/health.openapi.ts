const timestamp = { type: 'string', format: 'date-time' };

const healthResponse = (data: object) => ({
  description: 'Service status',
  content: { 'application/json': { schema: {
    type: 'object',
    required: ['success', 'message', 'data', 'timestamp'],
    properties: {
      success: { type: 'boolean', enum: [true] },
      message: { type: 'string' },
      timestamp,
      data,
    },
  } } },
});

export const healthPaths = (prefix: string) => ({
  '/health': {
    get: {
      tags: ['Health'], operationId: 'getBasicHealth', summary: 'Basic process health',
      responses: { '200': {
        description: 'Process is running',
        content: { 'application/json': { schema: {
          type: 'object', required: ['status', 'timestamp', 'environment'],
          properties: { status: { type: 'string', enum: ['OK'] }, timestamp, environment: { type: 'string' } },
        } } },
      } },
    },
  },
  [`${prefix}/health`]: {
    get: {
      tags: ['Health'], operationId: 'getHealth', summary: 'Process health and memory usage',
      responses: { '200': healthResponse({
        type: 'object', required: ['status', 'uptime', 'timestamp', 'environment', 'memory'],
        properties: {
          status: { type: 'string', enum: ['healthy'] }, uptime: { type: 'number' }, timestamp,
          environment: { type: 'string' },
          memory: {
            type: 'object', required: ['used', 'total', 'unit'],
            properties: { used: { type: 'integer' }, total: { type: 'integer' }, unit: { type: 'string', enum: ['MB'] } },
          },
        },
      }) },
    },
  },
  [`${prefix}/health/readiness`]: {
    get: {
      tags: ['Health'], operationId: 'getReadiness', summary: 'Readiness probe',
      description: 'Currently returns ready=true; does not check database or other dependencies.',
      responses: { '200': healthResponse({
        type: 'object', required: ['ready'], properties: { ready: { type: 'boolean', enum: [true] } },
      }) },
    },
  },
  [`${prefix}/health/liveness`]: {
    get: {
      tags: ['Health'], operationId: 'getLiveness', summary: 'Liveness probe',
      responses: { '200': healthResponse({
        type: 'object', required: ['alive'], properties: { alive: { type: 'boolean', enum: [true] } },
      }) },
    },
  },
});
