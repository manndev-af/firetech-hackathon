import { Request, Response } from 'express';
import { ApiResponse } from '../utils/apiResponse';
import { DomainError } from '../utils/domainError';
import { getProfile, updateProfile } from '../services/profile.service';
import { createScan } from '../services/scan.service';
import { dailySummary, deleteEntry, getEntry, listEntries, localDate, serializeEntry, updateQuantity } from '../services/journal.service';
import { readScanInput } from '../middleware/scanUpload';

const owner = (res: Response): string => res.locals.userId;
const id = (req: Request): string => {
  const value = req.params.id;
  if (typeof value !== 'string' || !/^[0-9a-f-]{36}$/i.test(value)) throw new DomainError('ENTRY_NOT_FOUND', 'Catatan tidak ditemukan.', 404);
  return value;
};
export async function readProfile(_req: Request, res: Response) { return ApiResponse.success(res, await getProfile(owner(res))); }
export async function patchProfile(req: Request, res: Response) { return ApiResponse.success(res, await updateProfile(owner(res), req.body)); }
export async function scan(req: Request, res: Response) {
  res.locals.scanRunning = true;
  try {
    const input = await readScanInput(req);
    const result = await createScan(owner(res), input);
    return ApiResponse.success(res, result.entry, result.replay ? 'Scan sebelumnya.' : 'Konsumsi tercatat.', result.replay ? 200 : 201);
  } finally { delete req.file; res.locals.scanRunning = false; res.locals.releaseScanSlot?.(); }
}
export async function entries(req: Request, res: Response) {
  const profile = await getProfile(owner(res));
  return ApiResponse.success(res, await listEntries(owner(res), profile.timezone, req.query));
}
export async function entry(req: Request, res: Response) { return ApiResponse.success(res, serializeEntry(await getEntry(owner(res), id(req)))); }
export async function quantity(req: Request, res: Response) { return ApiResponse.success(res, await updateQuantity(owner(res), id(req), req.body)); }
export async function removeEntry(req: Request, res: Response) { await deleteEntry(owner(res), id(req)); return res.status(204).send(); }
export async function daily(req: Request, res: Response) {
  const profile = await getProfile(owner(res));
  if (Object.keys(req.query).some(key => key !== 'date') || (req.query.date !== undefined && typeof req.query.date !== 'string')) throw new DomainError('INVALID_QUERY', 'Gunakan date YYYY-MM-DD.');
  const date = req.query.date as string | undefined || localDate(new Date(), profile.timezone);
  return ApiResponse.success(res, await dailySummary(owner(res), date, profile.timezone));
}
