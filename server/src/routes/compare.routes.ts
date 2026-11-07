import { Router } from 'express';
import { compare } from '../controllers/compare.controller';
import { compareUpload } from '../middleware/compareUpload';
import { scanSlot } from '../middleware/scanUpload';

const router = Router();
router.post('/', scanSlot, compareUpload, compare);
export default router;
