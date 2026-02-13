import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Store, Upload, FileText, Building2, CreditCard, MapPin, Phone, Mail, CheckCircle2, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

export const SellerRegistration: React.FC = () => {
  const navigate = useNavigate();
  const { user, profile } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  // Form state
  const [formData, setFormData] = useState({
    shopName: '',
    businessName: '',
    businessType: 'individual',
    taxId: '',
    phone: '',
    email: user?.email || '',
    address: '',
    city: '',
    postalCode: '',
    bankAccountName: '',
    bankAccountNumber: '',
    bankName: '',
    bankBranch: '',
  });

  const [documents, setDocuments] = useState({
    nid: null as File | null,
    tradeLicense: null as File | null,
    bankStatement: null as File | null,
  });

  if (!user || !profile) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Authentication Required</h2>
          <p className="text-gray-600 mb-6">Please login to register as a seller</p>
          <button
            onClick={() => navigate('/login')}
            className="bg-blue-600 text-white px-6 py-3 rounded-xl font-semibold"
          >
            Go to Login
          </button>
        </div>
      </div>
    );
  }

  if (profile.role === 'seller' || profile.role === 'admin') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <CheckCircle2 className="w-16 h-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Already a Seller</h2>
          <p className="text-gray-600 mb-6">You already have seller access</p>
          <button
            onClick={() => navigate('/admin')}
            className="bg-blue-600 text-white px-6 py-3 rounded-xl font-semibold"
          >
            Go to Dashboard
          </button>
        </div>
      </div>
    );
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>, docType: keyof typeof documents) => {
    if (e.target.files && e.target.files[0]) {
      setDocuments(prev => ({
        ...prev,
        [docType]: e.target.files![0]
      }));
    }
  };

  const uploadDocument = async (file: File, path: string): Promise<string> => {
    const fileExt = file.name.split('.').pop();
    const fileName = `${user!.id}/${path}-${Date.now()}.${fileExt}`;

    const { data, error } = await supabase.storage
      .from('seller-documents')
      .upload(fileName, file);

    if (error) throw error;

    const { data: { publicUrl } } = supabase.storage
      .from('seller-documents')
      .getPublicUrl(fileName);

    return publicUrl;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Validate required fields
      if (!formData.shopName || !formData.businessName || !formData.phone || !formData.address) {
        throw new Error('Please fill in all required fields');
      }

      if (!documents.nid) {
        throw new Error('NID/Passport document is required');
      }

      // Upload documents
      const nidUrl = await uploadDocument(documents.nid, 'nid');
      const tradeLicenseUrl = documents.tradeLicense ? await uploadDocument(documents.tradeLicense, 'trade-license') : null;
      const bankStatementUrl = documents.bankStatement ? await uploadDocument(documents.bankStatement, 'bank-statement') : null;

      // Create seller profile
      const { error: profileError } = await supabase
        .from('seller_profiles')
        .insert({
          user_id: user!.id,
          business_name: formData.businessName,
          business_type: formData.businessType,
          tax_id: formData.taxId || null,
          phone: formData.phone,
          email: formData.email,
          address: formData.address,
          city: formData.city,
          postal_code: formData.postalCode,
          bank_account_name: formData.bankAccountName,
          bank_account_number: formData.bankAccountNumber,
          bank_name: formData.bankName,
          bank_branch: formData.bankBranch,
          verification_documents: {
            nid: nidUrl,
            tradeLicense: tradeLicenseUrl,
            bankStatement: bankStatementUrl,
          },
          verification_status: 'pending',
          is_approved: false,
        });

      if (profileError) throw profileError;

      // Create shop
      const { error: shopError } = await supabase
        .from('shops')
        .insert({
          seller_id: user!.id,
          name: formData.shopName,
          description: `Welcome to ${formData.shopName}`,
          is_active: false, // Will be activated after admin approval
        });

      if (shopError) throw shopError;

      setSuccess(true);
      
      setTimeout(() => {
        navigate('/');
      }, 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to submit application');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-100 p-4">
        <div className="max-w-md w-full bg-white rounded-3xl shadow-2xl p-8 text-center">
          <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-emerald-600 rounded-full flex items-center justify-center mx-auto mb-6">
            <CheckCircle2 className="w-12 h-12 text-white" />
          </div>
          <h2 className="text-3xl font-bold text-gray-900 mb-4">Application Submitted!</h2>
          <p className="text-gray-600 mb-6 leading-relaxed">
            Your seller application has been submitted successfully. Our team will review your documents and get back to you within 24-48 hours via email.
          </p>
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-6">
            <p className="text-sm text-blue-800 font-medium">
              <strong>What's Next?</strong><br />
              1. Admin will verify your documents<br />
              2. You'll receive approval email<br />
              3. Start selling on Bongoportus!
            </p>
          </div>
          <p className="text-sm text-gray-500">Redirecting to home...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white py-8 md:py-12">
      <div className="max-w-4xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-8 md:mb-12">
          <div className="inline-flex items-center gap-3 bg-gradient-to-r from-orange-500 to-red-500 text-white px-6 py-3 rounded-full mb-6 shadow-lg">
            <Store size={24} />
            <span className="font-bold text-lg">Seller Registration</span>
          </div>
          <h1 className="text-3xl md:text-4xl font-extrabold text-gray-900 mb-4">
            Start Your Selling Journey
          </h1>
          <p className="text-gray-600 text-lg max-w-2xl mx-auto">
            Fill in your business details and upload required documents. We'll review your application within 24-48 hours.
          </p>
        </div>

        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
            <p className="text-red-800 text-sm">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Shop Information */}
          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6 md:p-8">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-blue-50 rounded-lg">
                <Store className="w-6 h-6 text-blue-600" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900">Shop Information</h2>
            </div>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Shop Name <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="shopName"
                  value={formData.shopName}
                  onChange={handleInputChange}
                  placeholder="My Amazing Shop"
                  required
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Business Type <span className="text-red-500">*</span>
                </label>
                <select
                  name="businessType"
                  value={formData.businessType}
                  onChange={handleInputChange}
                  required
                  className="input-primary"
                >
                  <option value="individual">Individual</option>
                  <option value="company">Company</option>
                  <option value="partnership">Partnership</option>
                </select>
              </div>
            </div>
          </div>

          {/* Business Details */}
          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6 md:p-8">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-purple-50 rounded-lg">
                <Building2 className="w-6 h-6 text-purple-600" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900">Business Details</h2>
            </div>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Business Name <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="businessName"
                  value={formData.businessName}
                  onChange={handleInputChange}
                  placeholder="ABC Trading Ltd."
                  required
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Tax ID / TIN (Optional)
                </label>
                <input
                  type="text"
                  name="taxId"
                  value={formData.taxId}
                  onChange={handleInputChange}
                  placeholder="123456789"
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Phone Number <span className="text-red-500">*</span>
                </label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleInputChange}
                  placeholder="+880 1700-000000"
                  required
                  className="input-primary"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Business Address <span className="text-red-500">*</span>
                </label>
                <textarea
                  name="address"
                  value={formData.address}
                  onChange={handleInputChange}
                  placeholder="House/Plot, Road, Area"
                  required
                  rows={3}
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  City <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="city"
                  value={formData.city}
                  onChange={handleInputChange}
                  placeholder="Dhaka"
                  required
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Postal Code
                </label>
                <input
                  type="text"
                  name="postalCode"
                  value={formData.postalCode}
                  onChange={handleInputChange}
                  placeholder="1212"
                  className="input-primary"
                />
              </div>
            </div>
          </div>

          {/* Bank Information */}
          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6 md:p-8">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-green-50 rounded-lg">
                <CreditCard className="w-6 h-6 text-green-600" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900">Bank Information</h2>
            </div>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Account Holder Name
                </label>
                <input
                  type="text"
                  name="bankAccountName"
                  value={formData.bankAccountName}
                  onChange={handleInputChange}
                  placeholder="John Doe"
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Account Number
                </label>
                <input
                  type="text"
                  name="bankAccountNumber"
                  value={formData.bankAccountNumber}
                  onChange={handleInputChange}
                  placeholder="1234567890"
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Bank Name
                </label>
                <input
                  type="text"
                  name="bankName"
                  value={formData.bankName}
                  onChange={handleInputChange}
                  placeholder="ABC Bank"
                  className="input-primary"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Branch Name
                </label>
                <input
                  type="text"
                  name="bankBranch"
                  value={formData.bankBranch}
                  onChange={handleInputChange}
                  placeholder="Gulshan Branch"
                  className="input-primary"
                />
              </div>
            </div>
          </div>

          {/* Documents Upload */}
          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-6 md:p-8">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2 bg-orange-50 rounded-lg">
                <FileText className="w-6 h-6 text-orange-600" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900">Required Documents</h2>
            </div>
            
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  NID / Passport <span className="text-red-500">*</span>
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 hover:border-blue-400 transition-colors">
                  <input
                    type="file"
                    accept="image/*,application/pdf"
                    onChange={(e) => handleFileChange(e, 'nid')}
                    required
                    className="hidden"
                    id="nid-upload"
                  />
                  <label htmlFor="nid-upload" className="cursor-pointer flex flex-col items-center">
                    <Upload className="w-10 h-10 text-gray-400 mb-2" />
                    <p className="text-sm font-medium text-gray-700">
                      {documents.nid ? documents.nid.name : 'Click to upload NID/Passport'}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">PNG, JPG or PDF (max. 5MB)</p>
                  </label>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Trade License (Optional)
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 hover:border-blue-400 transition-colors">
                  <input
                    type="file"
                    accept="image/*,application/pdf"
                    onChange={(e) => handleFileChange(e, 'tradeLicense')}
                    className="hidden"
                    id="trade-license-upload"
                  />
                  <label htmlFor="trade-license-upload" className="cursor-pointer flex flex-col items-center">
                    <Upload className="w-10 h-10 text-gray-400 mb-2" />
                    <p className="text-sm font-medium text-gray-700">
                      {documents.tradeLicense ? documents.tradeLicense.name : 'Click to upload Trade License'}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">PNG, JPG or PDF (max. 5MB)</p>
                  </label>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Bank Statement (Optional)
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 hover:border-blue-400 transition-colors">
                  <input
                    type="file"
                    accept="image/*,application/pdf"
                    onChange={(e) => handleFileChange(e, 'bankStatement')}
                    className="hidden"
                    id="bank-statement-upload"
                  />
                  <label htmlFor="bank-statement-upload" className="cursor-pointer flex flex-col items-center">
                    <Upload className="w-10 h-10 text-gray-400 mb-2" />
                    <p className="text-sm font-medium text-gray-700">
                      {documents.bankStatement ? documents.bankStatement.name : 'Click to upload Bank Statement'}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">PNG, JPG or PDF (max. 5MB)</p>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Submit */}
          <div className="flex flex-col sm:flex-row gap-4">
            <button
              type="button"
              onClick={() => navigate('/')}
              className="flex-1 py-4 px-6 border-2 border-gray-300 text-gray-700 rounded-xl font-bold hover:bg-gray-50 transition-all duration-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 btn-primary flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-2 border-white border-t-transparent"></div>
                  Processing...
                </>
              ) : (
                <>
                  <CheckCircle2 size={20} />
                  Submit Application
                </>
              )}
            </button>
          </div>
        </form>

        <div className="mt-8 bg-blue-50 border border-blue-200 rounded-xl p-6">
          <h3 className="font-bold text-blue-900 mb-3 flex items-center gap-2">
            <AlertCircle size={20} />
            Important Information
          </h3>
          <ul className="space-y-2 text-sm text-blue-800">
            <li>• All information provided must be accurate and verifiable</li>
            <li>• Documents should be clear and readable</li>
            <li>• Processing time: 24-48 hours</li>
            <li>• You'll receive email notification once approved</li>
            <li>• Commission: 5-10% per sale (based on category)</li>
          </ul>
        </div>
      </div>
    </div>
  );
};
