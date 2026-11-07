import { Router } from 'express';
import { entries, entry, quantity, removeEntry } from '../controllers/nutrition.controller';
const router = Router();
router.get('/', entries);
router.get('/:id', entry);
router.patch('/:id/quantity', quantity);
router.delete('/:id', removeEntry);
export default router;
