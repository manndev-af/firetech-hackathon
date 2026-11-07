import { Router } from 'express';
import healthRoutes from './health.routes';
import userRoutes from './user.routes';
import profileRoutes from './profile.routes';
import { demoOwner } from '../middleware/demoOwner';
import { domainErrorHandler } from '../utils/domainError';

const router = Router();

// Mount routes
router.use('/health', healthRoutes);
router.use('/users', userRoutes);
const domain = Router();
domain.use(demoOwner);
domain.use('/profile', profileRoutes);
domain.use(domainErrorHandler);
router.use('/v1', domain);

export default router;
