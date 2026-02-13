import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { Product } from '../../types';
import { MOCK_PRODUCTS } from '../../data/mockProducts';
import { Plus, Edit2, Trash2, Package, Loader2, ShoppingCart, Star } from 'lucide-react';
import { ProductModal } from './ProductModal';
import { ProductDetailsModal } from './ProductDetailsModal';
import { ensureProfileRecord } from '../../lib/profileUtils';

export const ProductGrid: React.FC = () => {
  const { profile, user } = useAuth();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [productModalTab, setProductModalTab] = useState<'details' | 'chat'>('details');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const isAdmin = profile?.role === 'admin';

  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('products')
        .select('*, category:categories(*), brand:brands(*)')
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      if (data && data.length > 0) {
        setProducts(data);
      } else {
        console.log('Using mock products');
        setProducts(MOCK_PRODUCTS);
      }
    } catch (err) {
      console.error('Failed to load products, using mock data:', err);
      setProducts(MOCK_PRODUCTS);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleModalClose = (shouldRefresh?: boolean) => {
    setShowModal(false);
    setEditingProduct(null);
    if (shouldRefresh) {
      fetchProducts();
    }
  };

  const handleProductClick = (product: Product, tab: 'details' | 'chat' = 'details') => {
    if (!isAdmin) {
      setSelectedProduct(product);
      setProductModalTab(tab);
    }
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setShowModal(true);
  };

  const handleDelete = async (productId: string) => {
    if (!window.confirm('Delete this product?')) return;
    try {
      const { error } = await supabase.from('products').delete().eq('id', productId);
      if (error) throw error;
      fetchProducts();
    } catch (err) {
      console.error('Failed to delete product:', err);
      alert('Could not delete the product. Please try again.');
    }
  };

  const categories = useMemo(
    () => ['All', ...Array.from(new Set(products.map((product) => (product.category as any)?.name || product.category || 'Other')))],
    [products],
  );

  const filteredProducts = useMemo(
    () =>
      products.filter((product) => {
        const categoryName = (product.category as any)?.name || product.category || '';
        const haystack = `${product.name} ${categoryName} ${product.description ?? ''}`.toLowerCase();
        const matchesSearch = haystack.includes(searchQuery.toLowerCase());
        const matchesCategory = selectedCategory === 'All' || categoryName === selectedCategory;
        return matchesSearch && matchesCategory;
      }),
    [products, searchQuery, selectedCategory],
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-blue-900" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-50 py-8">
      <div className="max-w-7xl mx-auto px-4 space-y-8">
        <div className="bg-gradient-to-r from-blue-900 via-purple-900 to-pink-900 rounded-3xl p-8 text-white shadow-2xl relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none" />
          <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
            <div>
              <p className="text-sm uppercase tracking-[0.4em] text-blue-200 mb-2">Marketplace</p>
              <h1 className="text-4xl font-black tracking-tight">
                {isAdmin ? 'Product Mission Control' : 'Choose Your Next Upgrade'}
              </h1>
              <p className="text-blue-100 max-w-2xl mt-2">
                {isAdmin
                  ? 'Create cinematic product launches with instant editing, live inventory, and curated storytelling cards.'
                  : 'Tap into authenticated global sellers, instant quotes, and concierge delivery choreography.'}
              </p>
            </div>
            {isAdmin && (
              <button
                onClick={() => setShowModal(true)}
                className="bg-yellow-400 text-blue-900 px-6 py-3 rounded-2xl font-bold shadow-lg hover:shadow-2xl transition-all hover:-translate-y-0.5"
              >
                <Plus className="w-5 h-5 mr-2" />
                Launch New Product
              </button>
            )}
          </div>
        </div>

        <div className="bg-white rounded-3xl shadow-xl border border-slate-200 p-6 space-y-4">
          <div className="flex flex-col lg:flex-row gap-4">
            <div className="flex-1 relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by device, category, or experience..."
                className="w-full px-5 py-4 rounded-2xl border-2 border-slate-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 text-slate-900 font-medium"
              />
              <span className="absolute right-5 top-1/2 -translate-y-1/2 text-slate-400 text-sm">{filteredProducts.length} results</span>
            </div>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {categories.map((category) => (
                <button
                  key={category}
                  onClick={() => setSelectedCategory(category)}
                  className={`px-4 py-2 rounded-2xl text-sm font-semibold whitespace-nowrap transition-all ${
                    selectedCategory === category
                      ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg shadow-blue-500/30'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {category}
                </button>
              ))}
            </div>
          </div>
        </div>

        {filteredProducts.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-3xl border-2 border-dashed border-slate-300 shadow-xl">
            <Package className="w-16 h-16 text-slate-300 mx-auto mb-4" />
            <p className="text-slate-600 text-lg">No products match your filters.</p>
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredProducts.map((product, index) => (
              <div
                key={product.id}
                onClick={() => !isAdmin && handleProductClick(product)}
                className={`group bg-white rounded-3xl border border-slate-200 shadow-lg hover:shadow-2xl transition-all duration-500 hover:-translate-y-2 overflow-hidden ${
                  !isAdmin ? 'cursor-pointer' : ''
                }`}
                style={{ animation: index < 8 ? `fadeInUp 0.4s ease-out ${index * 0.05}s both` : 'none' }}
              >
                <div className="relative p-6 h-60 flex items-center justify-center bg-gradient-to-br from-slate-50 to-white">
                  <div className="absolute top-4 left-4 px-3 py-1 rounded-full text-xs font-semibold bg-white shadow border border-slate-100 text-slate-600">
                    {(product.category as any)?.name || product.category || 'Other'}
                  </div>
                  {isAdmin && (
                    <div className="absolute top-4 right-4 flex gap-2">
                      <button
                        onClick={() => handleEdit(product)}
                        className="p-2 rounded-full bg-white/90 border border-slate-200 text-blue-600 hover:bg-blue-50"
                        title="Edit product"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(product.id)}
                        className="p-2 rounded-full bg-white/90 border border-slate-200 text-red-500 hover:bg-red-50"
                        title="Delete product"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                  {(product as any).image_url ? (
                    <img
                      src={(product as any).image_url}
                      alt={product.name}
                      loading="lazy"
                      decoding="async"
                      className="max-h-full max-w-full object-contain transition-transform duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="w-28 h-28 rounded-2xl bg-gradient-to-br from-blue-100 to-purple-100 flex items-center justify-center">
                      <Package className="w-12 h-12 text-blue-400" />
                    </div>
                  )}
                </div>
                <div className="p-6 space-y-4 border-t border-slate-100">
                  <div>
                    <h3 className="text-xl font-bold text-slate-900 line-clamp-2">
                      {product.name}
                    </h3>
                    <p className="text-3xl font-black text-slate-900 mt-2">
                      ${product.price.toLocaleString()}
                      <span className="text-sm text-slate-500 font-semibold ml-1">USD</span>
                    </p>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-slate-500">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${
                          i < Math.round(product.rating)
                            ? 'text-yellow-400 fill-yellow-400'
                            : 'text-slate-200'
                        }`}
                      />
                    ))}
                    <span>{product.rating.toFixed(1)} · {product.total_reviews.toLocaleString()} reviews</span>
                  </div>
                  {product.description && (
                    <p className="text-sm text-slate-600 line-clamp-3">
                      {product.description}
                    </p>
                  )}
                  <div className="flex gap-3 pt-2">
                    {isAdmin ? (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleEdit(product);
                        }}
                        className="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 text-white py-3 rounded-2xl font-semibold hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg hover:shadow-xl"
                      >
                        Manage Listing
                      </button>
                    ) : (
                      <>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleProductClick(product, 'details');
                          }}
                          className="flex-1 bg-blue-900 text-white py-3 rounded-2xl font-semibold flex items-center justify-center gap-2 hover:bg-blue-800 transition-all shadow-lg hover:shadow-xl"
                        >
                          <ShoppingCart className="w-4 h-4" />
                          View Details
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleProductClick(product, 'chat');
                          }}
                          className="px-4 py-3 rounded-2xl bg-slate-100 text-slate-600 hover:bg-slate-200 transition-all font-semibold"
                        >
                          Chat
                        </button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {showModal && (
          <ProductModal
            product={editingProduct}
            onClose={handleModalClose}
          />
        )}

        {selectedProduct && (
          <ProductDetailsModal
            product={selectedProduct}
            initialTab={productModalTab}
            onClose={() => setSelectedProduct(null)}
          />
        )}
      </div>
    </div>
  );
};
