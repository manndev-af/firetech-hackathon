import { getPrismaClient } from '../config/prisma';
import { NutritionProfile } from '../generated/prisma/client';
import { dayBounds, localDate, summarize, totals } from './journal.service';

export async function retrieveContext(userId: string, profile: NutritionProfile, consumedAt: Date, text: string) {
  const db = getPrismaClient();
  const date = localDate(consumedAt, profile.timezone);
  const { start } = dayBounds(date, profile.timezone);
  const words = [...new Set(text.toLowerCase().match(/[\p{L}]{3,}/gu) || [])].slice(0, 12);
  const profileContext = { priorities: profile.priorities, preference: profile.preference,
    eatingPattern: profile.eatingPattern, prefersHalal: profile.prefersHalal,
    allergyStatus: profile.allergyStatus, allergies: profile.allergies, otherAllergies: profile.otherAllergies };
  const [today, candidates, sources] = await Promise.all([
    db.foodEntry.findMany({ where: { userId, consumedAt: { gte: start, lt: consumedAt } } }),
    db.foodEntry.findMany({ where: { userId, consumedAt: { gte: new Date(consumedAt.getTime() - 7 * 86400000), lt: consumedAt } },
      orderBy: [{ consumedAt: 'desc' }, { id: 'asc' }], take: 100 }),
    db.knowledgeChunk.findMany({ where: { reviewed: true, reviewedAt: { not: null }, OR: [
      ...words.map(word => ({ text: { contains: word } })),
      ...(profile.priorities as string[]).map(tag => ({ tags: { array_contains: tag } })),
    ] }, orderBy: { id: 'asc' }, take: 100 }),
  ]);
  const score = (value: string) => words.filter(word => value.toLowerCase().includes(word)).length;
  const history = candidates.sort((a, b) => score(b.title) - score(a.title) || b.consumedAt.getTime() - a.consumedAt.getTime() || a.id.localeCompare(b.id)).slice(0, 5)
    .map(entry => ({ id: entry.id, title: entry.title.slice(0, 160), consumedAt: entry.consumedAt.toISOString(), nutrients: totals(entry), provenance: entry.provenance }));
  const references = sources.sort((a, b) => score(b.text) - score(a.text) || a.id.localeCompare(b.id)).slice(0, 3)
    .map(source => ({ id: source.id, title: source.title, text: source.text, sourceUrl: source.sourceUrl,
      sourceTitle: source.sourceTitle, version: source.version, reviewedAt: source.reviewedAt?.toISOString() }));
  const context = { snapshotAt: new Date().toISOString(), beforeConsumedAt: consumedAt.toISOString(), date, timezone: profile.timezone,
    profile: profileContext, recordedDaily: summarize(today), history, references,
    historyAvailable: candidates.length > 0, referencesAvailable: references.length > 0 };
  // ponytail: bounded SQL/text retrieval for a small corpus; add embeddings when semantic matching is needed.
  while (JSON.stringify(context).length > 8000 && context.references.length) context.references.pop();
  while (JSON.stringify(context).length > 8000 && context.history.length) context.history.pop();
  context.referencesAvailable = context.references.length > 0;
  return context;
}
export type RetrievalContext = Awaited<ReturnType<typeof retrieveContext>>;
