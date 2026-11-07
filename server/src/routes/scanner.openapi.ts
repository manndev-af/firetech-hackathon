import { scanMetadataSchema, maxImageBytes } from '../middleware/scanUpload';
import { entrySchema, errorResponse, errors, success } from './nutrition.openapi';
export const scannerPaths = (prefix: string) => ({ [`${prefix}/v1/scans`]: { post: {
  tags: ['Scanner (development)'], operationId: 'createConsumptionScan', summary: 'Analyze once and record consumed food',
  description: 'One image in either mode. SCANNER_USE_RAW_OCR defaults to false: label analysis uses the image, OCR is optional and excluded from retrieval, provider input and evidence matching. If true, label requires nonempty rawOcrText and uses it alongside the image. Supplied OCR remains stored and part of the request fingerprint in both settings. Optional description/consumedAt/quantity (default 1). New per_serving label results expressed in g/ml normalize to baseQuantity=1, unitCode=porsi, preserving printed mass/volume in referenceWeightG/referenceVolumeMl. Per-100 bases and existing entries remain unchanged. Total-energy evidence excludes energy-from-fat/daily-reference rows. Conflicting evidence becomes null and invalidates generated insights/speech. Owner comes from server, no userId accepted. One provider dispatch per unique owner/key; no automatic retry, including uncertain dispatch after restart. Replays return current saved entry; deleted entries are never recreated. Images are temporary, no server photo URL. ttsSummary is generated in the same call or falls back locally.',
  parameters: [{ name: 'Idempotency-Key', in: 'header', required: true, schema: { type: 'string', format: 'uuid' } }],
  requestBody: { required: true, content: { 'multipart/form-data': { schema: {
    type: 'object', additionalProperties: false, required: ['image', 'mode'], properties: {
      image: { type: 'string', format: 'binary', description: `JPEG/PNG, MIME must match decoded content, <=${maxImageBytes} bytes, <=20 MP; total multipart <=6 MiB. Backend rotates and normalizes to a 1600 x 1600 JPEG with aspect ratio preserved and white padding, without cropping.` },
      ...scanMetadataSchema.properties,
    },
  } } } },
  responses: { '201': success(entrySchema, 'Created consumption entry'), '200': success(entrySchema, 'Replay; no additional provider call'), ...errors,
    '409': errorResponse('IDEMPOTENCY_CONFLICT, SCAN_PROCESSING or DISPATCH_UNCERTAIN; do not silently retry with a new key.'),
    '429': errorResponse('SCAN_BUSY: two scan operations are already active in this process.'),
    '410': errorResponse('ENTRY_DELETED: original scan was deleted.'), '413': errorResponse('Upload/file/field limit exceeded.'),
    '415': errorResponse('Invalid multipart content type, MIME mismatch, unsupported/undecodable image or >20 MP.'),
    '422': errorResponse('RESCAN_REQUIRED: nonfood, unclear identity or ambiguous portion basis.'),
    '502': errorResponse('Provider failed or core output invalid; no consumption created.'), '504': errorResponse('Provider timeout; no automatic resend.'),
  },
} } });
