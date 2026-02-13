import React, { useState } from 'react';
import { X, Loader2 } from 'lucide-react';

interface SurveyModalProps {
  onSubmit: (data: { amount: string; address: string; days: number }) => void;
  onClose: () => void;
  loading: boolean;
}

export const SurveyModal: React.FC<SurveyModalProps> = ({ onSubmit, onClose, loading }) => {
  const [formData, setFormData] = useState({
    amount: '',
    address: '',
    days: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      amount: formData.amount,
      address: formData.address,
      days: parseInt(formData.days),
    });
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-60 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-8 shadow-2xl transform transition-all">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-3xl font-bold text-blue-900">Start Chat</h2>
            <p className="text-slate-600 text-sm mt-2">
              Please answer a few questions to help us serve you better
            </p>
          </div>
          <button
            onClick={onClose}
            disabled={loading}
            className="text-slate-400 hover:text-slate-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              How much amount/quantity? *
            </label>
            <input
              type="text"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              required
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="e.g., 50 tons, 100 items"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Address & Contact Number *
            </label>
            <textarea
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              required
              rows={3}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Full address and phone number"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              How many days for delivery? *
            </label>
            <input
              type="number"
              value={formData.days}
              onChange={(e) => setFormData({ ...formData, days: e.target.value })}
              required
              min="1"
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="e.g., 7"
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-blue-900 text-white px-4 py-2 rounded-lg hover:bg-blue-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <Loader2 className="animate-spin w-4 h-4" />
                  Starting...
                </>
              ) : (
                'Start Chat'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
