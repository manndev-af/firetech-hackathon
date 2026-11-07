import { Router } from 'express';
import healthRoutes from './health.routes';
import userRoutes from './user.routes';
import profileRoutes from './profile.routes';
import scannerRoutes from './scanner.routes';
import foodEntryRoutes from './food-entry.routes';
import nutritionRoutes from './nutrition.routes';
import compareRoutes from './compare.routes';
import assistantRoutes from './assistant.routes';
import { demoOwner } from '../middleware/demoOwner';
import { domainErrorHandler } from '../utils/domainError';

const router = Router();

// Mount routes
router.use('/health', healthRoutes);
router.use('/users', userRoutes);
const domain = Router();
domain.use(demoOwner);
domain.use('/profile', profileRoutes);
domain.use('/scans', scannerRoutes);
domain.use('/food-entries', foodEntryRoutes);
domain.use('/nutrition', nutritionRoutes);
domain.use('/comparisons', compareRoutes);
domain.use('/assistant', assistantRoutes);
domain.use(domainErrorHandler);
router.use('/v1', domain);

export default router;
