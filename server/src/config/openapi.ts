import { config } from './config';
import { healthPaths } from '../routes/health.openapi';
import { userPaths } from '../routes/user.openapi';
import { profilePaths } from '../routes/profile.openapi';
import { scannerPaths } from '../routes/scanner.openapi';
import { foodEntryPaths } from '../routes/food-entry.openapi';
import { nutritionPaths } from '../routes/nutrition.openapi';
import { comparePaths } from '../routes/compare.openapi';
import { assistantPaths } from '../routes/assistant.openapi';

// Route contracts stay beside their routers; this file only assembles metadata.
export const openapi = {
  openapi: '3.0.3',
  info: {
    title: 'NutriLens AI API',
    version: '1.0.0',
    description: 'Current backend routes. Users are in-memory starter examples, not authentication or nutrition profiles.',
  },
  servers: [{ url: '/' }],
  paths: { ...healthPaths(config.apiPrefix), ...userPaths(config.apiPrefix),
    ...profilePaths(config.apiPrefix), ...scannerPaths(config.apiPrefix),
    ...foodEntryPaths(config.apiPrefix), ...nutritionPaths(config.apiPrefix), ...comparePaths(config.apiPrefix), ...assistantPaths(config.apiPrefix) },
};
