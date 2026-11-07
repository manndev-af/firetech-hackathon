import { Request, Response } from 'express';
import { readAssistantInput } from '../validation/assistant';
import { createAssistantMessage } from '../services/assistant.service';
import { ApiResponse } from '../utils/apiResponse';

export async function assistantMessage(req: Request, res: Response) {
  res.locals.scanRunning = true;
  try {
    const input = readAssistantInput(req.body);
    return ApiResponse.success(res, await createAssistantMessage(res.locals.userId, input), 'Jawaban assistant tersedia.');
  } finally {
    res.locals.scanRunning = false;
    res.locals.releaseScanSlot?.();
  }
}
