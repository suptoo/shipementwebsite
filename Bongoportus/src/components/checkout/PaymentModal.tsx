import React, { useState, useEffect } from 'react';
import {
  X, CreditCard, Smartphone, Check, Shield, Lock,
  AlertCircle, Loader2, CheckCircle2, Sparkles
} from 'lucide-react';

// Card brand detection based on card number prefix
const getCardBrand = (number: string): 'visa' | 'mastercard' | 'unknown' => {
  const cleanNumber = number.replace(/\s/g, '');
  if (cleanNumber.startsWith('4')) return 'visa';
  if (/^5[1-5]/.test(cleanNumber) || /^2[2-7]/.test(cleanNumber)) return 'mastercard';
  // Accept any 16-digit number as valid card
  if (cleanNumber.length >= 13) return cleanNumber.startsWith('4') ? 'visa' : 'mastercard';
  return 'unknown';
};

// Format card number with spaces
const formatCardNumber = (value: string): string => {
  const v = value.replace(/\s+/g, '').replace(/[^0-9]/gi, '');
  const matches = v.match(/\d{4,16}/g);
  const match = (matches && matches[0]) || '';
  const parts = [];
  for (let i = 0, len = match.length; i < len; i += 4) {
    parts.push(match.substring(i, i + 4));
  }
  return parts.length ? parts.join(' ') : v;
};

// Format expiry date
const formatExpiry = (value: string): string => {
  const v = value.replace(/\s+/g, '').replace(/[^0-9]/gi, '');
  if (v.length >= 2) {
    return v.substring(0, 2) + '/' + v.substring(2, 4);
  }
  return v;
};

// Validate card number - Accept any 13-19 digit number for demo
const validateCardNumber = (number: string): boolean => {
  const cleanNumber = number.replace(/\s/g, '');
  // Accept any card number with 13-19 digits for demo purposes
  return cleanNumber.length >= 13 && cleanNumber.length <= 19 && /^\d+$/.test(cleanNumber);
};

// Validate expiry date format (MM/YY)
const validateExpiry = (expiry: string): boolean => {
  if (!/^\d{2}\/\d{2}$/.test(expiry)) return false;
  const [month, year] = expiry.split('/').map(Number);
  if (month < 1 || month > 12) return false;
  // Accept any future or past date for demo
  return true;
};

// Validate mobile number (Bangladesh format)
const validateMobileNumber = (number: string): boolean => {
  const cleanNumber = number.replace(/\D/g, '');
  // Accept any 10-11 digit number starting with valid BD prefixes or any number for demo
  return cleanNumber.length >= 10 && cleanNumber.length <= 11;
};

// Validate transaction ID format
const validateTransactionId = (txnId: string): boolean => {
  // Accept any alphanumeric string with 6+ characters
  return txnId.length >= 6 && /^[A-Za-z0-9]+$/.test(txnId);
};

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (paymentDetails: PaymentDetails) => void;
  amount: number;
  paymentMethod: 'card' | 'mobile';
}

export interface PaymentDetails {
  method: 'visa' | 'mastercard' | 'bkash' | 'nagad' | 'upay';
  transactionId: string;
  last4: string;
  timestamp: string;
  accountNumber?: string;
}

type MobileProvider = 'bkash' | 'nagad' | 'upay';

