import cors from "cors";
import express, { Application, Request, Response, NextFunction } from "express";
import helmet from "helmet";
import morgan from "morgan";
import swaggerUi from "swagger-ui-express";
import { config } from "./config/config";
import { openapi } from "./config/openapi";
import { errorHandler } from "./middleware/errorHandler";
import { notFoundHandler } from "./middleware/notFoundHandler";
import { createRequestLogger } from "./middleware/requestLogger";
import apiRoutes from "./routes";
import { DomainError, domainErrorHandler } from "./utils/domainError";

export const createApp = (): Application => {
  const app = express();

  // Security middleware
  app.use(helmet());

  // Capture parser/validation failures as well as successful API responses.
  if (config.env === "development") app.use(createRequestLogger());

  // CORS configuration
  app.use(
    cors({
      origin: config.corsOrigin,
      credentials: true,
    }),
  );

  // Body parsing middleware
  app.use(express.json({ limit: "10mb" }));
  app.use(express.urlencoded({ extended: true, limit: "10mb" }));

  // Custom morgan token for date
  morgan.token("date", () => {
    return new Date().toLocaleString();
  });

  // Logging middleware (skip in test environment)
  if (config.env !== "test") {
    app.use(
      morgan(
        config.env === "development"
          ? ":date :method :url :status :response-time ms - :res[content-length]"
          : "combined",
      ),
    );
  }

  // Health check endpoint
  app.get("/health", (req: Request, res: Response) => {
    res.status(200).json({
      status: "OK",
      timestamp: new Date().toISOString(),
      environment: config.env,
    });
  });

  // API routes
  app.get(`${config.apiPrefix}/openapi.json`, (_req, res) => res.json(openapi));
  app.use(
    `${config.apiPrefix}/docs`,
    helmet({
      contentSecurityPolicy: { directives: { upgradeInsecureRequests: null } },
    }),
    swaggerUi.serve,
    swaggerUi.setup(openapi, {
      swaggerOptions: { validatorUrl: null },
      customSiteTitle: "NutriLens API Docs",
    }),
  );
  app.use(config.apiPrefix, apiRoutes);

  // Error handling middleware (must be last)
  app.use(notFoundHandler);
  app.use((error: unknown, req: Request, res: Response, next: NextFunction) => {
    if (!req.path.startsWith(`${config.apiPrefix}/v1/`)) return next(error);
    const status = (error as { status?: number }).status;
    const failure =
      status === 400
        ? new DomainError("INVALID_JSON", "Body JSON tidak valid.")
        : status === 413
          ? new DomainError("UPLOAD_TOO_LARGE", "Body melebihi batas.", 413)
          : error;
    return domainErrorHandler(failure, req, res, next);
  });
  app.use(errorHandler);

  return app;
};
