import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Product } from '../../types';
import { X, Loader2 } from 'lucide-react';

interface ProductModalProps {
  product: Product | null;
  onClose: (updated?: boolean) => void;
}

export const ProductModal: React.FC<ProductModalProps> = ({ product, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    price: '',
    category: '',
    image_url: '',
    description: '',
    rating: '',
    reviews: '',
    stock_quantity: 10,
  });

  useEffect(() => {
    if (product) {
      setFormData({
        name: product.name,
        price: product.price.toString(),
        category: ((product.category as any)?.name || product.category || '') as string,
        image_url: (product as any).image_url || product.images?.[0]?.image_url || '',
        description: product.description || '',
        rating: product.rating.toString(),
        reviews: product.total_reviews.toString(),
        stock_quantity: product.stock_quantity,
      });
    }
  }, [product]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const dataToSave = {
        name: formData.name,
        price: parseFloat(formData.price),
        category_id: formData.category,
        description: formData.description || null,
        rating: parseFloat(formData.rating) || 0,
        total_reviews: parseInt(formData.reviews) || 0,
        stock_quantity: formData.stock_quantity,
      };

      if (product) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update(dataToSave)
          .eq('id', product.id);

        if (error) throw error;
      } else {
        // Create new product
        const { error } = await supabase.from('products').insert(dataToSave);

        if (error) throw error;
      }

      onClose(true);
    } catch (error: any) {
      alert('Error saving product: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-60 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-8 shadow-2xl transform transition-all">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-3xl font-bold text-blue-900">
            {product ? 'Edit Product' : 'Add New Product'}
          </h2>
          <button
            onClick={() => onClose()}
            className="text-slate-400 hover:text-slate-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Product Name *
            </label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="e.g., 20ft Container"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Price *
              </label>
              <input
                type="number"
                step="0.01"
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                required
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="1299.99"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Category *
              </label>
              <select
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                required
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Select category</option>
                <option value="Laptops">Laptops</option>
                <option value="Smartphones">Smartphones</option>
                <option value="Tablets">Tablets</option>
                <option value="Audio">Audio</option>
                <option value="Cameras">Cameras</option>
                <option value="TVs">TVs</option>
                <option value="Gaming">Gaming</option>
                <option value="Wearables">Wearables</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Image URL
            </label>
            <input
              type="url"
              value={formData.image_url}
              onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="https://example.com/image.jpg"
            />
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Rating
              </label>
              <input
                type="number"
                step="0.1"
                min="0"
                max="5"
                value={formData.rating}
                onChange={(e) => setFormData({ ...formData, rating: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="4.5"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Reviews
              </label>
              <input
                type="number"
                value={formData.reviews}
                onChange={(e) => setFormData({ ...formData, reviews: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="250"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Stock Quantity
              </label>
              <input
                type="number"
                value={formData.stock_quantity}
                onChange={(e) => setFormData({ ...formData, stock_quantity: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="10"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Product description..."
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={() => onClose()}
              className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors"
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
                  Saving...
                </>
              ) : (
                product ? 'Update' : 'Create'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
