import React, { useState, useMemo } from 'react';
import { DBState, Product, Contact, SaleItem } from '../types';
import { 
  ShoppingBag, 
  Search, 
  User, 
  Plus, 
  Minus, 
  Trash2, 
  CreditCard, 
  Coins, 
  Receipt,
  CheckCircle,
  FileText,
  AlertCircle
} from 'lucide-react';

interface PosTabProps {
  state: DBState;
  onAddSale: (sale: {
    items: SaleItem[];
    clientId: string | null;
    paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
    subtotal: number;
    vat: number;
    total: number;
  }) => void;
  onNavigateToTab: (index: number) => void;
}

// Vector SVG Fish illustrations based on category
function FishIcon({ category, className = "w-12 h-12" }: { category: string; className?: string }) {
  if (category === 'Poissons') {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 5C7.5 5 4 8 2 12C4 16 7.5 19 12 19C15.5 19 18 17 20 14.5L22 16V8L20 9.5C18 7 15.5 5 12 5ZM12 15C10.34 15 9 13.66 9 12C9 10.34 10.34 9 12 9C13.66 9 15 10.34 15 12C15 13.66 13.66 15 12 15ZM13 12C13 11.45 12.55 11 12 11C11.45 11 11 11.45 11 12C11 12.55 11.45 13 12 13C12.55 13 13 12.55 13 12Z" fill="url(#blueGrad)"/>
        <defs>
          <linearGradient id="blueGrad" x1="2" y1="5" x2="22" y2="19" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#3B82F6" />
            <stop offset="100%" stopColor="#1E40AF" />
          </linearGradient>
        </defs>
      </svg>
    );
  }
  if (category === 'Crustacés') {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2C9 2 6 4 6 7C6 8.5 7 10 8 11L7 13C5 13 3 14 2 16C1 18 2 21 5 21C7 21 8.5 19.5 9 18H15C15.5 19.5 17 21 19 21C22 21 23 18 22 16C21 14 19 13 17 13L16 11C17 10 18 8.5 18 7C18 4 15 2 12 2ZM10 7C10 5.9 10.9 5 12 5C13.1 5 14 5.9 14 7H10Z" fill="url(#coralGrad)"/>
        <defs>
          <linearGradient id="coralGrad" x1="2" y1="2" x2="22" y2="21" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#FF6B6B" />
            <stop offset="100%" stopColor="#EC4899" />
          </linearGradient>
        </defs>
      </svg>
    );
  }
  if (category === 'Coquillages') {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2C7 2 3 6 3 11C3 15 6 18 10 19.5V22H14V19.5C18 18 21 15 21 11C21 6 17 2 12 2ZM12 17C10.5 17 9.2 16.5 8 15.5L12 5L16 15.5C14.8 16.5 13.5 17 12 17Z" fill="url(#pinkGrad)"/>
        <defs>
          <linearGradient id="pinkGrad" x1="3" y1="2" x2="21" y2="22" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#EC4899" />
            <stop offset="100%" stopColor="#8B5CF6" />
          </linearGradient>
        </defs>
      </svg>
    );
  }
  // Traiteur
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M2 12C2 17 6 21 11 21C16 21 20 17 20 12H22V10H2V12ZM12 5C8 5 5.5 8 5.5 8H18.5C18.5 8 16 5 12 5Z" fill="url(#greenGrad)"/>
      <defs>
        <linearGradient id="greenGrad" x1="2" y1="5" x2="22" y2="21" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#22C55E" />
          <stop offset="100%" stopColor="#0F766E" />
        </linearGradient>
      </defs>
    </svg>
  );
}

