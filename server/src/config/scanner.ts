import { DomainError } from '../utils/domainError';

export function scannerConfig() {
  return {
    enabled: process.env.ENABLE_DEMO_USER === 'true' && ['development', 'test'].includes(process.env.NODE_ENV || 'development'),
    email: process.env.DEMO_USER_EMAIL?.trim().toLowerCase(),
    apiKey: process.env.DEEPSEEK_API_KEY,
    baseUrl: process.env.DEEPSEEK_BASE_URL?.trim().replace(/\/+$/, ''),
    model: process.env.DEEPSEEK_MODEL || 'deepseek-flash',
    timeoutMs: 45000,
    maxResponseBytes: 128 * 1024,
  };
}

export function providerReady() {
  const settings = scannerConfig();
  if (!settings.apiKey || !settings.baseUrl) throw new DomainError('PROVIDER_NOT_CONFIGURED', 'DeepSeek belum dikonfigurasi.', 503);
  try {
    const url = new URL(settings.baseUrl);
    if (!['https:', 'http:'].includes(url.protocol) || url.username || url.password || url.search || url.hash) throw new Error('Invalid base URL');
  } catch {
    throw new DomainError('PROVIDER_NOT_CONFIGURED', 'Base URL DeepSeek tidak valid.', 503);
  }
}
