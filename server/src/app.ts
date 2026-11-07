import cors from 'cors';
import express, { Application, Request, Response } from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/config';
import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFoundHandler';
import { generalLimiter } from './middleware/rateLimiter';
import apiRoutes from './routes';

export const createApp = (): Application => {
  const app = express();

  // Security middleware
  app.use(helmet());

  // CORS configuration
  app.use(cors({
    origin: config.corsOrigin,
    credentials: true,
  }));

  // Body parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Custom morgan token for date
  morgan.token('date', () => {
    return new Date().toLocaleString();
  });

  // Logging middleware (skip in test environment)
  if (config.env !== 'test') {
    app.use(morgan(config.env === 'development' ? ':date :method :url :status :response-time ms - :res[content-length]' : 'combined'));
  }

  // Health check endpoint
  app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      environment: config.env,
    });
  });

  // API routes with rate limiting
  app.use(config.apiPrefix, generalLimiter, apiRoutes);

  // Error handling middleware (must be last)
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
