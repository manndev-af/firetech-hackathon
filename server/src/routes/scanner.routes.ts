import { Router } from 'express';
import { scan } from '../controllers/nutrition.controller';
import { scanSlot, scanUpload } from '../middleware/scanUpload';
const router = Router();
router.post('/', scanSlot, scanUpload, scan);
export default router;
