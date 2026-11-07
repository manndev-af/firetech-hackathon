import dotenv from 'dotenv';

dotenv.config();

interface Config {
  env: string;
  port: number;
  corsOrigin: string | string[];
  apiPrefix: string;
  rateLimit: {
    windowMs: number;
    maxRequests: number;
  };
}

export const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  apiPrefix: process.env.API_PREFIX || '/api',
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  },
};

Object.keys(config).forEach((key) => {
  if (config[key as keyof Config] === undefined ) {
    throw new Error(`Missing configuration for ${key}`);
  }
});
