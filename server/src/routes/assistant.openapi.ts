import { assistantInputSchema, assistantMaxBytes } from '../validation/assistant';
import { errorResponse, openapiSchema, success } from './nutrition.openapi';
import { nutrients } from '../validation/nutrition';
import { buildPattern } from '../services/assistant.service';

const string = { type: 'string' };
const count = { type: 'integer', minimum: 0 };
const summary = { type: 'object', additionalProperties: false, required: ['entryCount', 'recordedIntakeOnly', 'nutrients'], properties: {
  entryCount: count, recordedIntakeOnly: { type: 'boolean', enum: [true] },
  nutrients: { type: 'object', additionalProperties: false, required: [...nutrients], properties: Object.fromEntries(nutrients.map(key => [key, {
    type: 'object', additionalProperties: false, required: ['knownTotal', 'knownCount', 'missingCount', 'complete', 'provenanceCounts'], properties: {
      knownTotal: { type: 'number', nullable: true, description: key === 'calories_kcal' ? 'kcal' : key === 'sodium_mg' ? 'mg' : 'g' },
      knownCount: count, missingCount: count, complete: { type: 'boolean' }, provenanceCounts: { type: 'object', additionalProperties: count },
    },
  }])) },
} };
const date = { type: 'string', format: 'date' };
const dateTime = { type: 'string', format: 'date-time' };
export const patternEvidenceSchema = { type: 'object', nullable: true, additionalProperties: false,
  required: ['dateFrom', 'dateTo', 'windowEndExclusive', 'entryCount', 'daysWithEntries', 'recordedIntakeOnly', 'periodSummary', 'dailySummaries', 'frequentFoods'], properties: {
    dateFrom: date, dateTo: date, windowEndExclusive: dateTime, entryCount: { ...count, maximum: 1000 },
    daysWithEntries: { ...count, maximum: 7 }, recordedIntakeOnly: { type: 'boolean', enum: [true] }, periodSummary: summary,
    dailySummaries: { type: 'array', minItems: 7, maxItems: 7, items: { ...summary, required: [...summary.required, 'date'], properties: { date, ...summary.properties } } },
    frequentFoods: { type: 'array', maxItems: 5, items: { ...summary, required: [...summary.required, 'title'], properties: { title: string, ...summary.properties } } },
  },
};
export const assistantResponseSchema = { type: 'object', additionalProperties: false,
  required: ['reply', 'sources', 'warnings', 'contextSummary', 'model', 'promptVersion'], properties: {
    reply: { type: 'string', minLength: 1, maxLength: 4000 },
    sources: { type: 'array', maxItems: 3, items: { type: 'object', additionalProperties: false,
      required: ['id', 'title', 'sourceTitle', 'sourceUrl', 'version', 'reviewedAt'], properties: {
        id: string, title: string, sourceTitle: string, sourceUrl: { type: 'string', format: 'uri' }, version: string, reviewedAt: dateTime,
      } } }, warnings: { type: 'array', items: string },
    contextSummary: { type: 'object', additionalProperties: false,
      required: ['mode', 'snapshotAt', 'timezone', 'historyMessageCount', 'referencesAvailable', 'patternEvidence'], properties: {
        mode: { type: 'string', enum: ['general', 'pattern'] }, snapshotAt: dateTime, timezone: string,
        historyMessageCount: { ...count, maximum: 10 }, referencesAvailable: { type: 'boolean' }, patternEvidence: patternEvidenceSchema,
      } }, model: string, promptVersion: string,
  },
};
export const assistantGeneralExample = { reply: 'Cek porsi dan kandungan gizi sesuai prioritasmu. Referensi khusus untuk pertanyaan ini belum tersedia.', sources: [],
  warnings: ['Referensi reviewed yang relevan belum tersedia; informasi umum tidak menggantikan data terverifikasi.'],
  contextSummary: { mode: 'general', snapshotAt: '2026-11-08T05:00:00.000Z', timezone: 'Asia/Jakarta', historyMessageCount: 0, referencesAvailable: false, patternEvidence: null },
  model: 'configured-provider-model', promptVersion: 'assistant-2026-11-v1' };
export const assistantPatternExample = { ...assistantGeneralExample,
  reply: 'Belum ada catatan dalam tujuh tanggal ini, jadi pola gulamu belum bisa disimpulkan. Mulai catat makanan yang kamu konsumsi, ya.',
  warnings: ['Belum ada catatan dalam tujuh tanggal ini; pola belum dapat disimpulkan.', 'Hanya konsumsi tercatat yang dianalisis, bukan seluruh asupan.'],
  contextSummary: { ...assistantGeneralExample.contextSummary, mode: 'pattern',
    patternEvidence: buildPattern([], new Date('2026-11-08T05:00:00.000Z'), 'Asia/Jakarta') } };
const envelope = (data: object) => ({ success: true, message: 'Jawaban assistant tersedia.', data, timestamp: '2026-11-08T05:00:00.000Z' });

export const assistantPaths = (prefix: string) => ({ [`${prefix}/v1/assistant/messages`]: { post: {
  tags: ['Assistant (development)'], operationId: 'askNutritionAssistant', summary: 'Ask a nutrition question using session context',
  description: `Text only; general or pattern. No compare, persisted conversation or database writes. JSON <=${assistantMaxBytes} bytes, no compressed body. History defaults to [], at most five completed alternating user/assistant pairs; nonblank text <=2000 Unicode code points each, total <=12000. One provider dispatch maximum, no retry/replay guarantee. Pattern uses seven local calendar dates through request time, <=1000 entries. Shared two-operation capacity. Request/response/query payload omitted from logs.`,
  requestBody: { required: true, content: { 'application/json': { schema: openapiSchema(assistantInputSchema),
    example: { mode: 'pattern', message: 'Bagaimana pola gula di catatanku?', history: [] } } } },
  responses: { '200': { ...success(assistantResponseSchema, 'Transient reply; patternEvidence is null for general and seven-date evidence for pattern.'),
    content: { 'application/json': { ...success(assistantResponseSchema).content['application/json'], examples: {
      general: { summary: 'General without matched references', value: envelope(assistantGeneralExample) },
      pattern: { summary: 'Pattern cold start, synthetic example', value: envelope(assistantPatternExample) },
    } } } },
    '400': errorResponse('INVALID_INPUT, INVALID_JSON or OWNER_OVERRIDE.'),
    '404': errorResponse('DEMO_DISABLED.'), '413': errorResponse('UPLOAD_TOO_LARGE: JSON exceeds 64 KiB.'),
    '415': errorResponse('INVALID_CONTENT_TYPE or INVALID_ENCODING; application/json, no compression.'),
    '422': errorResponse('PATTERN_LIMIT_EXCEEDED: more than 1000 entries in window.'),
    '429': errorResponse('SCAN_BUSY: shared scanner/comparison/assistant capacity is full.'),
    '502': errorResponse('Provider/output/citation failure; no retry.'),
    '503': errorResponse('Profile, database, provider configuration or mandatory context unavailable.'),
    '504': errorResponse('Provider exceeded 45 seconds; no retry.'),
  },
} } });
