import React, { useState, useMemo } from 'react';
import { DBState, Product, Contact, PurchaseItem } from '../types';
import { 
  PackageCheck, 
  Plus, 
  Trash2, 
  Coins, 
  Calendar, 
  User, 
  FileText, 
  CheckCircle,
  Clock,
  ArrowUpRight
} from 'lucide-react';

interface PurchasesTabProps {
  state: DBState;
  onAddPurchase: (purchase: {
    supplierId: string;
    items: { productId: string; name: string; quantity: number; price: number; unit: 'kg' | 'pièce' }[];
    total: number;
    paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
  }) => void;
  onNavigateToTab: (index: number) => void;
}

export function PurchasesTab({ state, onAddPurchase, onNavigateToTab }: PurchasesTabProps) {
  const { products, contacts, purchases, settings } = state;

  // Form states
  const [supplierId, setSupplierId] = useState('');
  const [paymentMode, setPaymentMode] = useState<'Espèces' | 'Chèque' | 'Mobile Money / Virement'>('Espèces');
  
  // Rows state: selected product, quantity, buy price
  const [rows, setRows] = useState<{ productId: string; quantity: number; price: number }[]>([
    { productId: '', quantity: 10, price: 0 }
  ]);

  const [isSuccess, setIsSuccess] = useState(false);

  // Filter suppliers only
  const suppliers = useMemo(() => {
    return contacts.filter(c => c.type === 'Fournisseur' || c.type === 'Deux');
  }, [contacts]);

  // Formats money
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // Add row
  const addRow = () => {
    setRows(prev => [...prev, { productId: '', quantity: 10, price: 0 }]);
  };

  // Remove row
  const removeRow = (index: number) => {
    setRows(prev => prev.filter((_, i) => i !== index));
  };

  // Update row details
  const updateRow = (index: number, field: 'productId' | 'quantity' | 'price', value: any) => {
    setRows(prev => {
      const updated = [...prev];
      updated[index] = {
        ...updated[index],
        [field]: value
      };
      
      // Auto populate purchase price if productId changed
      if (field === 'productId') {
        const prod = products.find(p => p.id === value);
        if (prod) {
          updated[index].price = prod.avgPurchasePrice;
        }
      }
      return updated;
    });
  };

  // Calculated total
  const purchaseTotal = useMemo(() => {
    return rows.reduce((sum, r) => sum + (r.quantity * r.price), 0);
  }, [rows]);

  // Handle submit purchase
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!supplierId) {
      alert("Veuillez sélectionner un fournisseur.");
      return;
    }

    const cleanRows = rows.filter(r => r.productId !== '' && r.quantity > 0 && r.price >= 0);
    if (cleanRows.length === 0) {
      alert("Veuillez ajouter au moins un produit valide.");
      return;
    }

    // Build items with name and unit
    const purchaseItems = cleanRows.map(r => {
      const p = products.find(prod => prod.id === r.productId)!;
      return {
        productId: r.productId,
        name: p.name,
        quantity: r.quantity,
        price: r.price,
        unit: p.unit
      };
    });

    onAddPurchase({
      supplierId,
      items: purchaseItems,
      total: purchaseTotal,
      paymentMode
    });

    // Reset Form
    setSupplierId('');
    setPaymentMode('Espèces');
    setRows([{ productId: '', quantity: 10, price: 0 }]);
    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 3000);
  };

  return (
    <div className="space-y-6" id="purchases-tab">
      
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Form panel (Col Span 7) */}
        <div className="lg:col-span-7 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-5">
          <div className="flex items-center gap-2 border-b border-gray-50 pb-3">
            <PackageCheck className="w-5 h-5 text-[#FF6B6B]" />
            <h2 className="text-base font-bold text-gray-900">Enregistrer un Arrivage / Approvisionnement</h2>
          </div>

          {isSuccess && (
            <div className="p-4 bg-emerald-50 text-emerald-800 border border-emerald-100 rounded-xl text-xs font-semibold flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-emerald-600 animate-bounce" />
              Approvisionnement enregistré avec succès. Stock et balance fournisseur mis à jour !
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5 text-xs">
            
            {/* Supplier & Payment Details */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              
              {/* Supplier Dropdown */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Fournisseur Partenaire *</label>
                <div className="flex items-center gap-1">
                  <select
                    required
                    value={supplierId}
                    onChange={(e) => setSupplierId(e.target.value)}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold focus:outline-hidden text-gray-700"
                  >
                    <option value="">-- Choisir Fournisseur --</option>
                    {suppliers.map(s => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Payment Mode */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Règlement Facture *</label>
                <select
                  value={paymentMode}
                  onChange={(e) => setPaymentMode(e.target.value as any)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold focus:outline-hidden text-gray-700"
                >
                  <option value="Espèces">Espèces (Déduction de Caisse)</option>
                  <option value="Chèque">Chèque</option>
                  <option value="Mobile Money / Virement">Virement / Mobile Money</option>
                </select>
              </div>

            </div>

            {/* Dynamic Items Rows */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <label className="font-bold text-gray-500 uppercase tracking-wider">Détail des poissons & crustacés reçus</label>
                <button
                  type="button"
                  onClick={addRow}
                  className="text-[11px] font-bold text-[#FF6B6B] hover:text-coral-dark flex items-center gap-0.5"
                >
                  <Plus className="w-4.5 h-4.5" /> Ajouter Ligne
                </button>
              </div>

              {rows.map((row, index) => (
                <div key={index} className="grid grid-cols-12 gap-2 items-center p-3 bg-[#F8FAFC]/50 rounded-xl border border-gray-100">
                  
                  {/* Select Product */}
                  <div className="col-span-6 sm:col-span-5">
                    <select
                      value={row.productId}
                      required
                      onChange={(e) => updateRow(index, 'productId', e.target.value)}
                      className="w-full bg-white border border-gray-200 p-2 rounded-lg text-xs"
                    >
                      <option value="">-- Choisir un Article --</option>
                      {products.map(p => (
                        <option key={p.id} value={p.id}>{p.name} ({p.unit})</option>
                      ))}
                    </select>
                  </div>

                  {/* Quantity input */}
                  <div className="col-span-3 sm:col-span-3">
                    <div className="relative">
                      <input
                        type="number"
                        min="0.5"
                        step="any"
                        required
                        placeholder="Qté"
                        value={row.quantity || ''}
                        onChange={(e) => updateRow(index, 'quantity', Number(e.target.value))}
                        className="w-full bg-white border border-gray-200 p-2 pr-6 rounded-lg text-xs font-semibold text-center"
                      />
                      <span className="absolute right-2 top-1/2 transform -translate-y-1/2 text-[9px] text-gray-400">
                        {row.productId ? products.find(p => p.id === row.productId)?.unit : 'u'}
                      </span>
                    </div>
                  </div>

                  {/* Unit Purchase Price */}
                  <div className="col-span-3 sm:col-span-3">
                    <input
                      type="number"
                      min="0"
                      required
                      placeholder="Prix Unit"
                      value={row.price || ''}
                      onChange={(e) => updateRow(index, 'price', Number(e.target.value))}
                      className="w-full bg-white border border-gray-200 p-2 rounded-lg text-xs font-semibold text-center font-mono"
                    />
                  </div>

                  {/* Delete row */}
                  <div className="col-span-12 sm:col-span-1 flex justify-end">
                    <button
                      type="button"
                      disabled={rows.length <= 1}
                      onClick={() => removeRow(index)}
                      className="p-1.5 text-gray-400 hover:text-pink-600 rounded-md hover:bg-pink-50 disabled:opacity-30 disabled:cursor-not-allowed"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>

                </div>
              ))}
            </div>

            {/* Calculations and CTA Submit */}
            <div className="pt-4 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-50 p-4 rounded-xl">
              <div>
                <span className="text-gray-400 text-xxs font-bold uppercase tracking-wider block">Montant Total Approvisionnement</span>
                <span className="font-mono text-lg font-black text-gray-900">{formatMoney(purchaseTotal)}</span>
              </div>

              <button
                type="submit"
                disabled={purchaseTotal <= 0}
                className="w-full sm:w-auto px-6 py-2.5 bg-[#FF6B6B] hover:bg-coral-dark text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-xs transition disabled:opacity-40"
              >
                <PackageCheck className="w-4 h-4" /> Enregistrer l'Arrivage
              </button>
            </div>

          </form>
        </div>

        {/* History arrivals panel (Col Span 5) */}
        <div className="lg:col-span-5 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-gray-50 pb-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              <Clock className="w-4.5 h-4.5 text-gray-500" /> Historique Approvisionnements
            </h3>
            <span className="text-[10px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full font-mono">
              {purchases.length} arrivages
            </span>
          </div>

          <div className="space-y-3 overflow-y-auto max-h-[500px] pr-1">
            {purchases.length === 0 ? (
              <div className="text-center p-8 text-gray-400 text-xs">
                Aucun achat enregistré.
              </div>
            ) : (
              purchases.map((p) => (
                <div key={p.id} className="p-3.5 rounded-xl border border-gray-50 bg-slate-50/50 space-y-2 text-xs">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-bold text-gray-800 block truncate max-w-[150px]">{p.supplierName}</span>
                      <span className="text-[10px] text-gray-400">{new Date(p.date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
                    </div>
                    <div className="text-right">
                      <span className="font-mono font-bold text-gray-900 block">{formatMoney(p.total)}</span>
                      <span className="text-[9px] bg-slate-100 text-slate-700 px-1.5 py-0.5 rounded font-semibold">{p.paymentMode}</span>
                    </div>
                  </div>

                  {/* Purchased items list */}
                  <div className="border-t border-gray-100/50 pt-1.5 space-y-1">
                    {p.items.map((item, idx) => (
                      <div key={idx} className="flex justify-between text-[10px] text-gray-500 font-mono">
                        <span>• {item.name}</span>
                        <span>{item.quantity}{item.unit} x {formatMoney(item.price)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
