import { NextFunction, Request, Response } from 'express';

type AsyncRequestHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<any>;

export const asyncErrorHandler = (fn: AsyncRequestHandler) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
