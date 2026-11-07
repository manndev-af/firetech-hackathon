import { createHash } from 'node:crypto';
import { getPrismaClient } from '../config/prisma';
import { scannerConfig, providerReady } from '../config/scanner';
import { Prisma } from '../generated/prisma/client';
import { ScanInput } from '../middleware/scanUpload';
import { DomainError } from '../utils/domainError';
import { getProfile } from './profile.service';
import { retrieveContext } from './retrieval.service';
import { callDeepSeek, promptVersion } from './deepseek.service';
import { getEntry, serializeEntry } from './journal.service';

export async function createScan(userId: string, input: ScanInput, provider = callDeepSeek) {
  const db = getPrismaClient();
  const fingerprint = createHash('sha256').update(input.original).update(JSON.stringify(input.fingerprintMetadata)).digest('hex');
  const where = { userId_key: { userId, key: input.key } };
  const replay = (existing: NonNullable<Awaited<ReturnType<typeof db.scanRequest.findUnique>>>) => {
    if (existing.fingerprint !== fingerprint) throw new DomainError('IDEMPOTENCY_CONFLICT', 'Key sudah dipakai untuk input berbeda.', 409);
    if (existing.state === 'deleted') throw new DomainError('ENTRY_DELETED', 'Catatan scan ini sudah dihapus.', 410);
    if (existing.state === 'completed' && existing.entryId) return getEntry(userId, existing.entryId).then(entry => ({ replay: true, entry: serializeEntry(entry) }));
    if (existing.state === 'failed') throw new DomainError(existing.errorCode || 'SCAN_FAILED', 'Scan sebelumnya gagal. Tidak dikirim ulang otomatis.', existing.errorStatus || 502);
    throw new DomainError(existing.state === 'dispatched' ? 'DISPATCH_UNCERTAIN' : 'SCAN_PROCESSING', 'Request sudah diproses atau status pengirimannya belum pasti; tidak dikirim ulang.', 409);
  };
  const existing = await db.scanRequest.findUnique({ where });
  if (existing) return replay(existing);
  let claimed;
  try {
    // Configuration failures before dispatch must not spend or reserve an API call.
    providerReady();
    claimed = await db.scanRequest.create({ data: { userId, key: input.key, fingerprint } });
  } catch (error) {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== 'P2002') throw error;
    return replay(await db.scanRequest.findUniqueOrThrow({ where }));
  }
  try {
    const profile = await getProfile(userId);
    const context = await retrieveContext(userId, profile, input.consumedAt, `${input.description}\n${input.rawOcrText}`);
    await db.scanRequest.update({ where: { id: claimed.id }, data: { state: 'dispatched', dispatchedAt: new Date() } });
    const analysis = await provider(input, context);
    const entry = await db.$transaction(async tx => {
      const created = await tx.foodEntry.create({ data: {
        userId, mode: input.mode, title: analysis.identity, consumedAt: input.consumedAt,
        description: input.description, rawOcrText: input.rawOcrText || null,
        quantity: input.quantity, baseQuantity: analysis.portion.baseQuantity,
        ...analysis.nutrients, provenance: input.mode === 'food' ? 'model_estimate' : 'label_extracted_unverified',
        analysis: JSON.parse(JSON.stringify(analysis)), context: JSON.parse(JSON.stringify(context)),
        model: scannerConfig().model, promptVersion,
      } });
      await tx.scanRequest.update({ where: { id: claimed.id }, data: { state: 'completed', entryId: created.id } });
      return created;
    });
    return { replay: false, entry: serializeEntry(entry) };
  } catch (error) {
    const failure = error instanceof DomainError ? error : new DomainError('SCAN_STORAGE_FAILED', 'Analisis belum dapat disimpan.', 503);
    try { await db.scanRequest.update({ where: { id: claimed.id }, data: { state: 'failed', errorCode: failure.code, errorStatus: failure.statusCode } }); } catch { /* Dispatch record stays unresolved; it must never cause a provider retry. */ }
    throw failure;
  }
}