export function PosTab({ state, onAddSale, onNavigateToTab }: PosTabProps) {
  const { products, contacts, settings } = state;

  // Active Category Filter
  const [selectedCategory, setSelectedCategory] = useState<string>('Tout');
  
  // Search state
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Cart state
  const [cartItems, setCartItems] = useState<{ product: Product; quantity: number }[]>([]);
  
  // Selected Client ID
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  
  // Checkout Modal
  const [showCheckout, setShowCheckout] = useState<boolean>(false);
  const [paymentMode, setPaymentMode] = useState<'Espèces' | 'Chèque' | 'Mobile Money / Virement'>('Espèces');
  const [changeReturned, setChangeReturned] = useState<number>(0);
  const [amountPaidByClient, setAmountPaidByClient] = useState<string>('');
  
  // Success receipt modal
  const [receiptSale, setReceiptSale] = useState<any | null>(null);

  // Currency Formatter
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // 1. Filtering products
  const filteredProducts = useMemo(() => {
    return products.filter((prod) => {
      const matchCategory = selectedCategory === 'Tout' || prod.category === selectedCategory;
      const matchSearch = prod.name.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    });
  }, [products, selectedCategory, searchQuery]);

  // Clients list
  const clients = useMemo(() => {
    return contacts.filter(c => c.type === 'Client' || c.type === 'Deux');
  }, [contacts]);

  // 2. Cart Operations
  const addToCart = (product: Product) => {
    if (product.quantity <= 0) return; // No stock

    setCartItems(prev => {
      const existing = prev.find(item => item.product.id === product.id);
      if (existing) {
        // Check if adding exceeds available quantity
        if (existing.quantity >= product.quantity) {
          alert(`Stock insuffisant ! Stock disponible : ${product.quantity} ${product.unit}`);
          return prev;
        }
        return prev.map(item => item.product.id === product.id ? { ...item, quantity: item.quantity + 0.5 } : item);
      }
      return [...prev, { product, quantity: product.unit === 'kg' ? 1 : 1 }];
    });
  };

  const updateQuantityInCart = (productId: string, delta: number) => {
    setCartItems(prev => {
      return prev.map(item => {
        if (item.product.id === productId) {
          const newQty = item.quantity + delta;
          if (newQty <= 0) return null; // Remove
          if (newQty > item.product.quantity) {
            alert(`Stock maximum de ${item.product.quantity} ${item.product.unit} atteint.`);
            return item;
          }
          return { ...item, quantity: parseFloat(newQty.toFixed(2)) };
        }
        return item;
      }).filter(Boolean) as any;
    });
  };

  const removeFromCart = (productId: string) => {
    setCartItems(prev => prev.filter(item => item.product.id !== productId));
  };

  const clearCart = () => {
    setCartItems([]);
    setSelectedClientId('');
  };

  // 3. Totals Calculations
  const cartSubtotal = useMemo(() => {
    return cartItems.reduce((sum, item) => sum + (item.product.sellingPrice * item.quantity), 0);
  }, [cartItems]);

  const cartVat = useMemo(() => {
    const rate = settings.vatRate || 18;
    return Math.round(cartSubtotal * (rate / 100));
  }, [cartSubtotal, settings.vatRate]);

  const cartTotal = cartSubtotal + cartVat;

  // Handle Amount Paid to calculate change
  const handleAmountPaidChange = (val: string) => {
    setAmountPaidByClient(val);
    const paid = parseFloat(val);
    if (!isNaN(paid) && paid >= cartTotal) {
      setChangeReturned(paid - cartTotal);
    } else {
      setChangeReturned(0);
    }
  };

  // 4. Validate and Execute Sale
  const handleCheckoutSubmit = () => {
    if (cartItems.length === 0) return;

    // Build items payload
    const saleItems: SaleItem[] = cartItems.map(item => ({
      productId: item.product.id,
      name: item.product.name,
      quantity: item.quantity,
      price: item.product.sellingPrice,
      unit: item.product.unit
    }));

    const client = clients.find(c => c.id === selectedClientId) || null;

    const salePayload = {
      items: saleItems,
      clientId: selectedClientId ? selectedClientId : null,
      clientName: client ? client.name : "Client Comptant",
      paymentMode: paymentMode,
      subtotal: cartSubtotal,
      vat: cartVat,
      total: cartTotal,
      date: new Date().toISOString()
    };

    // Execute Mutation
    onAddSale(salePayload);

    // Save for receipt screen
    setReceiptSale(salePayload);

    // Clear cart and close modal
    setCartItems([]);
    setSelectedClientId('');
    setAmountPaidByClient('');
    setChangeReturned(0);
    setShowCheckout(false);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 h-full items-stretch" id="pos-tab">
      
      {/* Catalog & Search Section (Col Span 8) */}
      <div className="lg:col-span-8 space-y-6 flex flex-col justify-between">
        
        {/* Search bar and Category selector */}
        <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <ShoppingBag className="w-5 h-5 text-[#FF6B6B]" />
              Catalogue de Vente
            </h2>
            
            {/* Live Search Input */}
            <div className="relative max-w-sm w-full">
              <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                placeholder="Rechercher un poisson, coquillage..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-gray-100 pl-10 pr-4 py-2 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/30"
              />
            </div>
          </div>

          {/* Categories Quick Filter */}
          <div className="flex flex-wrap items-center gap-2 pt-1 border-t border-gray-50">
            {['Tout', 'Poissons', 'Crustacés', 'Coquillages', 'Traiteur'].map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-4 py-1.5 rounded-full text-xs font-semibold transition duration-150 ${
                  selectedCategory === cat
                    ? 'bg-[#FF6B6B] text-white shadow-xs'
                    : 'bg-[#F1F5F9] text-gray-600 hover:bg-gray-200'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Products Grid */}
        <div className="overflow-y-auto pr-1 flex-1 min-h-[450px]">
          {filteredProducts.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-gray-100 flex flex-col items-center justify-center h-full">
              <Search className="w-12 h-12 text-gray-300 mb-4" />
              <h3 className="font-bold text-gray-700">Aucun produit ne correspond</h3>
              <p className="text-gray-400 text-sm mt-1 max-w-sm">
                Ajustez votre catégorie ou essayez une autre recherche. Si le produit est épuisé, vous devez l'approvisionner dans l'onglet Approvisionnements.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredProducts.map((prod) => {
                const isOutOfStock = prod.quantity <= 0;
                const isLowStock = prod.quantity <= prod.alertThreshold;

                return (
                  <div
                    key={prod.id}
                    onClick={() => !isOutOfStock && addToCart(prod)}
                    className={`bg-white rounded-[24px] p-4 border transition duration-150 relative select-none ${
                      isOutOfStock
                        ? 'opacity-60 border-gray-200 cursor-not-allowed bg-gray-50'
                        : 'border-gray-100 hover:border-[#FF6B6B] hover:shadow-md cursor-pointer group active:scale-98'
                    }`}
                  >
                    {/* SVG Vector Drawing Icon */}
                    <div className="flex justify-between items-start mb-3">
                      <div className="p-2.5 rounded-xl bg-slate-50 group-hover:bg-coral/10 group-hover:text-white transition duration-150">
                        <FishIcon category={prod.category} className="w-10 h-10" />
                      </div>
                      
                      {/* Quantity Tag */}
                      <div className="text-right">
                        <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full ${
                          isOutOfStock 
                            ? 'bg-gray-200 text-gray-500' 
                            : isLowStock 
                              ? 'bg-pink-100 text-pink-700 animate-pulse' 
                              : 'bg-emerald-100 text-emerald-700'
                        }`}>
                          {isOutOfStock ? "Épuisé" : `${prod.quantity} ${prod.unit}`}
                        </span>
                        <span className="text-[9px] text-gray-400 block mt-0.5">En Stock</span>
                      </div>
                    </div>

                    {/* Metadata */}
                    <div className="space-y-1">
                      <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">
                        {prod.category}
                      </span>
                      <h4 className="font-bold text-gray-800 text-sm tracking-tight group-hover:text-[#FF6B6B] transition line-clamp-1">
                        {prod.name}
                      </h4>
                    </div>

                    {/* Footer price */}
                    <div className="flex items-center justify-between pt-3 mt-3 border-t border-gray-50">
                      <span className="text-xs text-gray-400">Prix de vente</span>
                      <span className="font-mono font-bold text-base text-gray-900">
                        {formatMoney(prod.sellingPrice)}
                        <span className="text-[10px] text-gray-400 font-normal font-sans ml-0.5">/{prod.unit}</span>
                      </span>
                    </div>

                    {/* Rapid addition absolute icon */}
                    {!isOutOfStock && (
                      <div className="absolute bottom-16 right-4 p-1.5 bg-[#FF6B6B]/10 group-hover:bg-[#FF6B6B] text-[#FF6B6B] group-hover:text-white rounded-full opacity-0 group-hover:opacity-100 transform translate-y-2 group-hover:translate-y-0 transition duration-200 shadow-sm">
                        <Plus className="w-4 h-4" />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Cart & Billing Section (Col Span 4) */}
      <div className="lg:col-span-4 bg-white rounded-[24px] border border-gray-100 shadow-sm flex flex-col justify-between overflow-hidden">
        
        {/* Header */}
        <div className="p-4 bg-slate-50 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShoppingBag className="w-5 h-5 text-gray-600" />
            <h3 className="font-bold text-gray-800 text-sm">Panier En Cours</h3>
          </div>
          <span className="bg-slate-200 text-slate-800 text-[10px] font-bold px-2.5 py-0.5 rounded-full font-mono">
            {cartItems.length} articles
          </span>
        </div>

        {/* Client Selector */}
        <div className="p-4 border-b border-gray-100 bg-[#FBFBFD] space-y-2">
          <label className="text-[11px] font-bold text-gray-500 uppercase tracking-wider flex items-center gap-1">
            <User className="w-3.5 h-3.5" /> Client Appairé (VIP/Comptant)
          </label>
          <select
            value={selectedClientId}
            onChange={(e) => setSelectedClientId(e.target.value)}
            className="w-full bg-white border border-gray-200 p-2 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
          >
            <option value="">-- Client Comptant --</option>
            {clients.map(c => (
              <option key={c.id} value={c.id}>
                {c.name} {c.balance > 0 ? `(Créance: ${formatMoney(c.balance)})` : ''}
              </option>
            ))}
          </select>
        </div>

        {/* Cart items list scrollable */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3 min-h-[250px]">
          {cartItems.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center text-gray-400">
              <ShoppingBag className="w-8 h-8 opacity-30 mb-2 text-gray-400" />
              <p className="text-xs">Votre panier est vide.</p>
              <p className="text-[10px] text-gray-300 mt-1">Sélectionnez des articles à gauche.</p>
            </div>
          ) : (
            cartItems.map((item) => (
              <div 
                key={item.product.id} 
                className="flex items-center justify-between p-3 rounded-xl border border-gray-50 bg-slate-50/50 hover:bg-slate-50 transition duration-150"
              >
                <div className="flex-1 space-y-1 pr-2">
                  <h5 className="font-bold text-gray-800 text-xs truncate max-w-[150px]">{item.product.name}</h5>
                  <span className="text-[10px] font-semibold text-gray-500 font-mono">
                    {formatMoney(item.product.sellingPrice)}
                  </span>
                </div>
                
                {/* Quantity adjustments */}
                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => updateQuantityInCart(item.product.id, -0.5)}
                    className="p-1 rounded-md hover:bg-slate-200 text-gray-600 bg-white border border-gray-100"
                  >
                    <Minus className="w-3 h-3" />
                  </button>
                  <span className="font-mono text-xs font-bold w-12 text-center">
                    {item.quantity} <span className="text-[9px] text-gray-400 font-normal">{item.product.unit}</span>
                  </span>
                  <button
                    onClick={() => updateQuantityInCart(item.product.id, 0.5)}
                    className="p-1 rounded-md hover:bg-slate-200 text-gray-600 bg-white border border-gray-100"
                  >
                    <Plus className="w-3 h-3" />
                  </button>
                  
                  <button
                    onClick={() => removeFromCart(item.product.id)}
                    className="p-1.5 ml-1 text-gray-400 hover:text-pink-600 rounded-md hover:bg-pink-50"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Calculation Invoice Area */}
        <div className="p-4 bg-slate-50 border-t border-gray-100 space-y-3">
          <div className="space-y-1.5 text-xs text-gray-600">
            <div className="flex justify-between">
              <span>Total HT :</span>
              <span className="font-mono font-medium">{formatMoney(cartSubtotal)}</span>
            </div>
            <div className="flex justify-between">
              <span>TVA ({settings.vatRate || 18}%) :</span>
              <span className="font-mono font-medium">{formatMoney(cartVat)}</span>
            </div>
            <div className="flex justify-between border-t border-gray-200/60 pt-2 text-sm font-bold text-gray-900">
              <span>Net à payer (TTC) :</span>
              <span className="font-mono text-[#FF6B6B]">{formatMoney(cartTotal)}</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-1">
            <button
              onClick={clearCart}
              disabled={cartItems.length === 0}
              className="py-2.5 rounded-xl border border-gray-200 text-xs font-semibold hover:bg-gray-100 transition disabled:opacity-40 disabled:cursor-not-allowed"
            >
              Vider
            </button>
            <button
              onClick={() => setShowCheckout(true)}
              disabled={cartItems.length === 0}
              className="py-2.5 rounded-xl bg-[#FF6B6B] text-white text-xs font-semibold hover:bg-coral-dark shadow-xs flex items-center justify-center gap-1 hover:shadow-md transition active:scale-98 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <CreditCard className="w-4 h-4" /> Encaisser
            </button>
          </div>
        </div>

      </div>

      {/* ================= CHECKOUT PAY MODAL ================= */}
      {showCheckout && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 animate-fadeIn">
          <div className="bg-white rounded-2xl max-w-md w-full border border-gray-100 shadow-xl overflow-hidden flex flex-col justify-between">
            
            {/* Header */}
            <div className="p-5 bg-slate-50 border-b border-gray-100 flex items-center gap-3">
              <div className="p-2 bg-coral/10 text-[#FF6B6B] rounded-xl">
                <Coins className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 text-base">Règlement & Encaissement</h3>
                <p className="text-gray-400 text-xs mt-0.5">Choisissez le mode de paiement et saisissez la somme reçue.</p>
              </div>
            </div>

            {/* Form */}
            <div className="p-5 space-y-4 flex-1">
              {/* Payment selection */}
              <div className="space-y-2">
                <label className="text-[11px] font-bold text-gray-500 uppercase tracking-wider">Mode de Règlement</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['Espèces', 'Chèque', 'Mobile Money / Virement'] as const).map((mode) => (
                    <button
                      key={mode}
                      onClick={() => setPaymentMode(mode)}
                      className={`p-2.5 rounded-xl border text-center text-xs font-semibold transition ${
                        paymentMode === mode
                          ? 'border-[#FF6B6B] bg-orange-50 text-[#FF6B6B]'
                          : 'border-gray-200 hover:bg-slate-50 text-gray-600'
                      }`}
                    >
                      {mode === 'Espèces' ? 'Espèces' : mode === 'Chèque' ? 'Chèque' : 'Virement/MoMo'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Amount Net */}
              <div className="bg-slate-50 p-4 rounded-xl border border-gray-100 flex justify-between items-center">
                <span className="text-xs font-bold text-gray-600">Net à Payer (TTC) :</span>
                <span className="font-mono font-black text-xl text-[#FF6B6B]">
                  {formatMoney(cartTotal)}
                </span>
              </div>

              {/* Espèces Cash Calculations */}
              {paymentMode === 'Espèces' && (
                <div className="space-y-3 p-3 bg-orange-50/20 border border-orange-100/50 rounded-xl">
                  <div className="space-y-1">
                    <label className="text-[11px] font-bold text-gray-500 uppercase tracking-wider">Espèces Reçues ({settings.currency || 'FCFA'})</label>
                    <input
                      type="number"
                      placeholder="Ex: 50000"
                      value={amountPaidByClient}
                      onChange={(e) => handleAmountPaidChange(e.target.value)}
                      className="w-full bg-white border border-gray-200 p-2.5 rounded-xl font-mono text-base font-bold text-gray-900 focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
                    />
                  </div>
                  {parseFloat(amountPaidByClient) >= cartTotal && (
                    <div className="flex justify-between items-center text-sm pt-2 border-t border-orange-100/50">
                      <span className="font-medium text-gray-600 flex items-center gap-1">
                        <CheckCircle className="w-4 h-4 text-emerald-600" /> Monnaie à rendre :
                      </span>
                      <span className="font-mono font-black text-emerald-600 text-lg">
                        {formatMoney(changeReturned)}
                      </span>
                    </div>
                  )}
                </div>
              )}

              {/* VIP / Corporate alert */}
              {selectedClientId && (paymentMode === 'Chèque' || paymentMode === 'Mobile Money / Virement') && (
                <div className="p-3 bg-blue-50 border border-blue-100 text-blue-700 rounded-xl text-xs flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 text-blue-500 shrink-0 mt-0.5" />
                  <p>
                    <strong>Avis de crédit client VIP :</strong> Ce règlement par {paymentMode} sera comptabilisé et rattaché au compte de <em>{clients.find(c => c.id === selectedClientId)?.name}</em>.
                  </p>
                </div>
              )}
            </div>

            {/* Footer buttons */}
            <div className="p-5 border-t border-gray-100 flex items-center justify-end gap-3 bg-slate-50">
              <button
                onClick={() => setShowCheckout(false)}
                className="px-4 py-2 text-xs font-semibold border border-gray-200 rounded-xl hover:bg-gray-100 text-gray-600"
              >
                Annuler
              </button>
              <button
                onClick={handleCheckoutSubmit}
                disabled={paymentMode === 'Espèces' && (isNaN(parseFloat(amountPaidByClient)) || parseFloat(amountPaidByClient) < cartTotal)}
                className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1 transition disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <CheckCircle className="w-4 h-4" /> Enregistrer la vente
              </button>
            </div>

          </div>
        </div>
      )}

      {/* ================= SUCCESS ENCAISSEMENT RECEIPT WINDOW ================= */}
      {receiptSale && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 animate-fadeIn">
          <div className="bg-white rounded-2xl max-w-sm w-full border border-gray-100 shadow-xl overflow-hidden p-6 text-center space-y-4 printable-receipt">
            <div className="w-14 h-14 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto no-print">
              <CheckCircle className="w-8 h-8" />
            </div>
            
            <div className="space-y-1 no-print">
              <h3 className="text-lg font-bold text-gray-900">Vente Enregistrée !</h3>
              <p className="text-xs text-gray-400">Le stock a été déduit et l'écriture comptable a été enregistrée.</p>
            </div>

            {/* Simple mini ticket block */}
            <div className="bg-slate-50 border border-dashed border-gray-200 p-4 rounded-xl text-left font-mono text-xs text-gray-600 space-y-2.5">
              <div className="text-center font-bold border-b border-gray-200 pb-1.5 text-gray-800">
                {settings.shopName}
              </div>
              <div className="text-[10px] space-y-0.5">
                <p>Client: {receiptSale.clientName}</p>
                <p>Date: {new Date(receiptSale.date).toLocaleString('fr-FR')}</p>
                <p>Règlement: {receiptSale.paymentMode}</p>
              </div>
              
              <div className="border-t border-b border-gray-200 py-1.5 space-y-1">
                {receiptSale.items.map((it: any, index: number) => (
                  <div key={index} className="flex justify-between text-[11px]">
                    <span className="truncate max-w-[150px]">{it.name}</span>
                    <span>{it.quantity}{it.unit} x {formatMoney(it.price)}</span>
                  </div>
                ))}
              </div>

              <div className="space-y-0.5 text-right font-bold text-gray-800">
                <div className="text-[10px] font-normal text-gray-500 flex justify-between">
                  <span>Total HT:</span>
                  <span>{formatMoney(receiptSale.subtotal)}</span>
                </div>
                <div className="text-[10px] font-normal text-gray-500 flex justify-between">
                  <span>TVA ({settings.vatRate}%):</span>
                  <span>{formatMoney(receiptSale.vat)}</span>
                </div>
                <div className="text-sm text-coral flex justify-between pt-1 border-t border-dashed border-gray-200 mt-1">
                  <span>Net à payer:</span>
                  <span>{formatMoney(receiptSale.total)}</span>
                </div>
              </div>
            </div>

            {/* Iframe detection print warning */}
            {typeof window !== 'undefined' && window.self !== window.top && (
              <div className="text-[11px] text-amber-700 bg-amber-50 border border-amber-200 p-3 rounded-xl text-left flex items-start gap-2 no-print">
                <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-amber-500" />
                <span>
                  <strong>Avis d'impression :</strong> Le mode de prévisualisation intégré de l'éditeur restreint l'accès à l'impression. Veuillez ouvrir l'application dans un <strong>nouvel onglet</strong> pour imprimer vos tickets.
                </span>
              </div>
            )}

            <div className="grid grid-cols-2 gap-2 no-print">
              <button
                onClick={() => {
                  try {
                    window.print();
                  } catch (err) {
                    console.error("Print failed/blocked:", err);
                    alert("L'impression est bloquée par l'aperçu sécurisé. Ouvrez l'application dans un nouvel onglet pour tester.");
                  }
                }}
                className="py-2 px-4 text-xs font-semibold border border-gray-200 rounded-xl hover:bg-slate-50 flex items-center justify-center gap-1 text-gray-600 cursor-pointer"
              >
                <FileText className="w-3.5 h-3.5" /> Imprimer Ticket
              </button>
              <button
                onClick={() => setReceiptSale(null)}
                className="py-2 px-4 bg-[#FF6B6B] hover:bg-coral-dark text-white text-xs font-semibold rounded-xl cursor-pointer"
              >
                Nouvelle Vente
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
