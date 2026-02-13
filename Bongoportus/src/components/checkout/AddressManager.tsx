import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { ensureProfileRecord } from '../../lib/profileUtils';
import { MapPin, Plus, Edit2, Trash2, Check, Loader2, Home, Building } from 'lucide-react';

export interface Address {
  id: string;
  user_id: string;
  label: string;
  full_name: string;
  phone: string;
  address_line1: string;
  address_line2?: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  is_default: boolean;
  created_at?: string;
}

interface AddressManagerProps {
  selectedAddress: Address | null;
  onAddressSelect: (address: Address) => void;
}

export const AddressManager: React.FC<AddressManagerProps> = ({
  selectedAddress,
  onAddressSelect,
}) => {
  const { user } = useAuth();
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingAddress, setEditingAddress] = useState<Address | null>(null);
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    label: 'Home',
    full_name: '',
    phone: '',
    address_line1: '',
    address_line2: '',
    city: '',
    state: '',
    postal_code: '',
    country: 'Bangladesh',
    is_default: false,
  });

  useEffect(() => {
    if (user) {
      fetchAddresses();
    }
  }, [user]);

  const fetchAddresses = async () => {
    try {
      const { data, error } = await supabase
        .from('user_addresses')
        .select('*')
        .eq('user_id', user?.id)
        .order('is_default', { ascending: false })
        .order('created_at', { ascending: false });

      if (error) throw error;
      setAddresses(data || []);

      // Auto-select default address if none selected
      if (!selectedAddress && data && data.length > 0) {
        const defaultAddr = data.find((a) => a.is_default) || data[0];
        onAddressSelect(defaultAddr);
      }
    } catch (error) {
      console.error('Error fetching addresses:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    setSaving(true);
    try {
      // Ensure user profile exists before creating address (fixes FK constraint)
      await ensureProfileRecord(user);

      // If setting as default, remove default from other addresses
      if (formData.is_default) {
        await supabase
          .from('user_addresses')
          .update({ is_default: false })
          .eq('user_id', user.id);
      }

      if (editingAddress) {
        // Update existing address
        const { error } = await supabase
          .from('user_addresses')
          .update({
            ...formData,
            user_id: user.id,
          })
          .eq('id', editingAddress.id);

        if (error) throw error;
      } else {
        // Create new address
        const { error } = await supabase.from('user_addresses').insert({
          ...formData,
          user_id: user.id,
        });

        if (error) throw error;
      }

      await fetchAddresses();
      resetForm();
    } catch (error: any) {
      alert('Error saving address: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (address: Address) => {
    setEditingAddress(address);
    setFormData({
      label: address.label,
      full_name: address.full_name,
      phone: address.phone,
      address_line1: address.address_line1,
      address_line2: address.address_line2 || '',
      city: address.city,
      state: address.state,
      postal_code: address.postal_code,
      country: address.country,
      is_default: address.is_default,
    });
    setShowForm(true);
  };

  const handleDelete = async (addressId: string) => {
    if (!window.confirm('Delete this address?')) return;

    try {
      const { error } = await supabase
        .from('user_addresses')
        .delete()
        .eq('id', addressId);

      if (error) throw error;

      // If deleted address was selected, clear selection
      if (selectedAddress?.id === addressId) {
        onAddressSelect(null as any);
      }

      await fetchAddresses();
    } catch (error: any) {
      alert('Error deleting address: ' + error.message);
    }
  };

  const resetForm = () => {
    setShowForm(false);
    setEditingAddress(null);
    setFormData({
      label: 'Home',
      full_name: '',
      phone: '',
      address_line1: '',
      address_line2: '',
      city: '',
      state: '',
      postal_code: '',
      country: 'Bangladesh',
      is_default: false,
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="w-6 h-6 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Address List */}
      {addresses.length > 0 && !showForm && (
        <div className="grid gap-3">
          {addresses.map((address) => (
            <div
              key={address.id}
              onClick={() => onAddressSelect(address)}
              className={`relative p-4 border-2 rounded-xl cursor-pointer transition-all ${selectedAddress?.id === address.id
                ? 'border-blue-500 bg-blue-50'
                : 'border-slate-200 hover:border-blue-300'
                }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2 mb-2">
                  {address.label === 'Home' ? (
                    <Home className="w-4 h-4 text-blue-600" />
                  ) : (
                    <Building className="w-4 h-4 text-purple-600" />
                  )}
                  <span className="font-semibold text-sm">{address.label}</span>
                  {address.is_default && (
                    <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full">
                      Default
                    </span>
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleEdit(address);
                    }}
                    className="p-1 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <Edit2 className="w-4 h-4 text-slate-500" />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDelete(address.id);
                    }}
                    className="p-1 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4 text-red-500" />
                  </button>
                </div>
              </div>
              <p className="font-medium text-slate-900">{address.full_name}</p>
              <p className="text-sm text-slate-600">{address.phone}</p>
              <p className="text-sm text-slate-600">
                {address.address_line1}
                {address.address_line2 && `, ${address.address_line2}`}
              </p>
              <p className="text-sm text-slate-600">
                {address.city}, {address.state} {address.postal_code}
              </p>
              {selectedAddress?.id === address.id && (
                <div className="absolute top-4 right-12 text-blue-600">
                  <Check className="w-5 h-5" />
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Add New Address Button */}
      {!showForm && (
        <button
          onClick={() => setShowForm(true)}
          className="w-full p-4 border-2 border-dashed border-slate-300 rounded-xl text-slate-600 hover:border-blue-400 hover:text-blue-600 transition-colors flex items-center justify-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Add New Address
        </button>
      )}

      {/* Address Form */}
      {showForm && (
        <form onSubmit={handleSubmit} className="bg-slate-50 rounded-xl p-6 space-y-4">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-lg font-semibold text-slate-900">
              {editingAddress ? 'Edit Address' : 'Add New Address'}
            </h3>
            <button
              type="button"
              onClick={resetForm}
              className="text-slate-500 hover:text-slate-700"
            >
              Cancel
            </button>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Label *
              </label>
              <select
                value={formData.label}
                onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="Home">Home</option>
                <option value="Office">Office</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Full Name *
              </label>
              <input
                type="text"
                value={formData.full_name}
                onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                required
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Phone Number *
            </label>
            <input
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              required
              placeholder="01XXXXXXXXX"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Address Line 1 *
            </label>
            <input
              type="text"
              value={formData.address_line1}
              onChange={(e) => setFormData({ ...formData, address_line1: e.target.value })}
              required
              placeholder="House/Building, Street"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Address Line 2
            </label>
            <input
              type="text"
              value={formData.address_line2}
              onChange={(e) => setFormData({ ...formData, address_line2: e.target.value })}
              placeholder="Area, Landmark (optional)"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                City *
              </label>
              <input
                type="text"
                value={formData.city}
                onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                required
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                State/Division *
              </label>
              <select
                value={formData.state}
                onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                required
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Select Division</option>
                <option value="Dhaka">Dhaka</option>
                <option value="Chittagong">Chittagong</option>
                <option value="Rajshahi">Rajshahi</option>
                <option value="Khulna">Khulna</option>
                <option value="Barisal">Barisal</option>
                <option value="Sylhet">Sylhet</option>
                <option value="Rangpur">Rangpur</option>
                <option value="Mymensingh">Mymensingh</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Postal Code *
              </label>
              <input
                type="text"
                value={formData.postal_code}
                onChange={(e) => setFormData({ ...formData, postal_code: e.target.value })}
                required
                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Country
              </label>
              <input
                type="text"
                value={formData.country}
                disabled
                className="w-full px-3 py-2 border border-slate-200 rounded-lg bg-slate-100 text-slate-600"
              />
            </div>
          </div>

          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={formData.is_default}
              onChange={(e) => setFormData({ ...formData, is_default: e.target.checked })}
              className="w-4 h-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
            />
            <span className="text-sm text-slate-700">Set as default address</span>
          </label>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={resetForm}
              className="flex-1 py-3 border border-slate-300 rounded-xl font-semibold text-slate-700 hover:bg-slate-100 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {saving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Saving...
                </>
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  Save Address
                </>
              )}
            </button>
          </div>
        </form>
      )}

      {/* Empty State */}
      {addresses.length === 0 && !showForm && (
        <div className="text-center py-8">
          <MapPin className="w-12 h-12 text-slate-300 mx-auto mb-3" />
          <p className="text-slate-600">No saved addresses</p>
          <p className="text-sm text-slate-500">Add an address to continue checkout</p>
        </div>
      )}
    </div>
  );
};
