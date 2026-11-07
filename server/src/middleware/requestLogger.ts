import { appendFile, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { Request, Response, RequestHandler } from 'express';
import morgan from 'morgan';

const privateField = /^(authorization|cookie|setcookie|.*password.*|.*secret.*|.*token|.*apikey|name|email|age|heightcm|weightkg|allergies|otherallergies|rawocrtext|description|usernote|image|base64|buffer|stack|context|profile)$/i;

function redact(value: unknown, depth = 0): unknown {
  if (depth > 8) return '[depth limit]';
  if (Buffer.isBuffer(value)) return `[binary: ${value.length} bytes]`;
  if (typeof value === 'string') return value.length > 4000 ? `${value.slice(0, 4000)}[truncated]` : value;
  if (Array.isArray(value)) return value.slice(0, 100).map(item => redact(item, depth + 1));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).slice(0, 100).map(([key, item]) =>
    [key, privateField.test(key.replace(/[-_]/g, '')) ? '[redacted]' : redact(item, depth + 1)]));
  return value;
}

function bounded(value: unknown): unknown {
  const safe = redact(value);
  const text = JSON.stringify(safe);
  return text && text.length > 32000 ? { truncated: true, preview: text.slice(0, 32000) } : safe;
}

export function createRequestLogger(directory = resolve(__dirname, '../../src/logs')): RequestHandler {
  mkdirSync(directory, { recursive: true });
  const logger = morgan<Request, Response>((tokens, req, res) => {
    return JSON.stringify({
      timestamp: new Date().toISOString(), method: req.method, path: req.path,
      query: bounded(req.query), status: res.statusCode,
      durationMs: Number(tokens['response-time'](req, res)),
      request: { headers: bounded(req.headers), body: bounded(req.body),
        ...(req.file && { file: { mimeType: req.file.mimetype, bytes: req.file.size } }) },
      response: { contentType: res.getHeader('content-type'), body: res.locals.debugResponse ?? '[streamed or empty response]' },
    });
  }, { stream: { write(line) {
    appendFile(join(directory, `requests-${new Date().toISOString().slice(0, 10)}.log`), line, { mode: 0o600 }, error => {
      if (error) console.error('Request log could not be written.');
    });
  } } });
  return (req, res, next) => {
    const send = res.send;
    res.send = function (body) {
      let payload: unknown = body;
      if (typeof body === 'string') {
        try { payload = JSON.parse(body); } catch { payload = '[non-JSON response omitted]'; }
      }
      res.locals.debugResponse = bounded(payload);
      return send.call(this, body);
    };
    logger(req, res, next);
  };
}
