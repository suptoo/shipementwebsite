import { loadStripe, Stripe } from '@stripe/stripe-js';

const STRIPE_PUBLISHABLE_KEY = import.meta.env.VITE_STRIPE_PUBLIC_KEY || 'pk_test_51SW3Uz9PPh298IzgrsZdptzlVaEMGZkepdF8flAMFqdhk75FV1KEgUflIqurFxMfjygcst3H0YgiG6tNGBoYhFo800AQ29C25U';

let stripePromise: Promise<Stripe | null>;

export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(STRIPE_PUBLISHABLE_KEY);
  }
  return stripePromise;
};

export interface CreatePaymentIntentParams {
  amount: number; // in cents
  currency?: string;
  orderId: string;
  customerId?: string;
  customerEmail?: string;
  metadata?: Record<string, string>;
}

export interface StripePaymentResult {
  success: boolean;
  paymentIntentId?: string;
  error?: string;
}

// Helper to format amount for Stripe (convert to cents)
export const formatAmountForStripe = (amount: number, currency: string = 'usd'): number => {
  return Math.round(amount * 100);
};

// Helper to format amount from Stripe (convert from cents)
export const formatAmountFromStripe = (amount: number, currency: string = 'usd'): number => {
  return amount / 100;
};
