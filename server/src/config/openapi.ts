import { config } from './config';
import { healthPaths } from '../routes/health.openapi';
import { userPaths } from '../routes/user.openapi';
import { profilePaths } from '../routes/profile.openapi';

// Route contracts stay beside their routers; this file only assembles metadata.
export const openapi = {
  openapi: '3.0.3',
  info: {
    title: 'NutriLens AI API',
    version: '1.0.0',
    description: 'Current backend routes. Users are in-memory starter examples, not authentication or nutrition profiles.',
  },
  servers: [{ url: '/' }],
  paths: { ...healthPaths(config.apiPrefix), ...userPaths(config.apiPrefix), ...profilePaths(config.apiPrefix) },
};
