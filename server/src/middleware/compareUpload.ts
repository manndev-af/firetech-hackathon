import { Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { scannerConfig } from '../config/scanner';
import { validate } from '../validation/nutrition';
import { DomainError } from '../utils/domainError';
import { maxImageBytes, normalizeImage } from './scanUpload';

export const maxCompareBytes = 11 * 1024 * 1024;
export const maxMetadataBytes = 256 * 1024;
const optionSchema = {
  type: 'object', additionalProperties: false, required: ['mode'],
  properties: {
    mode: { type: 'string', enum: ['food', 'label'] },
    description: { type: 'string', maxLength: 1000 },
    rawOcrText: { type: 'string', maxLength: 20000 },
    quantity: { type: 'number', minimum: 0.000001, maximum: 10000, multipleOf: 0.000001 },
  },
};
export const compareMetadataSchema = {
  type: 'object', additionalProperties: false, required: ['a', 'b'],
  properties: {
    a: optionSchema, b: optionSchema,
    basis: { type: 'string', enum: ['per_serving', 'per_100g', 'per_100ml'] },
  },
};
const upload = multer({ storage: multer.memoryStorage(), limits: {
  fileSize: maxImageBytes, files: 2, fields: 1, parts: 4,
  fieldSize: maxMetadataBytes, fieldNameSize: 64,
} }).fields([{ name: 'imageA', maxCount: 1 }, { name: 'imageB', maxCount: 1 }]);

export function compareUpload(req: Request, res: Response, next: NextFunction) {
  res.locals.omitDebugPayload = true;
  if (!req.is('multipart/form-data')) return next(new DomainError('INVALID_CONTENT_TYPE', 'Gunakan multipart/form-data.', 415));
  if (Number(req.get('content-length')) > maxCompareBytes)
    return next(new DomainError('UPLOAD_TOO_LARGE', 'Upload melebihi 11 MiB.', 413));
  let bytes = 0;
  let finished = false;
  const done = (error?: unknown) => {
    if (finished) return;
    finished = true;
    req.off('data', count);
    if (error) delete req.files;
    next(error);
  };
  const count = (chunk: Buffer) => {
    bytes += chunk.length;
    if (bytes > maxCompareBytes && !finished) {
      req.unpipe();
      res.once('finish', () => req.destroy());
      req.resume();
      done(new DomainError('UPLOAD_TOO_LARGE', 'Upload melebihi 11 MiB.', 413));
    }
  };
  req.on('data', count);
  upload(req, res, error => done(error ? new DomainError('INVALID_UPLOAD',
    'Upload melebihi batas atau field tidak sesuai.', error.code?.startsWith('LIMIT_') && error.code !== 'LIMIT_UNEXPECTED_FILE' ? 413 : 400) : undefined));
}

export type CompareOption = { mode: 'food' | 'label'; description: string; rawOcrText: string; quantity: number; image: Buffer };
export type CompareInput = { a: CompareOption; b: CompareOption; basis: 'per_serving' | 'per_100g' | 'per_100ml' };

export async function readCompareInput(req: Request): Promise<CompareInput> {
  if (Object.keys(req.body || {}).length !== 1 || typeof req.body.metadata !== 'string')
    throw new DomainError('INVALID_INPUT', 'Satu field metadata JSON wajib diisi.');
  if (Buffer.byteLength(req.body.metadata, 'utf8') > maxMetadataBytes)
    throw new DomainError('UPLOAD_TOO_LARGE', 'Metadata melebihi 256 KiB.', 413);
  let metadata: unknown;
  try { metadata = JSON.parse(req.body.metadata); }
  catch { throw new DomainError('INVALID_INPUT', 'Metadata JSON tidak valid.'); }
  validate(compareMetadataSchema, metadata);
  const value = metadata as { a: Omit<CompareOption, 'image'>; b: Omit<CompareOption, 'image'>; basis?: CompareInput['basis'] };
  const files = req.files as Record<string, Express.Multer.File[]> | undefined;
  if (!files || Object.keys(files).length !== 2 || files.imageA?.length !== 1 || files.imageB?.length !== 1)
    throw new DomainError('IMAGE_REQUIRED', 'Gambar A dan B wajib diunggah masing-masing satu.');
  // Validate both metadata objects before decoding either image or contacting a provider.
  for (const key of ['a', 'b'] as const) {
    if (value[key].mode === 'label' && scannerConfig().useRawOcr && !value[key].rawOcrText?.trim())
      throw new DomainError('OCR_REQUIRED', `Raw OCR wajib untuk pilihan ${key.toUpperCase()}.`);
  }
  const read = async (key: 'a' | 'b', file: Express.Multer.File): Promise<CompareOption> => {
    if (!file.size || file.size > maxImageBytes)
      throw new DomainError('INVALID_UPLOAD', 'Ukuran tiap gambar harus lebih dari nol dan maksimal 5 MiB.', file.size ? 413 : 400);
    return { mode: value[key].mode, description: (value[key].description || '').trim(),
      rawOcrText: (value[key].rawOcrText || '').trim(), quantity: value[key].quantity ?? 1,
      image: await normalizeImage(file) };
  };
  return { a: await read('a', files.imageA[0]), b: await read('b', files.imageB[0]), basis: value.basis || 'per_serving' };
}
