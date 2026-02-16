/**
 * Input sanitization and validation utilities.
 * All user input must be validated before processing.
 */

/** Sanitize string input: trim whitespace, limit length, remove control chars */
export function sanitizeString(input: unknown, maxLength = 500): string {
    if (typeof input !== 'string') return '';
    // Remove control characters except newlines/tabs
    return input
        .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
        .trim()
        .slice(0, maxLength);
}

/** Validate UUID format */
export function isValidUUID(str: unknown): boolean {
    if (typeof str !== 'string') return false;
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
}

/** Validate positive number */
export function isPositiveNumber(val: unknown): val is number {
    return typeof val === 'number' && val > 0 && isFinite(val);
}

/** Validate non-negative number */
export function isNonNegativeNumber(val: unknown): val is number {
    return typeof val === 'number' && val >= 0 && isFinite(val);
}

/** Validate integer */
export function isPositiveInteger(val: unknown): val is number {
    return typeof val === 'number' && Number.isInteger(val) && val > 0;
}

/** Validate email format */
export function isValidEmail(str: unknown): boolean {
    if (typeof str !== 'string') return false;
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(str);
}

/** Validate phone number (basic: 10-15 digits) */
export function isValidPhone(str: unknown): boolean {
    if (typeof str !== 'string') return false;
    const digits = str.replace(/\D/g, '');
    return digits.length >= 10 && digits.length <= 15;
}

/** Validate coupon code format */
export function isValidCouponCode(str: unknown): boolean {
    if (typeof str !== 'string') return false;
    return /^[A-Z0-9_-]{3,30}$/i.test(str.trim());
}

/** Validate array and ensure all items pass a check */
export function isValidArray<T>(
    arr: unknown,
    itemValidator: (item: unknown) => item is T,
    minLength = 1,
    maxLength = 100
): arr is T[] {
    if (!Array.isArray(arr)) return false;
    if (arr.length < minLength || arr.length > maxLength) return false;
    return arr.every(itemValidator);
}

/** Rate limiting store (in-memory per function instance) */
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();

/**
 * Simple in-memory rate limiter per function instance.
 * For production, use Redis or Supabase-based rate limiting.
 */
export function checkRateLimit(
    key: string,
    maxRequests = 30,
    windowMs = 60_000
): boolean {
    const now = Date.now();
    const entry = rateLimitMap.get(key);

    if (!entry || now > entry.resetTime) {
        rateLimitMap.set(key, { count: 1, resetTime: now + windowMs });
        return true;
    }

    if (entry.count >= maxRequests) {
        return false;
    }

    entry.count++;
    return true;
}

/** Generate a secure order number */
export function generateOrderNumber(): string {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = crypto.getRandomValues(new Uint8Array(4));
    const randomStr = Array.from(random)
        .map((b) => b.toString(36))
        .join('')
        .toUpperCase()
        .slice(0, 5);
    return `ORD-${timestamp}-${randomStr}`;
}

/** Generate a transaction ID */
export function generateTransactionId(prefix = 'TXN'): string {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = crypto.getRandomValues(new Uint8Array(4));
    const randomStr = Array.from(random)
        .map((b) => b.toString(36))
        .join('')
        .toUpperCase()
        .slice(0, 6);
    return `${prefix}${timestamp}${randomStr}`;
}
