import { NextFunction, Request, Response } from 'express';
import { AppError } from './appError';

export class DomainError extends AppError {
  constructor(public readonly code: string, message: string, status = 400) {
    super(message, status);
  }
}

export function domainErrorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  const known = error instanceof DomainError;
  res.status(known ? error.statusCode : 503).json({
    success: false,
    message: known ? error.message : 'Database atau layanan belum tersedia.',
    data: { code: known ? error.code : 'SERVICE_UNAVAILABLE' },
    timestamp: new Date().toISOString(),
  });
}
