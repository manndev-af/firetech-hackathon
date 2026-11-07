import { Router } from 'express';
import { readProfile, patchProfile } from '../controllers/nutrition.controller';
const router = Router();
router.get('/', readProfile);
router.patch('/', patchProfile);
export default router;
