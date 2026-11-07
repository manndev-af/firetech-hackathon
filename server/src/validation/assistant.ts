import express, { RequestHandler } from 'express';
import { config } from '../config/config';
import { DomainError } from '../utils/domainError';
import { validate } from './nutrition';

export const assistantMaxBytes = 64 * 1024;
export const isAssistantPath = (path: string) => path.replace(/\/+$/, '').toLowerCase() === `${config.apiPrefix}/v1/assistant/messages`.toLowerCase();
const text = { type: 'string', minLength: 1, maxLength: 2000 };
export const assistantInputSchema = { type: 'object', additionalProperties: false, required: ['mode', 'message'], properties: {
  mode: { type: 'string', enum: ['general', 'pattern'] }, message: text,
  history: { type: 'array', maxItems: 10, items: { type: 'object', additionalProperties: false, required: ['role', 'text'],
    properties: { role: { type: 'string', enum: ['user', 'assistant'] }, text } } },
} };
export type AssistantInput = { mode: 'general' | 'pattern'; message: string; history: { role: 'user' | 'assistant'; text: string }[] };
export const assistantOutputSchema = { type: 'object', additionalProperties: false, required: ['reply', 'citationIds'], properties: {
  reply: { type: 'string', minLength: 1, maxLength: 4000 },
  citationIds: { type: 'array', maxItems: 3, uniqueItems: true, items: { type: 'string', maxLength: 80 } },
} };

export function readAssistantInput(value: unknown): AssistantInput {
  validate(assistantInputSchema, value);
  const input = value as AssistantInput;
  const history = (input.history || []).map(item => ({ role: item.role, text: item.text.trim() }));
  const message = input.message.trim();
  if (!message || history.length % 2 || history.some((item, index) => !item.text || item.role !== (index % 2 ? 'assistant' : 'user')) ||
    [message, ...history.map(item => item.text)].reduce((sum, item) => sum + [...item].length, 0) > 12000)
    throw new DomainError('INVALID_INPUT', 'Pesan dan pasangan riwayat tidak valid atau terlalu panjang.');
  return { mode: input.mode, message, history };
}

const json = express.json({ limit: assistantMaxBytes, inflate: false });
export const assistantJson: RequestHandler = (req, res, next) => {
  if (!isAssistantPath(req.path)) return next();
  if (!req.is('application/json')) return next(new DomainError('INVALID_CONTENT_TYPE', 'Gunakan application/json.', 415));
  json(req, res, error => {
    if (!error) return next();
    const status = error.status === 413 ? 413 : error.status === 415 ? 415 : 400;
    next(new DomainError(status === 413 ? 'UPLOAD_TOO_LARGE' : status === 415 ? 'INVALID_ENCODING' : 'INVALID_JSON',
      status === 413 ? 'Body melebihi 64 KiB.' : status === 415 ? 'Encoding request tidak didukung.' : 'Body JSON tidak valid.', status));
  });
};
