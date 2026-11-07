import { scanMetadataSchema, maxImageBytes } from '../middleware/scanUpload';
import { entrySchema, errorResponse, errors, success } from './nutrition.openapi';
export const scannerPaths = (prefix: string) => ({ [`${prefix}/v1/scans`]: { post: {
  tags: ['Scanner (development)'], operationId: 'createConsumptionScan', summary: 'Analyze once and record consumed food',
  description: 'One image in either mode. Label requires nonempty rawOcrText. Optional description/consumedAt/quantity (default 1). Owner comes from server, no userId accepted. One provider dispatch per unique owner/key; no automatic retry, including uncertain dispatch after restart. Replays return current saved entry; deleted entries are never recreated. Images are temporary, no server photo URL. ttsSummary is generated in the same call or falls back locally.',
  parameters: [{ name: 'Idempotency-Key', in: 'header', required: true, schema: { type: 'string', format: 'uuid' } }],
  requestBody: { required: true, content: { 'multipart/form-data': { schema: {
    type: 'object', additionalProperties: false, required: ['image', 'mode'], properties: {
      image: { type: 'string', format: 'binary', description: `JPEG/PNG, MIME must match decoded content, <=${maxImageBytes} bytes, <=20 MP; total multipart <=6 MiB.` },
      ...scanMetadataSchema.properties,
    },
  } } } },
  responses: { '201': success(entrySchema, 'Created consumption entry'), '200': success(entrySchema, 'Replay; no additional provider call'), ...errors,
    '409': errorResponse('IDEMPOTENCY_CONFLICT, SCAN_PROCESSING or DISPATCH_UNCERTAIN; do not silently retry with a new key.'),
    '410': errorResponse('ENTRY_DELETED: original scan was deleted.'), '413': errorResponse('Upload/file/field limit exceeded.'),
    '415': errorResponse('Invalid multipart content type, MIME mismatch, unsupported/undecodable image or >20 MP.'),
    '422': errorResponse('RESCAN_REQUIRED: nonfood, unclear identity or ambiguous portion basis.'),
    '502': errorResponse('Provider failed or core output invalid; no consumption created.'), '504': errorResponse('Provider timeout; no automatic resend.'),
  },
} } });
