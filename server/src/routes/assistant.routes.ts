import { Router } from 'express';
import { assistantMessage } from '../controllers/assistant.controller';
import { scanSlot } from '../middleware/scanUpload';

const router = Router();
router.post('/messages', scanSlot, assistantMessage);
export default router;
