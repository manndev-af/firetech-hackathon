import { Prisma, NutritionProfile } from '../generated/prisma/client';
import { getPrismaClient } from '../config/prisma';
import { allergens, priorities, profilePatchSchema, timezoneValid, validate } from '../validation/nutrition';
import { DomainError } from '../utils/domainError';

export function mergeProfile(profile: NutritionProfile, input: unknown) {
  // Validate before merging; unknown properties must be rejected, never silently stripped.
  const patch = { ...(input as Record<string, unknown>) };
  for (const key of ['name', 'otherAllergies']) if (typeof patch[key] === 'string') patch[key] = patch[key].trim();
  validate(profilePatchSchema, patch);
  if (patch.timezone && !timezoneValid(patch.timezone as string)) throw new DomainError('INVALID_TIMEZONE', 'Timezone IANA tidak valid.');
  const merged = { ...profile, ...patch } as NutritionProfile;
  const personalization = ['preference', 'priorities', 'eatingPattern', 'prefersHalal', 'allergyStatus', 'allergies', 'otherAllergies'];
  if (personalization.some(key => key in patch) && !(merged.priorities as string[]).length) {
    throw new DomainError('PRIORITY_REQUIRED', 'Pilih minimal satu prioritas.');
  }
  if (merged.allergyStatus === 'listed') {
    if (!(merged.allergies as string[]).length && !merged.otherAllergies) throw new DomainError('ALLERGEN_REQUIRED', 'Pilih bahan atau tulis bahan lain.');
  } else {
    if ((Array.isArray(patch.allergies) && patch.allergies.length) || patch.otherAllergies) throw new DomainError('ALLERGY_CONFLICT', 'Status alergi tidak sesuai bahan yang dikirim.');
    if (personalization.some(key => key in patch)) { patch.allergies = []; patch.otherAllergies = ''; }
  }
  if (patch.priorities) patch.priorities = priorities.filter(value => (patch.priorities as string[]).includes(value));
  if (patch.allergies) patch.allergies = allergens.filter(value => (patch.allergies as string[]).includes(value));
  return patch as Prisma.NutritionProfileUpdateInput;
}

export async function getProfile(userId: string) {
  const profile = await getPrismaClient().nutritionProfile.findUnique({ where: { userId } });
  if (!profile) throw new DomainError('PROFILE_NOT_FOUND', 'Profil belum tersedia.', 503);
  return profile;
}

export async function updateProfile(userId: string, input: unknown) {
  return getPrismaClient().$transaction(async tx => {
    // Serialize merge/read/update so partial updates cannot erase another section.
    await tx.$queryRaw`SELECT userId FROM NutritionProfile WHERE userId = ${userId} FOR UPDATE`;
    const profile = await tx.nutritionProfile.findUniqueOrThrow({ where: { userId } });
    return tx.nutritionProfile.update({ where: { userId }, data: mergeProfile(profile, input) });
  });
}
