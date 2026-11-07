import { Prisma, FoodEntry } from '../generated/prisma/client';
import { getPrismaClient } from '../config/prisma';
import { Nutrient, nutrients, quantitySchema, timezoneValid, validate } from '../validation/nutrition';
import { DomainError } from '../utils/domainError';

export function localDate(date: Date, timezone: string) {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(date);
  const part = (type: string) => parts.find(value => value.type === type)!.value;
  return `${part('year')}-${part('month')}-${part('day')}`;
}

export function dayBounds(date: string, timezone: string) {
  if (!timezoneValid(timezone) || !/^\d{4}-\d{2}-\d{2}$/.test(date) || date < '2000-01-01' || date > '2100-12-30') throw new DomainError('INVALID_DATE', 'Tanggal atau timezone tidak valid.');
  const midnight = Date.parse(`${date}T00:00:00Z`);
  if (!Number.isFinite(midnight) || new Date(midnight).toISOString().slice(0, 10) !== date) throw new DomainError('INVALID_DATE', 'Tanggal tidak valid.');
  // Find local day boundaries with Intl; handles 23/25-hour DST days without a timezone dependency.
  const boundary = (target: string, anchor: number) => {
    let low = anchor - 36 * 3600000;
    let high = anchor + 36 * 3600000;
    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      if (localDate(new Date(mid), timezone) < target) low = mid + 1; else high = mid;
    }
    return new Date(low);
  };
  const next = new Date(midnight + 86400000).toISOString().slice(0, 10);
  const start = boundary(date, midnight);
  const end = boundary(next, midnight + 86400000);
  if (localDate(start, timezone) !== date) throw new DomainError('INVALID_DATE', 'Tanggal lokal tidak tersedia.');
  return { start, end };
}

export function totals(entry: Pick<FoodEntry, Nutrient | 'quantity' | 'baseQuantity'>) {
  return Object.fromEntries(nutrients.map(key => [key, entry[key] === null ? null : new Prisma.Decimal(entry[key]!).mul(entry.quantity).div(entry.baseQuantity).toDecimalPlaces(6).toNumber()])) as Record<Nutrient, number | null>;
}

export function serializeEntry(entry: FoodEntry) {
  const analysis = entry.analysis as Prisma.JsonObject;
  return { id: entry.id, consumedAt: entry.consumedAt, mode: entry.mode, title: entry.title,
    description: entry.description, rawOcrText: entry.rawOcrText,
    quantity: entry.quantity.toNumber(), baseQuantity: entry.baseQuantity.toNumber(),
    baseNutrients: Object.fromEntries(nutrients.map(key => [key, entry[key]?.toNumber() ?? null])),
    nutrients: totals(entry), provenance: entry.provenance, analysis,
    pros: analysis.advantages ?? [], cons: analysis.tradeoffs ?? [],
    ttsSummary: analysis.ttsSummary, ttsSummarySource: analysis.ttsSummarySource,
    context: entry.context, model: entry.model, promptVersion: entry.promptVersion,
    createdAt: entry.createdAt, updatedAt: entry.updatedAt };
}

export function summarize(entries: FoodEntry[]) {
  return { entryCount: entries.length, recordedIntakeOnly: true, nutrients: Object.fromEntries(nutrients.map(key => {
    let sum = new Prisma.Decimal(0);
    let knownCount = 0;
    const provenanceCounts: Record<string, number> = {};
    for (const entry of entries) {
      if (entry[key] !== null) { sum = sum.add(entry[key]!.mul(entry.quantity).div(entry.baseQuantity)); knownCount++; }
      provenanceCounts[entry.provenance] = (provenanceCounts[entry.provenance] || 0) + 1;
    }
    return [key, { knownTotal: knownCount ? sum.toDecimalPlaces(6).toNumber() : null, knownCount,
      missingCount: entries.length - knownCount, complete: entries.length > 0 && knownCount === entries.length, provenanceCounts }];
  })) };
}

export async function getEntry(userId: string, id: string) {
  const entry = await getPrismaClient().foodEntry.findFirst({ where: { id, userId } });
  if (!entry) throw new DomainError('ENTRY_NOT_FOUND', 'Catatan tidak ditemukan.', 404);
  return entry;
}

export async function updateQuantity(userId: string, id: string, input: unknown) {
  validate(quantitySchema, input);
  const { quantity } = input as { quantity: number };
  const result = await getPrismaClient().foodEntry.updateMany({ where: { id, userId }, data: { quantity } });
  if (!result.count) throw new DomainError('ENTRY_NOT_FOUND', 'Catatan tidak ditemukan.', 404);
  return serializeEntry(await getEntry(userId, id));
}

export async function deleteEntry(userId: string, id: string) {
  await getPrismaClient().$transaction(async tx => {
    await tx.scanRequest.updateMany({ where: { userId, entryId: id }, data: { state: 'deleted' } });
    const result = await tx.foodEntry.deleteMany({ where: { id, userId } });
    if (!result.count) throw new DomainError('ENTRY_NOT_FOUND', 'Catatan tidak ditemukan.', 404);
  });
}

export async function dailySummary(userId: string, date: string, timezone: string) {
  const { start, end } = dayBounds(date, timezone);
  const entries = await getPrismaClient().foodEntry.findMany({ where: { userId, consumedAt: { gte: start, lt: end } } });
  return { date, timezone, ...summarize(entries) };
}

export async function listEntries(userId: string, timezone: string, query: Record<string, unknown>) {
  if (Object.keys(query).some(key => !['date', 'page', 'limit'].includes(key))) throw new DomainError('INVALID_QUERY', 'Parameter daftar tidak didukung.');
  const parse = (value: unknown, fallback: number, maximum: number) => {
    if (value === undefined) return fallback;
    if (typeof value !== 'string' || !/^[1-9]\d*$/.test(value) || Number(value) > maximum) throw new DomainError('INVALID_QUERY', 'Pagination tidak valid.');
    return Number(value);
  };
  const page = parse(query.page, 1, 10000);
  const limit = parse(query.limit, 20, 100);
  let consumedAt;
  if (query.date !== undefined) {
    if (typeof query.date !== 'string') throw new DomainError('INVALID_DATE', 'Tanggal tidak valid.');
    const { start, end } = dayBounds(query.date, timezone);
    consumedAt = { gte: start, lt: end };
  }
  const db = getPrismaClient();
  const where = { userId, consumedAt };
  const [entries, total] = await db.$transaction([
    db.foodEntry.findMany({ where, orderBy: [{ consumedAt: 'desc' }, { id: 'asc' }], skip: (page - 1) * limit, take: limit }),
    db.foodEntry.count({ where }),
  ]);
  return { entries: entries.map(serializeEntry), total, page, limit };
}
