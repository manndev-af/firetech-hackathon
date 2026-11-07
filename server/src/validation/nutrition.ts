import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import { DomainError } from '../utils/domainError';

export const priorities = ['Gula', 'Natrium', 'Protein', 'Kalori', 'Keseimbangan'];
export const preferences = ['Masakan rumahan', 'Praktis dan cepat', 'Lebih banyak nabati'];
export const patterns = ['Fleksibel', 'Vegetarian', 'Vegan', 'Pescatarian'];
export const allergens = ['Susu', 'Telur', 'Kacang tanah', 'Kacang pohon', 'Kedelai', 'Gandum', 'Ikan', 'Kerang / udang'];
export const nutrients = ['calories_kcal', 'protein_g', 'total_fat_g', 'saturated_fat_g', 'carbohydrates_g', 'sugar_g', 'sodium_mg', 'fiber_g'] as const;
export type Nutrient = typeof nutrients[number];
export const units = ['butir', 'biji', 'potong', 'porsi', 'g', 'ml', 'botol', 'kemasan'];
export const ajv = new Ajv({ allErrors: true, strictNumbers: true });
addFormats(ajv);
export const optionalChoice = (values: string[]) => ({ type: ['string', 'null'], enum: [...values, null] });
const choices = (values: string[]) => ({ type: 'array', uniqueItems: true, maxItems: values.length, items: { type: 'string', enum: values } });
export const profileProperties = {
  name: { type: 'string', maxLength: 60 },
  age: { type: ['integer', 'null'], minimum: 1, maximum: 120 },
  heightCm: { type: ['number', 'null'], exclusiveMinimum: 0, maximum: 300 },
  weightKg: { type: ['number', 'null'], exclusiveMinimum: 0, maximum: 700 },
  preference: optionalChoice(preferences), priorities: choices(priorities),
  eatingPattern: optionalChoice(patterns), prefersHalal: { type: 'boolean' },
  allergyStatus: { type: 'string', enum: ['unknown', 'noneKnown', 'listed'] },
  allergies: choices(allergens), otherAllergies: { type: 'string', maxLength: 120 },
  audioAnalysisEnabled: { type: 'boolean' }, timezone: { type: 'string', minLength: 1, maxLength: 64 },
};
export const profilePatchSchema = { type: 'object', additionalProperties: false, minProperties: 1, properties: profileProperties };
export const quantitySchema = { type: 'object', additionalProperties: false, required: ['quantity'], properties: {
  quantity: { type: 'number', minimum: 0.000001, maximum: 10000, multipleOf: 0.000001 },
} };
export function validate(schema: object, value: unknown, code = 'INVALID_INPUT') {
  if (!ajv.validate(schema, value)) throw new DomainError(code, 'Input tidak sesuai kontrak API.');
}
export function timezoneValid(timezone: string) {
  try { new Intl.DateTimeFormat('en', { timeZone: timezone }); return true; } catch { return false; }
}
