import { NextFunction, Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import { config } from '../config/config';
import { AppError } from '../utils/appError';

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  let statusCode = StatusCodes.INTERNAL_SERVER_ERROR;
  let message = 'Internal Server Error';
  let isOperational = false;

  if (err instanceof AppError) {
    statusCode = err.statusCode;
    message = err.message;
    isOperational = true;
  } else if (err.name === 'ValidationError') {
    statusCode = StatusCodes.BAD_REQUEST;
    message = err.message;
    isOperational = true;
  } else if (err.name === 'UnauthorizedError') {
    statusCode = StatusCodes.UNAUTHORIZED;
    message = 'Invalid token';
    isOperational = true;
  }

  // Log error in development
  if (config.env === 'development') {
    console.error('Error:', {
      statusCode,
      message,
      stack: err.stack,
    });
  }

  if (config.env === 'production' && !isOperational) {
    message = 'Something went wrong';
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(config.env === 'development' && {
      stack: err.stack,
      error: err.name,
    }),
  });
};