export const PaymentModal: React.FC<PaymentModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  amount,
  paymentMethod
}) => {
  // Card payment state
  const [cardNumber, setCardNumber] = useState('');
  const [cardName, setCardName] = useState('');
  const [expiry, setExpiry] = useState('');
  const [cvv, setCvv] = useState('');
  const [cardBrand, setCardBrand] = useState<'visa' | 'mastercard' | 'unknown'>('unknown');

  // Mobile payment state
  const [mobileProvider, setMobileProvider] = useState<MobileProvider>('bkash');
  const [mobileNumber, setMobileNumber] = useState('');
  const [pin, setPin] = useState('');
  const [otp, setOtp] = useState('');
  const [transactionId, setTransactionId] = useState('');
  const [mobileStep, setMobileStep] = useState<'input' | 'otp' | 'txn' | 'processing'>('input');

  // Common state
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [progressStep, setProgressStep] = useState(0);

  // Reset state when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setCardNumber('');
      setCardName('');
      setExpiry('');
      setCvv('');
      setMobileNumber('');
      setPin('');
      setOtp('');
      setTransactionId('');
      setMobileStep('input');
      setProcessing(false);
      setError(null);
      setSuccess(false);
      setProgressStep(0);
    }
  }, [isOpen]);

  // Update card brand when card number changes
  useEffect(() => {
    setCardBrand(getCardBrand(cardNumber));
  }, [cardNumber]);

  // Generate fake transaction ID
  const generateTransactionId = (): string => {
    const prefix = paymentMethod === 'card' ? 'TXN' : mobileProvider.toUpperCase();
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `${prefix}${timestamp}${random}`;
  };

  // Get provider display name
  const getProviderName = (provider: MobileProvider): string => {
    switch (provider) {
      case 'bkash': return 'bKash';
      case 'nagad': return 'Nagad';
      case 'upay': return 'Upay';
      default: return provider;
    }
  };

  // Get provider colors
  const getProviderColors = (provider: MobileProvider) => {
    switch (provider) {
      case 'bkash':
        return {
          gradient: 'from-pink-600 to-pink-700',
          bg: 'bg-pink-600',
          bgLight: 'bg-pink-100',
          bgLighter: 'bg-pink-50',
          border: 'border-pink-500',
          borderLight: 'border-pink-200',
          text: 'text-pink-600',
          textDark: 'text-pink-700',
          shadow: 'shadow-pink-500/25',
          ring: 'focus:ring-pink-500',
          hover: 'hover:border-pink-300',
          buttonGradient: 'from-pink-600 to-pink-700 hover:from-pink-700 hover:to-pink-800'
        };
      case 'nagad':
        return {
          gradient: 'from-orange-500 to-orange-600',
          bg: 'bg-orange-500',
          bgLight: 'bg-orange-100',
          bgLighter: 'bg-orange-50',
          border: 'border-orange-500',
          borderLight: 'border-orange-200',
          text: 'text-orange-500',
          textDark: 'text-orange-700',
          shadow: 'shadow-orange-500/25',
          ring: 'focus:ring-orange-500',
          hover: 'hover:border-orange-300',
          buttonGradient: 'from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700'
        };
      case 'upay':
        return {
          gradient: 'from-blue-500 to-blue-600',
          bg: 'bg-blue-500',
          bgLight: 'bg-blue-100',
          bgLighter: 'bg-blue-50',
          border: 'border-blue-500',
          borderLight: 'border-blue-200',
          text: 'text-blue-500',
          textDark: 'text-blue-700',
          shadow: 'shadow-blue-500/25',
          ring: 'focus:ring-blue-500',
          hover: 'hover:border-blue-300',
          buttonGradient: 'from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700'
        };
    }
  };

  const providerColors = getProviderColors(mobileProvider);

  // Simulate card payment processing - NO VALIDATION, ALWAYS SUCCEEDS
  const processCardPayment = async () => {
    setError(null);
    setProcessing(true);

    const cleanCardNumber = cardNumber.replace(/\s/g, '') || '4242424242424242';

    // Determine card brand - default to visa
    let finalCardBrand: 'visa' | 'mastercard' = 'visa';
    if (cleanCardNumber.startsWith('5')) {
      finalCardBrand = 'mastercard';
    }

    // Quick processing animation
    const steps = ['Processing...', 'Verifying...', 'Success!'];
    for (let i = 0; i < steps.length; i++) {
      setProgressStep(i + 1);
      await new Promise(resolve => setTimeout(resolve, 400));
    }

    // ALWAYS succeed - no validation
    setSuccess(true);

    // Stay on success screen for 30 SECONDS so user can take screenshots
    setTimeout(() => {
      onSuccess({
        method: finalCardBrand,
        transactionId: generateTransactionId(),
        last4: cleanCardNumber.slice(-4) || '0000',
        timestamp: new Date().toISOString()
      });
    }, 30000); // 30 seconds for screenshot time
  };

  // Simulate mobile payment processing - NO VALIDATION, ALWAYS SUCCEEDS
  const processMobilePayment = async () => {
    setError(null);
    setProcessing(true);
    setMobileStep('processing');

    const cleanNumber = mobileNumber || '01700000000';
    const txnId = transactionId || generateTransactionId();

    // Quick processing animation
    const steps = ['Processing...', 'Verifying...', 'Success!'];
    for (let i = 0; i < steps.length; i++) {
      setProgressStep(i + 1);
      await new Promise(resolve => setTimeout(resolve, 400));
    }

    // ALWAYS succeed - no validation
    setSuccess(true);

    // Stay on success screen for 30 SECONDS so user can take screenshots
    setTimeout(() => {
      onSuccess({
        method: mobileProvider,
        transactionId: txnId.toUpperCase() || generateTransactionId(),
        last4: cleanNumber.slice(-4) || '0000',
        timestamp: new Date().toISOString(),
        accountNumber: cleanNumber
      });
    }, 30000); // 30 seconds for screenshot time
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={!processing ? onClose : undefined}
      />

      {/* Modal */}
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
        {/* Header */}
        <div className={`px-6 py-4 ${paymentMethod === 'card'
          ? 'bg-gradient-to-r from-slate-800 to-slate-900'
          : `bg-gradient-to-r ${providerColors.gradient}`
          }`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {paymentMethod === 'card' ? (
                <div className="p-2 bg-white/10 rounded-lg">
                  <CreditCard className="w-6 h-6 text-white" />
                </div>
              ) : (
                <div className="p-2 bg-white/20 rounded-lg">
                  <Smartphone className="w-6 h-6 text-white" />
                </div>
              )}
              <div>
                <h3 className="text-white font-semibold text-lg">
                  {paymentMethod === 'card' ? 'Card Payment' : `${getProviderName(mobileProvider)} Payment`}
                </h3>
                <p className="text-white/70 text-sm">Secure Payment Gateway</p>
              </div>
            </div>
            {!processing && (
              <button
                onClick={onClose}
                className="p-2 hover:bg-white/10 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-white" />
              </button>
            )}
          </div>
        </div>

        {/* Amount Display */}
        <div className="px-6 py-4 bg-gradient-to-r from-slate-50 to-slate-100 border-b">
          <div className="flex items-center justify-between">
            <span className="text-slate-600">Amount to Pay</span>
            <span className="text-2xl font-bold text-slate-800">৳{amount.toFixed(2)}</span>
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          {success ? (
            // Success State
            <div className="text-center py-8">
              <div className="w-20 h-20 mx-auto mb-4 bg-green-100 rounded-full flex items-center justify-center">
                <CheckCircle2 className="w-12 h-12 text-green-500" />
              </div>
              <h4 className="text-xl font-bold text-green-600 mb-2">Payment Successful!</h4>
              <p className="text-slate-600 mb-4">Your payment has been processed successfully.</p>
              <div className="flex items-center justify-center gap-2 text-sm text-slate-500">
                <Sparkles className="w-4 h-4" />
                <span>Redirecting to order confirmation...</span>
              </div>
            </div>
          ) : processing && paymentMethod === 'card' ? (
            // Card Processing State
            <div className="text-center py-8">
              <div className="w-16 h-16 mx-auto mb-4 relative">
                <div className="absolute inset-0 border-4 border-blue-200 rounded-full"></div>
                <div className="absolute inset-0 border-4 border-blue-600 rounded-full border-t-transparent animate-spin"></div>
                <Lock className="w-6 h-6 text-blue-600 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
              </div>
              <h4 className="text-lg font-semibold text-slate-800 mb-2">Processing Payment</h4>
              <div className="space-y-2">
                {['Connecting...', 'Verifying...', 'Authenticating...', 'Processing...', 'Finalizing...'].map((step, idx) => (
                  <div key={idx} className={`flex items-center justify-center gap-2 text-sm transition-all duration-300 ${idx + 1 <= progressStep ? 'text-green-600' : idx + 1 === progressStep + 1 ? 'text-blue-600' : 'text-slate-400'
                    }`}>
                    {idx + 1 < progressStep ? (
                      <Check className="w-4 h-4" />
                    ) : idx + 1 === progressStep ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <div className="w-4 h-4" />
                    )}
                    <span>{step}</span>
                  </div>
                ))}
              </div>
            </div>
          ) : mobileStep === 'processing' ? (
            // Mobile Processing State
            <div className="text-center py-8">
              <div className="w-16 h-16 mx-auto mb-4 relative">
                <div className={`absolute inset-0 border-4 ${providerColors.borderLight} rounded-full`}></div>
                <div className={`absolute inset-0 border-4 ${providerColors.border} rounded-full border-t-transparent animate-spin`}></div>
                <Smartphone className={`w-6 h-6 ${providerColors.text} absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2`} />
              </div>
              <h4 className="text-lg font-semibold text-slate-800 mb-2">Processing {getProviderName(mobileProvider)} Payment</h4>
              <div className="space-y-2">
                {[`Connecting to ${getProviderName(mobileProvider)}...`, 'Verifying Transaction...', 'Processing...', 'Confirming...', 'Success!'].map((step, idx) => (
                  <div key={idx} className={`flex items-center justify-center gap-2 text-sm transition-all duration-300 ${idx + 1 <= progressStep ? 'text-green-600' : idx + 1 === progressStep + 1 ? providerColors.text : 'text-slate-400'
                    }`}>
                    {idx + 1 < progressStep ? (
                      <Check className="w-4 h-4" />
                    ) : idx + 1 === progressStep ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <div className="w-4 h-4" />
                    )}
                    <span>{step}</span>
                  </div>
                ))}
              </div>
            </div>
          ) : paymentMethod === 'card' ? (
            // Card Form
            <div className="space-y-4">
              {/* Card Preview */}
              <div className={`relative h-44 rounded-xl p-5 text-white overflow-hidden ${cardBrand === 'visa'
                ? 'bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-800'
                : cardBrand === 'mastercard'
                  ? 'bg-gradient-to-br from-orange-500 via-red-500 to-red-600'
                  : 'bg-gradient-to-br from-slate-600 to-slate-800'
                }`}>
                <div className="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
                <div className="absolute bottom-0 left-0 w-32 h-32 bg-white/5 rounded-full translate-y-1/2 -translate-x-1/2" />

                <div className="relative z-10 h-full flex flex-col justify-between">
                  <div className="flex justify-between items-start">
                    <div className="w-12 h-9 bg-gradient-to-br from-yellow-200 to-yellow-400 rounded-md" />
                    {cardBrand === 'visa' ? (
                      <span className="text-2xl font-bold italic tracking-wider">VISA</span>
                    ) : cardBrand === 'mastercard' ? (
                      <div className="flex -space-x-3">
                        <div className="w-8 h-8 bg-red-500 rounded-full opacity-90" />
                        <div className="w-8 h-8 bg-yellow-500 rounded-full opacity-90" />
                      </div>
                    ) : (
                      <CreditCard className="w-8 h-8 opacity-50" />
                    )}
                  </div>

                  <div>
                    <div className="text-lg tracking-[0.2em] font-mono mb-3">
                      {cardNumber || '•••• •••• •••• ••••'}
                    </div>
                    <div className="flex justify-between text-sm">
                      <div>
                        <div className="text-white/60 text-xs mb-0.5">Card Holder</div>
                        <div className="font-medium uppercase tracking-wide">
                          {cardName || 'YOUR NAME'}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-white/60 text-xs mb-0.5">Expires</div>
                        <div className="font-medium">{expiry || 'MM/YY'}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Card Number */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1.5">Card Number</label>
                <div className="relative">
                  <input
                    type="text"
                    value={cardNumber}
                    onChange={(e) => setCardNumber(formatCardNumber(e.target.value))}
                    placeholder="1234 5678 9012 3456"
                    maxLength={19}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 pr-12"
                  />
                  <div className="absolute right-3 top-1/2 -translate-y-1/2">
                    {cardBrand === 'visa' && (
                      <span className="text-xs font-bold text-blue-600 italic">VISA</span>
                    )}
                    {cardBrand === 'mastercard' && (
                      <div className="flex -space-x-1">
                        <div className="w-4 h-4 bg-red-500 rounded-full" />
                        <div className="w-4 h-4 bg-yellow-500 rounded-full" />
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Cardholder Name */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1.5">Cardholder Name</label>
                <input
                  type="text"
                  value={cardName}
                  onChange={(e) => setCardName(e.target.value.toUpperCase())}
                  placeholder="JOHN DOE"
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              {/* Expiry & CVV */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1.5">Expiry Date</label>
                  <input
                    type="text"
                    value={expiry}
                    onChange={(e) => setExpiry(formatExpiry(e.target.value))}
                    placeholder="MM/YY"
                    maxLength={5}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1.5">CVV</label>
                  <input
                    type="password"
                    value={cvv}
                    onChange={(e) => setCvv(e.target.value.replace(/\D/g, '').slice(0, 4))}
                    placeholder="•••"
                    maxLength={4}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>

              {/* Error Message */}
              {error && (
                <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  {error}
                </div>
              )}



              {/* Submit Button */}
              <button
                onClick={processCardPayment}
                disabled={processing}
                className="w-full py-3.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg shadow-blue-500/25"
              >
                <Lock className="w-4 h-4" />
                Pay ৳{amount.toFixed(2)}
              </button>

              {/* Security Badge */}
              <div className="flex items-center justify-center gap-2 text-xs text-slate-500">
                <Shield className="w-4 h-4" />
                <span>256-bit SSL Encrypted • PCI DSS Compliant</span>
              </div>
            </div>
          ) : (
            // Mobile Payment Form
            <div className="space-y-4">
              {/* Provider Selection */}
              {mobileStep === 'input' && (
                <div className="grid grid-cols-3 gap-2 mb-4">
                  <button
                    onClick={() => setMobileProvider('bkash')}
                    className={`p-3 rounded-xl border-2 transition-all ${mobileProvider === 'bkash'
                      ? 'border-pink-500 bg-pink-50'
                      : 'border-slate-200 hover:border-pink-300'
                      }`}
                  >
                    <div className="flex flex-col items-center gap-1">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${mobileProvider === 'bkash' ? 'bg-pink-600' : 'bg-pink-100'
                        }`}>
                        <span className={`text-lg font-bold ${mobileProvider === 'bkash' ? 'text-white' : 'text-pink-600'}`}>b</span>
                      </div>
                      <span className={`text-sm font-semibold ${mobileProvider === 'bkash' ? 'text-pink-600' : 'text-slate-600'}`}>bKash</span>
                    </div>
                  </button>

                  <button
                    onClick={() => setMobileProvider('nagad')}
                    className={`p-3 rounded-xl border-2 transition-all ${mobileProvider === 'nagad'
                      ? 'border-orange-500 bg-orange-50'
                      : 'border-slate-200 hover:border-orange-300'
                      }`}
                  >
                    <div className="flex flex-col items-center gap-1">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${mobileProvider === 'nagad' ? 'bg-orange-500' : 'bg-orange-100'
                        }`}>
                        <span className={`text-lg font-bold ${mobileProvider === 'nagad' ? 'text-white' : 'text-orange-500'}`}>N</span>
                      </div>
                      <span className={`text-sm font-semibold ${mobileProvider === 'nagad' ? 'text-orange-500' : 'text-slate-600'}`}>Nagad</span>
                    </div>
                  </button>

                  <button
                    onClick={() => setMobileProvider('upay')}
                    className={`p-3 rounded-xl border-2 transition-all ${mobileProvider === 'upay'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-slate-200 hover:border-blue-300'
                      }`}
                  >
                    <div className="flex flex-col items-center gap-1">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${mobileProvider === 'upay' ? 'bg-blue-500' : 'bg-blue-100'
                        }`}>
                        <span className={`text-lg font-bold ${mobileProvider === 'upay' ? 'text-white' : 'text-blue-500'}`}>U</span>
                      </div>
                      <span className={`text-sm font-semibold ${mobileProvider === 'upay' ? 'text-blue-500' : 'text-slate-600'}`}>Upay</span>
                    </div>
                  </button>
                </div>
              )}

              {mobileStep === 'input' ? (
                <>
                  {/* Mobile Number */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">
                      {getProviderName(mobileProvider)} Account Number
                    </label>
                    <div className="relative">
                      <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500">+880</span>
                      <input
                        type="tel"
                        value={mobileNumber}
                        onChange={(e) => setMobileNumber(e.target.value.replace(/\D/g, '').slice(0, 11))}
                        placeholder="1XXXXXXXXX"
                        className={`w-full pl-16 pr-4 py-3 border border-slate-300 rounded-lg focus:ring-2 ${providerColors.ring} focus:border-transparent`}
                      />
                    </div>
                  </div>

                  {/* PIN */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">PIN</label>
                    <input
                      type="password"
                      value={pin}
                      onChange={(e) => setPin(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      placeholder="Enter your PIN"
                      maxLength={6}
                      className={`w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 ${providerColors.ring} focus:border-transparent`}
                    />
                  </div>
                </>
              ) : mobileStep === 'otp' ? (
                <>
                  {/* OTP Sent Message */}
                  <div className={`p-4 rounded-lg ${providerColors.bgLighter}`}>
                    <div className="flex items-center gap-3">
                      <div className={`p-2 rounded-full ${providerColors.bgLight}`}>
                        <Check className={`w-5 h-5 ${providerColors.text}`} />
                      </div>
                      <div>
                        <p className={`font-medium ${providerColors.textDark}`}>
                          OTP Sent!
                        </p>
                        <p className="text-sm text-slate-600">
                          A verification code has been sent to +880{mobileNumber}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* OTP Input */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">Enter OTP</label>
                    <input
                      type="text"
                      value={otp}
                      onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      placeholder="Enter 4-6 digit OTP"
                      maxLength={6}
                      className={`w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 ${providerColors.ring} focus:border-transparent text-center text-2xl tracking-[0.5em] font-mono`}
                    />
                  </div>

                  {/* Resend OTP */}
                  <button
                    onClick={() => setOtp('')}
                    className="text-sm text-blue-600 hover:underline"
                  >
                    Didn't receive the code? Resend OTP
                  </button>
                </>
              ) : mobileStep === 'txn' ? (
                <>
                  {/* Transaction ID Entry */}
                  <div className={`p-4 rounded-lg ${providerColors.bgLighter} border ${providerColors.borderLight}`}>
                    <div className="flex items-center gap-3 mb-3">
                      <div className={`p-2 rounded-full ${providerColors.bgLight}`}>
                        <CheckCircle2 className={`w-5 h-5 ${providerColors.text}`} />
                      </div>
                      <div>
                        <p className={`font-medium ${providerColors.textDark}`}>
                          OTP Verified!
                        </p>
                        <p className="text-sm text-slate-600">
                          Now enter your Transaction ID from {getProviderName(mobileProvider)}
                        </p>
                      </div>
                    </div>
                    <div className="bg-white/80 rounded-lg p-3 text-sm">
                      <p className="text-slate-600 mb-2">📱 Open your {getProviderName(mobileProvider)} app and complete the payment:</p>
                      <ol className="list-decimal list-inside text-slate-500 space-y-1 text-xs">
                        <li>Open {getProviderName(mobileProvider)} App → Send Money/Payment</li>
                        <li>Send <span className="font-bold text-green-600">৳{amount.toFixed(2)}</span> to merchant</li>
                        <li>Copy the Transaction ID from confirmation</li>
                        <li>Paste it below to complete your order</li>
                      </ol>
                    </div>
                  </div>

                  {/* Transaction ID Input */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">
                      Transaction ID / TrxID
                    </label>
                    <input
                      type="text"
                      value={transactionId}
                      onChange={(e) => setTransactionId(e.target.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase())}
                      placeholder="e.g., ABC123XYZ789"
                      className={`w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 ${providerColors.ring} focus:border-transparent font-mono text-center tracking-wider uppercase`}
                    />
                    <p className="text-xs text-slate-500 mt-1">
                      Enter the Transaction ID exactly as shown in your {getProviderName(mobileProvider)} app
                    </p>
                  </div>
                </>
              ) : null}

              {/* Error Message */}
              {error && (
                <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  {error}
                </div>
              )}

              {/* Test Info */}
              {mobileStep === 'input' && (
                <div className={`p-3 rounded-lg ${providerColors.bgLighter} border ${providerColors.borderLight}`}>
                  <p className={`text-xs font-medium mb-1 ${providerColors.textDark}`}>
                    🧪 Demo Mode - Use any details
                  </p>
                  <p className={`text-xs ${providerColors.text}`}>
                    Enter any 10-11 digit number and 4+ digit PIN
                  </p>
                </div>
              )}

              {mobileStep === 'otp' && (
                <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                  <p className="text-xs text-green-700 font-medium mb-1">🧪 Demo Mode</p>
                  <p className="text-xs text-green-600">Enter any 4-6 digit code (e.g., 1234)</p>
                </div>
              )}

              {mobileStep === 'txn' && (
                <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg">
                  <p className="text-xs text-emerald-700 font-medium mb-1">🧪 Demo Mode</p>
                  <p className="text-xs text-emerald-600">Enter any alphanumeric Transaction ID (min 6 characters, e.g., TXN123ABC)</p>
                </div>
              )}

              {/* Submit Button */}
              {(mobileStep === 'input' || mobileStep === 'otp' || mobileStep === 'txn') && (
                <button
                  onClick={processMobilePayment}
                  disabled={processing}
                  className={`w-full py-3.5 font-semibold rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg bg-gradient-to-r ${providerColors.buttonGradient} text-white ${providerColors.shadow}`}
                >
                  {processing ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      {mobileStep === 'input' ? 'Sending OTP...' : mobileStep === 'otp' ? 'Verifying OTP...' : 'Processing...'}
                    </>
                  ) : (
                    <>
                      {mobileStep === 'input' ? (
                        <>
                          <Smartphone className="w-4 h-4" />
                          Send OTP
                        </>
                      ) : mobileStep === 'otp' ? (
                        <>
                          <Check className="w-4 h-4" />
                          Verify OTP
                        </>
                      ) : (
                        <>
                          <Lock className="w-4 h-4" />
                          Complete Payment ৳{amount.toFixed(2)}
                        </>
                      )}
                    </>
                  )}
                </button>
              )}

              {/* Security Badge */}
              <div className="flex items-center justify-center gap-2 text-xs text-slate-500">
                <Shield className="w-4 h-4" />
                <span>Secured by {getProviderName(mobileProvider)} Payment Gateway</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PaymentModal;
