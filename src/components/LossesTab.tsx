import React, { useState, useMemo } from 'react';
import { DBState, Product, Loss } from '../types';
import { 
  AlertTriangle, 
  Trash2, 
  Calendar, 
  Clock, 
  ArrowUpRight, 
  CheckCircle,
  TrendingDown,
  Info
} from 'lucide-react';

interface LossesTabProps {
  state: DBState;
  onAddLoss: (loss: {
    productId: string;
    quantity: number;
    reason: 'Périmé' | 'Altéré' | 'Invendu' | 'Erreur de découpe' | 'Autre';
    notes: string;
  }) => void;
  onNavigateToTab: (index: number) => void;
}

export function LossesTab({ state, onAddLoss, onNavigateToTab }: LossesTabProps) {
  const { products, losses, settings } = state;

  // Form states
  const [productId, setProductId] = useState('');
  const [quantity, setQuantity] = useState(1);
  const [reason, setReason] = useState<Loss['reason']>('Périmé');
  const [notes, setNotes] = useState('');

  const [isSuccess, setIsSuccess] = useState(false);

  // Filter out products with > 0 stock just so they can log losses (even if 0, they could declare)
  const availableProducts = useMemo(() => {
    return products;
  }, [products]);

  // Selected product unit
  const selectedProduct = useMemo(() => {
    return products.find(p => p.id === productId);
  }, [productId, products]);

  // Estimated lost money
  const estimatedCost = useMemo(() => {
    if (!selectedProduct) return 0;
    return Math.round(quantity * selectedProduct.avgPurchasePrice);
  }, [selectedProduct, quantity]);

  // Format money
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!productId) {
      alert("Veuillez choisir un poisson ou crustacé.");
      return;
    }
    if (quantity <= 0) {
      alert("La quantité doit être supérieure à 0.");
      return;
    }

    // Safety check on inventory
    if (selectedProduct && quantity > selectedProduct.quantity) {
      const confirmForce = window.confirm(
        `La quantité de perte (${quantity} ${selectedProduct.unit}) dépasse la quantité disponible en stock (${selectedProduct.quantity} ${selectedProduct.unit}). Voulez-vous tout de même forcer cette déclaration (le stock deviendra nul) ?`
      );
      if (!confirmForce) return;
    }

    onAddLoss({
      productId,
      quantity,
      reason,
      notes
    });

    // Reset Form
    setProductId('');
    setQuantity(1);
    setReason('Périmé');
    setNotes('');
    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 3000);
  };

  // Aggregated losses statistics
  const lossesStats = useMemo(() => {
    let perm = 0;
    let alter = 0;
    let invend = 0;
    let decoupe = 0;
    let autre = 0;

    losses.forEach(l => {
      if (l.reason === 'Périmé') perm += l.estimatedCost;
      else if (l.reason === 'Altéré') alter += l.estimatedCost;
      else if (l.reason === 'Invendu') invend += l.estimatedCost;
      else if (l.reason === 'Erreur de découpe') decoupe += l.estimatedCost;
      else autre += l.estimatedCost;
    });

    return {
      'Périmé': perm,
      'Altéré': alter,
      'Invendu': invend,
      'Erreur de découpe': decoupe,
      'Autre': autre
    };
  }, [losses]);

  return (
    <div className="space-y-6" id="losses-tab">
      
      {/* Losses KPI Statistics Header */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {Object.entries(lossesStats).map(([res, sum]) => (
          <div key={res} className="bg-white p-4 rounded-[24px] border border-gray-100 shadow-sm">
            <span className="text-gray-400 text-xxs font-bold uppercase tracking-wider block">{res}</span>
            <span className="text-sm font-bold font-mono text-pink-600 block mt-1">{formatMoney(sum as number)}</span>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Loss Declaration Form (Col Span 5) */}
        <div className="lg:col-span-5 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center gap-2 border-b border-gray-50 pb-3">
            <AlertTriangle className="w-5 h-5 text-[#EC4899]" />
            <h2 className="text-base font-bold text-gray-900">Déclaration de Perte (Gaspillage)</h2>
          </div>

          {isSuccess && (
            <div className="p-3.5 bg-pink-50 text-pink-800 border border-pink-100 rounded-xl text-xs font-semibold flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-[#EC4899] animate-bounce" />
              Perte déclarée. Stock mis à jour et imputé en comptabilité (Compte 68).
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            
            {/* Select product */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Produit endommagé *</label>
              <select
                required
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
              >
                <option value="">-- Sélectionner Produit --</option>
                {availableProducts.map(p => (
                  <option key={p.id} value={p.id}>
                    {p.name} (Dispo: {p.quantity} {p.unit})
                  </option>
                ))}
              </select>
            </div>

            {/* Quantity and unit display */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Quantité Perdue *</label>
                <div className="relative">
                  <input
                    type="number"
                    step="any"
                    min="0.1"
                    required
                    placeholder="Ex: 2.5"
                    value={quantity || ''}
                    onChange={(e) => setQuantity(Number(e.target.value))}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold"
                  />
                  <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-[10px] text-gray-400 font-bold">
                    {selectedProduct ? selectedProduct.unit : 'kg'}
                  </span>
                </div>
              </div>

              {/* Reason */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Motif de la Perte</label>
                <select
                  value={reason}
                  onChange={(e) => setReason(e.target.value as any)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                >
                  <option value="Périmé">Périmé / Invendable</option>
                  <option value="Altéré">Altération de fraîcheur</option>
                  <option value="Invendu">Invendu fin de marché</option>
                  <option value="Erreur de découpe">Erreur de découpe</option>
                  <option value="Autre">Autre motif exceptionnel</option>
                </select>
              </div>
            </div>

            {/* Explanatory notes */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Description / Note explicative</label>
              <textarea
                placeholder="Indiquez les détails de l'incident (ex: rupture froid congélateur, avarie transport...)"
                rows={3}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold focus:outline-hidden"
              />
            </div>

            {/* Calculation summary cost box */}
            <div className="bg-slate-50 p-4 rounded-xl border border-gray-100 flex justify-between items-center text-xs">
              <div>
                <span className="text-gray-400 font-bold uppercase tracking-wider block text-[10px]">Perte Financière Estimée</span>
                <span className="text-gray-400 text-xxs font-medium">(Quantité x Prix d'Achat Moyen)</span>
              </div>
              <span className="font-mono text-base font-black text-[#EC4899]">
                {formatMoney(estimatedCost)}
              </span>
            </div>

            {/* Submit button */}
            <button
              type="submit"
              disabled={!productId}
              className="w-full py-2.5 bg-[#EC4899] hover:bg-pink-700 text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-xs transition disabled:opacity-40"
            >
              <TrendingDown className="w-4 h-4" /> Déclarer la perte
            </button>

          </form>
        </div>

        {/* Losses Ledger Log (Col Span 7) */}
        <div className="lg:col-span-7 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-gray-50 pb-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              <Clock className="w-4.5 h-4.5 text-gray-500" /> Registre de Spoliation & Déchets
            </h3>
            <span className="text-[10px] font-bold text-pink-600 bg-pink-50 px-2 py-0.5 rounded-full font-mono">
              {losses.length} déclarations
            </span>
          </div>

          <div className="space-y-3 overflow-y-auto max-h-[500px] pr-1">
            {losses.length === 0 ? (
              <div className="text-center p-8 text-gray-400 text-xs">
                Aucun déchet ou perte déclarée pour le moment.
              </div>
            ) : (
              losses.map((l) => (
                <div key={l.id} className="p-4 rounded-xl border border-pink-50 bg-pink-50/10 space-y-2 text-xs flex flex-col justify-between">
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-bold text-gray-800 text-sm flex items-center gap-1.5">
                        {l.productName} 
                        {!l.isSynced && (
                          <span className="w-1.5 h-1.5 bg-orange-400 rounded-full inline-block"></span>
                        )}
                      </h4>
                      <span className="text-[10px] text-gray-400">{new Date(l.date).toLocaleString('fr-FR')}</span>
                    </div>

                    <div className="text-right">
                      <span className="font-mono font-bold text-[#EC4899] block">-{formatMoney(l.estimatedCost)}</span>
                      <span className="text-[10px] text-pink-700 font-bold bg-pink-100/70 px-2 py-0.5 rounded-full mt-0.5 inline-block">
                        {l.reason}
                      </span>
                    </div>
                  </div>

                  {l.notes && (
                    <div className="p-2.5 bg-white border border-gray-100 rounded-lg text-gray-500 text-[11px] leading-relaxed flex items-start gap-1.5">
                      <Info className="w-3.5 h-3.5 text-gray-400 shrink-0 mt-0.5" />
                      <p>{l.notes}</p>
                    </div>
                  )}

                  <div className="flex justify-between text-[10px] text-gray-400 border-t border-gray-100/50 pt-2 font-mono">
                    <span>Quantité imputée: {l.quantity} {l.unit}</span>
                    <span>ID: {l.id}</span>
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
