import { NextFunction, Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import { config } from '../config/config';
import { ApiResponse } from '../utils/apiResponse';

export class HealthController {
  public getHealth = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const healthData = {
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        environment: config.env,
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
          unit: 'MB',
        },
      };

      ApiResponse.success(res, healthData, 'Service is healthy');
    } catch (error) {
      next(error);
    }
  };

  /**
   * Readiness probe - indicates if the application is ready to accept traffic
   */
  public getReadiness = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const isReady = true;

      if (!isReady) {
        ApiResponse.error(res, 'Service not ready', StatusCodes.SERVICE_UNAVAILABLE);
        return;
      }

      ApiResponse.success(res, { ready: true }, 'Service is ready');
    } catch (error) {
      next(error);
    }
  };

  /**
   * Liveness probe - indicates if the application is alive
   */
  public getLiveness = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      ApiResponse.success(res, { alive: true }, 'Service is alive');
    } catch (error) {
      next(error);
    }
  };
}
