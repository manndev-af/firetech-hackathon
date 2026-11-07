import { Request, Response } from 'express';
import { readCompareInput } from '../middleware/compareUpload';
import { createComparison } from '../services/compare.service';
import { ApiResponse } from '../utils/apiResponse';

export async function compare(req: Request, res: Response) {
  res.locals.scanRunning = true;
  try {
    const input = await readCompareInput(req);
    const result = await createComparison(res.locals.userId, input);
    return ApiResponse.success(res, result, 'Perbandingan selesai; belum dicatat sebagai konsumsi.');
  } finally {
    delete req.files;
    res.locals.scanRunning = false;
    res.locals.releaseScanSlot?.();
  }
}
