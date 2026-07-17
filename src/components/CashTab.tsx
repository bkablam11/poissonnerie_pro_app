import React, { useState, useMemo } from 'react';
import { DBState, LedgerEntry } from '../types';
import { 
  CreditCard, 
  Coins, 
  ArrowDownLeft, 
  ArrowUpRight, 
  Plus, 
  Trash2, 
  Clock, 
  Search,
  Filter,
  CheckCircle,
  FileText
} from 'lucide-react';

interface CashTabProps {
  state: DBState;
  onAddExpense: (expense: {
    amount: number;
    category: 'Glace et Consommables' | 'Emballage' | 'Électricité & Eau' | 'Transport & Carburant' | 'Salaires' | 'Divers';
    paymentMode: 'Caisse' | 'Banque';
    label: string;
  }) => void;
}

// Balance helper
function getAccountBalance(ledger: LedgerEntry[], code: string): number {
  let debitSum = 0;
  let creditSum = 0;
  ledger.forEach(entry => {
    if (entry.accountCode === code) {
      if (entry.type === 'Débit') debitSum += entry.amount;
      else creditSum += entry.amount;
    }
  });
  
  // Asset and Expense accounts have natural DEBIT balances
  const debitAccounts = ['571', '521', '2182', '411', '601', '65', '68'];
  if (debitAccounts.includes(code)) {
    return debitSum - creditSum;
  } else {
    // Equity, Liabilities, Revenue accounts have natural CREDIT balances
    return creditSum - debitSum;
  }
}

