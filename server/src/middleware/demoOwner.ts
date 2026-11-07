import { Request, Response, NextFunction } from 'express';
import { scannerConfig } from '../config/scanner';
import { getPrismaClient } from '../config/prisma';
import { DomainError } from '../utils/domainError';

export async function demoOwner(req: Request, res: Response, next: NextFunction) {
  try {
    const settings = scannerConfig();
    if (!settings.enabled) throw new DomainError('DEMO_DISABLED', 'Endpoint development tidak aktif.', 404);
    if (['x-user-id', 'x-owner-id', 'user-id', 'userId', 'ownerId'].some(key => req.get(key)) ||
      ['userId', 'ownerId', 'user_id', 'owner_id'].some(key => key in req.query || (req.body && key in req.body))) {
      throw new DomainError('OWNER_OVERRIDE', 'Pemilik ditentukan server.');
    }
    if (!settings.email) throw new DomainError('DEMO_NOT_CONFIGURED', 'User dummy belum dikonfigurasi.', 503);
    const user = await getPrismaClient().user.findUnique({ where: { email: settings.email }, select: { id: true } });
    if (!user) throw new DomainError('DEMO_NOT_SEEDED', 'Jalankan seed user dummy terlebih dahulu.', 503);
    res.locals.userId = user.id;
    next();
  } catch (error) { next(error); }
}
