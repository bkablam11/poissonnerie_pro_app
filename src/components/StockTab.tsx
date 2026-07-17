import React, { useState, useMemo } from 'react';
import { DBState, Product } from '../types';
import { 
  Package, 
  Search, 
  Plus, 
  Edit, 
  Trash2, 
  AlertTriangle, 
  X, 
  Save, 
  Info,
  Calendar
} from 'lucide-react';

interface StockTabProps {
  state: DBState;
  onAddProduct: (product: Omit<Product, 'id' | 'updatedAt' | 'isSynced'>) => void;
  onUpdateProduct: (product: Product) => void;
  onDeleteProduct: (id: string) => void;
}

export function StockTab({ state, onAddProduct, onUpdateProduct, onDeleteProduct }: StockTabProps) {
  const { products, settings } = state;

  // Search & Filter state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('Tout');

  // Sidebar Form Editor
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form Fields
  const [name, setName] = useState('');
  const [category, setCategory] = useState<Product['category']>('Poissons');
  const [avgPurchasePrice, setAvgPurchasePrice] = useState(0);
  const [sellingPrice, setSellingPrice] = useState(0);
  const [quantity, setQuantity] = useState(0);
  const [alertThreshold, setAlertThreshold] = useState(5);
  const [unit, setUnit] = useState<Product['unit']>('kg');
  const [freshness, setFreshness] = useState<Product['freshness']>('Frais');

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // Open form for adding
  const handleOpenAdd = () => {
    setEditingProduct(null);
    setName('');
    setCategory('Poissons');
    setAvgPurchasePrice(0);
    setSellingPrice(0);
    setQuantity(0);
    setAlertThreshold(5);
    setUnit('kg');
    setFreshness('Frais');
    setIsFormOpen(true);
  };

  // Open form for editing
  const handleOpenEdit = (prod: Product) => {
    setEditingProduct(prod);
    setName(prod.name);
    setCategory(prod.category);
    setAvgPurchasePrice(prod.avgPurchasePrice);
    setSellingPrice(prod.sellingPrice);
    setQuantity(prod.quantity);
    setAlertThreshold(prod.alertThreshold);
    setUnit(prod.unit);
    setFreshness(prod.freshness);
    setIsFormOpen(true);
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    const payload = {
      name,
      category,
      avgPurchasePrice: Number(avgPurchasePrice),
      sellingPrice: Number(sellingPrice),
      quantity: Number(quantity),
      alertThreshold: Number(alertThreshold),
      unit,
      freshness
    };

    if (editingProduct) {
      // Update
      onUpdateProduct({
        ...editingProduct,
        ...payload
      });
    } else {
      // Add
      onAddProduct(payload);
    }
    setIsFormOpen(false);
  };

  const handleDelete = (id: string) => {
    if (window.confirm("Êtes-vous sûr de vouloir supprimer cet article de l'inventaire ?")) {
      onDeleteProduct(id);
    }
  };

  // Filtered List
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchesCat = selectedCategory === 'Tout' || p.category === selectedCategory;
      const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    });
  }, [products, selectedCategory, searchQuery]);

  // Freshness Badge Color helper
  const getFreshnessStyle = (fresh: Product['freshness']) => {
    switch (fresh) {
      case 'Frais':
        return 'bg-emerald-100 text-emerald-800 border border-emerald-200';
      case 'Moyen':
        return 'bg-amber-100 text-amber-800 border border-amber-200';
      case 'Périssable':
        return 'bg-orange-100 text-orange-800 border border-orange-200';
      case 'Sensible':
        return 'bg-pink-100 text-pink-800 border border-pink-200';
    }
  };

  return (
    <div className="space-y-6" id="stock-tab">
      
      {/* Search Header panel */}
      <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        <div className="flex flex-col sm:flex-row sm:items-center gap-3 w-full max-w-2xl">
          {/* Live Search */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 transform -translate-y-1/2" />
            <input
              type="text"
              placeholder="Rechercher par nom d'article..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#F8FAFC] border border-gray-100 pl-10 pr-4 py-2 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
            />
          </div>

          {/* Categories select dropdown */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="bg-[#F8FAFC] border border-gray-100 px-4 py-2 rounded-xl text-xs font-semibold focus:outline-hidden text-gray-600"
          >
            <option value="Tout">-- Toutes Catégories --</option>
            <option value="Poissons">Poissons</option>
            <option value="Crustacés">Crustacés</option>
            <option value="Coquillages">Coquillages</option>
            <option value="Traiteur">Traiteur</option>
          </select>
        </div>

        {/* Add Product Button */}
        <button
          onClick={handleOpenAdd}
          className="bg-[#FF6B6B] hover:bg-coral-dark text-white px-5 py-2.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-xs hover:shadow-md transition active:scale-98"
        >
          <Plus className="w-4 h-4" /> Nouvel Article
        </button>

      </div>

      {/* Main Stock Table Container */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
        
        {/* Table list - Col Span 8 or 12 depending on if Form Editor is open */}
        <div className={`${isFormOpen ? 'xl:col-span-8' : 'xl:col-span-12'} bg-white rounded-[24px] border border-gray-100 shadow-sm overflow-hidden transition-all duration-300`}>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50/75 border-b border-gray-100 text-gray-400 text-xxs font-bold uppercase tracking-wider">
                  <th className="p-4 pl-6">Désignation</th>
                  <th className="p-4">Catégorie</th>
                  <th className="p-4 text-right">P. Achat Moyen</th>
                  <th className="p-4 text-right">P. Vente Public</th>
                  <th className="p-4 text-center">Quantité</th>
                  <th className="p-4">Fraîcheur</th>
                  <th className="p-4 text-right pr-6">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 text-xs">
                {filteredProducts.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-12 text-center text-gray-400">
                      <Package className="w-10 h-10 mx-auto opacity-30 mb-2" />
                      Aucun article répertorié. Cliquez sur "Nouvel Article" pour débuter votre inventaire.
                    </td>
                  </tr>
                ) : (
                  filteredProducts.map((prod) => {
                    const isLowStock = prod.quantity <= prod.alertThreshold;
                    const isOutOfStock = prod.quantity <= 0;

                    return (
                      <tr key={prod.id} className="hover:bg-slate-50/50 transition">
                        {/* Name and alert indicators */}
                        <td className="p-4 pl-6 font-bold text-gray-800">
                          <div className="flex flex-col">
                            <span className="flex items-center gap-1.5">
                              {prod.name}
                              {!prod.isSynced && (
                                <span className="inline-block w-1.5 h-1.5 rounded-full bg-orange-400" title="Non synchronisé avec le serveur"></span>
                              )}
                            </span>
                            {isLowStock && (
                              <span className="text-[10px] text-pink-600 font-semibold flex items-center gap-1 mt-0.5">
                                <AlertTriangle className="w-3.5 h-3.5 shrink-0" /> Stock sous seuil d'alerte ({prod.alertThreshold} {prod.unit})
                              </span>
                            )}
                          </div>
                        </td>

                        {/* Category */}
                        <td className="p-4">
                          <span className="bg-slate-100 text-slate-800 text-[10px] font-bold px-2 py-0.5 rounded-full uppercase">
                            {prod.category}
                          </span>
                        </td>

                        {/* Cost Price */}
                        <td className="p-4 text-right font-mono font-medium text-gray-500">
                          {formatMoney(prod.avgPurchasePrice)}
                        </td>

                        {/* Sale Price */}
                        <td className="p-4 text-right font-mono font-semibold text-gray-900">
                          {formatMoney(prod.sellingPrice)}
                        </td>

                        {/* Available Qty */}
                        <td className="p-4 text-center">
                          <div className="flex flex-col items-center">
                            <span className={`font-mono font-bold text-sm ${
                              isOutOfStock 
                                ? 'text-gray-400' 
                                : isLowStock 
                                  ? 'text-[#EC4899]' 
                                  : 'text-[#2E3A4B]'
                            }`}>
                              {prod.quantity} {prod.unit}
                            </span>
                          </div>
                        </td>

                        {/* Freshness Rating */}
                        <td className="p-4">
                          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${getFreshnessStyle(prod.freshness)}`}>
                            {prod.freshness}
                          </span>
                        </td>

                        {/* Actions */}
                        <td className="p-4 text-right pr-6">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleOpenEdit(prod)}
                              className="p-1.5 bg-slate-100 text-slate-600 hover:bg-[#FF6B6B]/10 hover:text-[#FF6B6B] rounded-lg transition"
                              title="Modifier"
                            >
                              <Edit className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleDelete(prod.id)}
                              className="p-1.5 bg-slate-100 text-slate-400 hover:bg-pink-100 hover:text-pink-600 rounded-lg transition"
                              title="Supprimer"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>

                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* CRUD Side-panel Editor (Col Span 4) */}
        {isFormOpen && (
          <div className="xl:col-span-4 bg-white rounded-[24px] border border-gray-100 shadow-sm p-5 space-y-4 animate-slideIn">
            
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="font-bold text-gray-900 text-sm">
                {editingProduct ? 'Modifier l\'Article' : 'Ajouter un Article'}
              </h3>
              <button 
                onClick={() => setIsFormOpen(false)}
                className="p-1.5 bg-slate-50 hover:bg-slate-100 text-gray-400 hover:text-gray-600 rounded-lg"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleFormSubmit} className="space-y-4 text-xs">
              
              {/* Product Name */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Désignation du produit *</label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Filet de Bar Sauvage"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                />
              </div>

              {/* Category and unit in grid */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Catégorie</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value as any)}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                  >
                    <option value="Poissons">Poissons</option>
                    <option value="Crustacés">Crustacés</option>
                    <option value="Coquillages">Coquillages</option>
                    <option value="Traiteur">Traiteur</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Unité de mesure</label>
                  <select
                    value={unit}
                    onChange={(e) => setUnit(e.target.value as any)}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                  >
                    <option value="kg">kilogramme (kg)</option>
                    <option value="pièce">pièce</option>
                  </select>
                </div>
              </div>

              {/* Financial prices */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">P. Achat Moyen ({settings.currency})</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="Ex: 5000"
                    value={avgPurchasePrice || ''}
                    onChange={(e) => setAvgPurchasePrice(Number(e.target.value))}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                  />
                </div>

                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">P. Vente Public ({settings.currency})</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="Ex: 8500"
                    value={sellingPrice || ''}
                    onChange={(e) => setSellingPrice(Number(e.target.value))}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                  />
                </div>
              </div>

              {/* Inventory metrics */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Quantité de Départ</label>
                  <input
                    type="number"
                    step="any"
                    placeholder="Ex: 25"
                    value={quantity || ''}
                    onChange={(e) => setQuantity(Number(e.target.value))}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                  />
                </div>

                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Seuil d'Alerte</label>
                  <input
                    type="number"
                    placeholder="Ex: 5"
                    value={alertThreshold || ''}
                    onChange={(e) => setAlertThreshold(Number(e.target.value))}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                  />
                </div>
              </div>

              {/* Freshness rating / perishability sensitivity */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Périssabilité / Niveau de Fraîcheur</label>
                <select
                  value={freshness}
                  onChange={(e) => setFreshness(e.target.value as any)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                >
                  <option value="Frais">Ultra-Frais (Glace directe)</option>
                  <option value="Moyen">Conservation Standard</option>
                  <option value="Périssable">Fortement Périssable (Jour J)</option>
                  <option value="Sensible">Sensible aux chocs thermiques (Ex: Coquillages)</option>
                </select>
                <p className="text-[10px] text-gray-400 mt-1 flex items-center gap-1">
                  <Info className="w-3.5 h-3.5 shrink-0" /> Détermine la criticité de l'alerte fraîcheur sur le tableau de bord.
                </p>
              </div>

              {/* CTA Form Actions */}
              <button
                type="submit"
                className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-sm hover:shadow-md transition cursor-pointer active:scale-98"
              >
                <Save className="w-4 h-4" /> Enregistrer les modifications
              </button>

            </form>

          </div>
        )}

      </div>

    </div>
  );
}