export function CashTab({ state, onAddExpense }: CashTabProps) {
  const { ledger, settings } = state;

  // Form expense states
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState<'Glace et Consommables' | 'Emballage' | 'Électricité & Eau' | 'Transport & Carburant' | 'Salaires' | 'Divers'>('Glace et Consommables');
  const [paymentMode, setPaymentMode] = useState<'Caisse' | 'Banque'>('Caisse');
  const [label, setLabel] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);

  // Search/Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedAccount, setSelectedAccount] = useState('All'); // All, 571, 521

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // Get current balances
  const caisseBalance = useMemo(() => getAccountBalance(ledger, '571'), [ledger]);
  const banqueBalance = useMemo(() => getAccountBalance(ledger, '521'), [ledger]);

  // Handle submit expense
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const numAmt = Number(amount);
    if (isNaN(numAmt) || numAmt <= 0) {
      alert("Saisissez un montant supérieur à 0.");
      return;
    }
    if (!label.trim()) {
      alert("Précisez un libellé descriptif.");
      return;
    }

    // Safety checks on drawer limits
    if (paymentMode === 'Caisse' && numAmt > caisseBalance) {
      const force = window.confirm(`Le montant dépasse le solde de la caisse (${formatMoney(caisseBalance)}). Confirmer tout de même le paiement (caisse négative) ?`);
      if (!force) return;
    }
    if (paymentMode === 'Banque' && numAmt > banqueBalance) {
      const force = window.confirm(`Le montant dépasse le solde en banque (${formatMoney(banqueBalance)}). Confirmer tout de même ?`);
      if (!force) return;
    }

    onAddExpense({
      amount: numAmt,
      category,
      paymentMode,
      label
    });

    setAmount('');
    setLabel('');
    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 3000);
  };

  // Filtered chronological transaction log
  const filteredLedgerEntries = useMemo(() => {
    // We display entries that involve either Caisse (571) or Banque (521) to show direct cash flows
    return ledger.filter(entry => {
      const isTreasury = entry.accountCode === '571' || entry.accountCode === '521';
      if (!isTreasury) return false;

      // Filter account match
      if (selectedAccount !== 'All' && entry.accountCode !== selectedAccount) return false;

      // Filter search
      const matchesSearch = entry.label.toLowerCase().includes(searchQuery.toLowerCase()) || 
                            entry.accountName.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesSearch;
    });
  }, [ledger, selectedAccount, searchQuery]);

  return (
    <div className="space-y-6" id="cash-tab">
      
      {/* Treasury Real-time Balances */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Cash register 571 */}
        <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm flex items-center justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-xs font-bold uppercase tracking-wider block">Solde Caisse Physique (Compte 571)</span>
            <div className="text-3xl font-black font-mono text-gray-900 tracking-tight">
              {formatMoney(caisseBalance)}
            </div>
            <p className="text-xs text-gray-400">Pour les transactions quotidiennes au comptant en espèces.</p>
          </div>
          <div className="p-4 bg-orange-50 text-[#FF6B6B] rounded-2xl shadow-xs">
            <Coins className="w-8 h-8" />
          </div>
        </div>

        {/* Bank register 521 */}
        <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm flex items-center justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-xs font-bold uppercase tracking-wider block">Solde Banque & Mobile Money (Compte 521)</span>
            <div className="text-3xl font-black font-mono text-gray-900 tracking-tight">
              {formatMoney(banqueBalance)}
            </div>
            <p className="text-xs text-gray-400">Pour les règlements chèques, virements bancaires et services MoMo.</p>
          </div>
          <div className="p-4 bg-blue-50 text-blue-600 rounded-2xl shadow-xs">
            <CreditCard className="w-8 h-8" />
          </div>
        </div>

      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Expense Logger Form (Col Span 5) */}
        <div className="lg:col-span-5 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center gap-2 border-b border-gray-50 pb-3">
            <Plus className="w-5 h-5 text-[#FF6B6B]" />
            <h2 className="text-base font-bold text-gray-900">Enregistrer des Frais de Fonctionnement</h2>
          </div>

          {isSuccess && (
            <div className="p-3 bg-emerald-50 text-emerald-800 border border-emerald-100 rounded-xl text-xs font-semibold flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-emerald-600 animate-bounce" />
              Charge opérationnelle comptabilisée avec succès !
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            
            {/* Amount input */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Montant du frais *</label>
              <div className="relative">
                <input
                  type="number"
                  required
                  placeholder="Ex: 15000"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-base font-bold font-mono text-gray-900 focus:outline-hidden"
                />
                <span className="absolute right-3 top-1/2 transform -translate-y-1/2 font-bold text-gray-400 text-xs">
                  {settings.currency}
                </span>
              </div>
            </div>

            {/* Category selection */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Nature de la Charge *</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value as any)}
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
              >
                <option value="Glace et Consommables">Achat Glace (Écailles de conservation)</option>
                <option value="Emballage">Emballages et Sacs de transport</option>
                <option value="Électricité & Eau">Électricité & Factures Eau (Refroidissement)</option>
                <option value="Transport & Carburant">Transport & Carburant (Approvisionnement)</option>
                <option value="Salaires">Salaires et Main d'œuvre</option>
                <option value="Divers">Autres frais divers d'exploitation</option>
              </select>
            </div>

            {/* Account choice */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Source de Règlement *</label>
              <select
                value={paymentMode}
                onChange={(e) => setPaymentMode(e.target.value as any)}
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
              >
                <option value="Caisse">Espèces (Compte Caisse 571)</option>
                <option value="Banque">Banque / Mobile Money (Compte Banque 521)</option>
              </select>
            </div>

            {/* Description label */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Désignation / Libellé de paiement *</label>
              <input
                type="text"
                required
                placeholder="Ex: Achat 3 blocs de glace pour étal"
                value={label}
                onChange={(e) => setLabel(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold focus:outline-hidden"
              />
            </div>

            {/* Submit button */}
            <button
              type="submit"
              className="w-full py-2.5 bg-[#FF6B6B] hover:bg-coral-dark text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-xs transition"
            >
              <Plus className="w-4 h-4" /> Imputer la Charge
            </button>

          </form>
        </div>

        {/* Ledger logs panel (Col Span 7) */}
        <div className="lg:col-span-7 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-gray-50 pb-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              <Clock className="w-4.5 h-4.5 text-gray-500" /> Journal de Caisse & Banque
            </h3>
            
            {/* Table filters */}
            <div className="flex items-center gap-2">
              <select
                value={selectedAccount}
                onChange={(e) => setSelectedAccount(e.target.value)}
                className="bg-[#F8FAFC] border border-gray-100 px-3 py-1.5 rounded-lg text-[10px] font-bold text-gray-600 focus:outline-hidden"
              >
                <option value="All">Tous Comptes</option>
                <option value="571">571 (Caisse)</option>
                <option value="521">521 (Banque)</option>
              </select>
            </div>
          </div>

          {/* Search ledger */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
            <input
              type="text"
              placeholder="Filtrer par mot-clé (Ex: Vente, Sénégal)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#F8FAFC] border border-gray-100 pl-8 pr-3 py-1.5 rounded-lg text-[11px]"
            />
          </div>

          {/* Chronological List of Entries */}
          <div className="space-y-2 overflow-y-auto max-h-[400px] pr-1">
            {filteredLedgerEntries.length === 0 ? (
              <div className="text-center p-8 text-gray-400 text-xs">
                Aucun mouvement de trésorerie répertorié.
              </div>
            ) : (
              filteredLedgerEntries.map((entry) => {
                const isDebit = entry.type === 'Débit'; // For asset accounts, Debit is INFLOW, Credit is OUTFLOW
                
                return (
                  <div 
                    key={entry.id} 
                    className="flex items-center justify-between p-3 rounded-xl border border-gray-50 bg-slate-50/50 hover:bg-slate-50 transition text-xs"
                  >
                    <div className="flex items-center gap-2.5 min-w-0 flex-1 pr-3">
                      {isDebit ? (
                        <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg shrink-0">
                          <ArrowDownLeft className="w-4 h-4" />
                        </div>
                      ) : (
                        <div className="p-2 bg-pink-50 text-pink-500 rounded-lg shrink-0">
                          <ArrowUpRight className="w-4 h-4" />
                        </div>
                      )}
                      <div className="min-w-0">
                        <span className="font-bold text-gray-800 block truncate">{entry.label}</span>
                        <div className="flex items-center gap-1.5 text-[10px] text-gray-400 mt-0.5">
                          <span className="font-mono text-gray-500 font-semibold">C{entry.accountCode}</span>
                          <span>•</span>
                          <span>{new Date(entry.date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
                        </div>
                      </div>
                    </div>

                    <div className="text-right shrink-0">
                      <span className={`font-mono font-bold block ${isDebit ? 'text-emerald-600' : 'text-[#EC4899]'}`}>
                        {isDebit ? '+' : '-'}{formatMoney(entry.amount)}
                      </span>
                      <span className="text-[9px] text-gray-400 block font-medium mt-0.5">{entry.accountName}</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
