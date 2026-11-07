import { Router } from 'express';
import { HealthController } from '../controllers';

const router = Router();
const healthController = new HealthController();

router.get('/', healthController.getHealth);
router.get('/readiness', healthController.getReadiness);
router.get('/liveness', healthController.getLiveness);

export default router;
