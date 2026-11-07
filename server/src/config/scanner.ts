import { DomainError } from '../utils/domainError';

export function scannerConfig() {
  return {
    enabled: process.env.ENABLE_DEMO_USER === 'true' && ['development', 'test'].includes(process.env.NODE_ENV || 'development'),
    email: process.env.DEMO_USER_EMAIL?.trim().toLowerCase(),
    apiKey: process.env.DEEPSEEK_API_KEY,
    model: process.env.DEEPSEEK_MODEL || 'deepseek-flash',
    timeoutMs: 45000,
    maxResponseBytes: 128 * 1024,
  };
}

export function providerReady() {
  if (!scannerConfig().apiKey) throw new DomainError('PROVIDER_NOT_CONFIGURED', 'DeepSeek belum dikonfigurasi.', 503);
}
