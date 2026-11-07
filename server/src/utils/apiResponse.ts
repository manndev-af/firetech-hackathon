import { Response } from 'express';
import { StatusCodes } from 'http-status-codes';

interface ApiResponseData {
  success: boolean;
  message?: string;
  data?: any;
  timestamp?: string;
}

export class ApiResponse {
  static success(res: Response, data: any = null, message?: string, statusCode: number = StatusCodes.OK): Response {
    const response: ApiResponseData = {
      success: true,
      ...(message && { message }),
      ...(data && { data }),
      timestamp: new Date().toISOString(),
    };

    return res.status(statusCode).json(response);
  }

  static error(res: Response, message: string, statusCode: number = StatusCodes.INTERNAL_SERVER_ERROR, data: any = null): Response {
    const response: ApiResponseData = {
      success: false,
      message,
      ...(data && { data }),
      timestamp: new Date().toISOString(),
    };

    return res.status(statusCode).json(response);
  }

  static created(res: Response, data: any = null, message: string = 'Resource created successfully'): Response {
    return this.success(res, data, message, StatusCodes.CREATED);
  }

  static noContent(res: Response): Response {
    return res.status(StatusCodes.NO_CONTENT).send();
  }
}
