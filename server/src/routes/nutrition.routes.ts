import { Router } from 'express';
import { daily } from '../controllers/nutrition.controller';
const router = Router();
router.get('/daily', daily);
export default router;
