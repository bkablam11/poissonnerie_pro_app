import React, { useMemo } from 'react';
import { DBState, LedgerEntry } from '../types';
import { 
  Building2, 
  ArrowRight, 
  Percent, 
  TrendingUp, 
  BookOpen, 
  HelpCircle,
  FileCheck2,
  CalendarDays
} from 'lucide-react';

interface AccountingTabProps {
  state: DBState;
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

export function AccountingTab({ state }: AccountingTabProps) {
  const { ledger, settings } = state;

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // 1. Calculate Balances for all core SYSCOHADA accounts
  const accountsData = useMemo(() => {
    const list = [
      { code: '101', name: 'Capital social', category: 'Passif / Capitaux' },
      { code: '2182', name: 'Matériel et équipement (Congélateurs...)', category: 'Actif / Immobilisations' },
      { code: '401', name: 'Fournisseurs d\'exploitation', category: 'Passif / Tiers' },
      { code: '411', name: 'Clients d\'exploitation (Créances VIP)', category: 'Actif / Tiers' },
      { code: '521', name: 'Banques et Établissements Financiers', category: 'Actif / Trésorerie' },
      { code: '571', name: 'Caisse de la Poissonnerie', category: 'Actif / Trésorerie' },
      { code: '601', name: 'Achats de marchandises (Approvisionnements)', category: 'Charge / Exploitation' },
      { code: '701', name: 'Ventes de marchandises (Chiffre d\'Affaires)', category: 'Produit / Exploitation' },
      { code: '65', name: 'Autres charges externes (Frais courants)', category: 'Charge / Exploitation' },
      { code: '68', name: 'Charges exceptionnelles (Pertes de stock)', category: 'Charge / Exceptionnelle' },
    ];

    return list.map(acc => ({
      ...acc,
      balance: getAccountBalance(ledger, acc.code)
    }));
  }, [ledger]);

  // 2. SIG (Soldes Intermédiaires de Gestion) calculations
  const sigCalculations = useMemo(() => {
    const ventes = getAccountBalance(ledger, '701');
    const achats = getAccountBalance(ledger, '601');
    
    // Marge Commerciale = Ventes de Marchandises - Achats de Marchandises
    const margeCommerciale = ventes - achats;

    // Filter services extérieurs from account 65 (we assume 65 contains glace, electricity, water, packaging, transport - except salaries)
    // To be precise, let's look at ledger entries for Salaries specifically:
    let chargesSalaires = 0;
    let chargesExternes = 0;
    ledger.forEach(entry => {
      if (entry.accountCode === '65') {
        if (entry.label.startsWith('Salaires')) {
          chargesSalaires += entry.amount;
        } else {
          chargesExternes += entry.amount;
        }
      }
    });

    // Valeur Ajoutée (VA) = Marge Commerciale - Charges Externes (Glace, Emballages, Énergie, Transport)
    const valeurAjoutee = margeCommerciale - chargesExternes;

    // Excédent Brut d'Exploitation (EBE) = Valeur Ajoutée - Charges Salariales
    const ebe = valeurAjoutee - chargesSalaires;

    // Résultat Net Estimé = EBE - Pertes/Avaries de stock (compte 68)
    const pertesStock = getAccountBalance(ledger, '68');
    const resultatNet = ebe - pertesStock;

    return {
      ventes,
      achats,
      margeCommerciale,
      chargesExternes,
      valeurAjoutee,
      chargesSalaires,
      ebe,
      pertesStock,
      resultatNet
    };
  }, [ledger]);

  return (
    <div className="space-y-6" id="accounting-tab">
      
      {/* Accounting Title */}
      <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-[#FF6B6B]" />
            Comptabilité Simplifiée SYSCOHADA
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Génération automatique d'écritures en partie double et calcul des Soldes Intermédiaires de Gestion (SIG).
          </p>
        </div>
        <div className="text-[11px] font-bold text-slate-500 bg-slate-100 px-3 py-1.5 rounded-xl flex items-center gap-1">
          <CalendarDays className="w-4 h-4 text-slate-400" />
          <span>Exercice Comptable {new Date().getFullYear()}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* SYSCOHADA Chart of Accounts (Col Span 6) */}
        <div className="lg:col-span-6 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-gray-50 pb-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              <Building2 className="w-4.5 h-4.5 text-gray-500" /> Grand Livre & Balances des Comptes
            </h3>
          </div>

          <div className="space-y-2.5 overflow-y-auto max-h-[500px] pr-1">
            {accountsData.map((acc) => (
              <div 
                key={acc.code} 
                className="flex items-center justify-between p-3 rounded-xl border border-gray-50 bg-slate-50/50 hover:bg-slate-50 transition text-xs"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono bg-slate-200/80 text-slate-700 font-black text-[10px] px-2 py-0.5 rounded-md w-11 text-center">
                      {acc.code}
                    </span>
                    <span className="font-bold text-gray-800 truncate max-w-[200px]">{acc.name}</span>
                  </div>
                  <span className="text-[9px] text-gray-400 block mt-1 uppercase tracking-wider font-semibold">{acc.category}</span>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-gray-900 text-sm block">
                    {formatMoney(acc.balance)}
                  </span>
                  <span className="text-[9px] text-gray-400 font-semibold block mt-0.5">Solde</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* SIG Intermediary balances dashboard (Col Span 6) */}
        <div className="lg:col-span-6 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-5">
          <div className="flex items-center justify-between border-b border-gray-50 pb-3">
            <h3 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              <Percent className="w-4.5 h-4.5 text-[#FF6B6B]" /> Soldes Intermédiaires de Gestion (SIG)
            </h3>
          </div>

          {/* Structured SIG Flow ladder */}
          <div className="space-y-4 text-xs font-medium text-gray-600">
            
            {/* Level 1: Revenue & Purchases */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center text-gray-500">
                <span className="flex items-center gap-1.5">Chiffre d'Affaires (+ Compte 701)</span>
                <span className="font-mono font-bold text-gray-900">{formatMoney(sigCalculations.ventes)}</span>
              </div>
              <div className="flex justify-between items-center text-gray-500">
                <span className="flex items-center gap-1.5">Coût d'Achat des Marchandises (- Compte 601)</span>
                <span className="font-mono font-bold text-gray-400">-{formatMoney(sigCalculations.achats)}</span>
              </div>
              
              {/* Result 1: Marge Commerciale */}
              <div className="flex justify-between items-center bg-orange-50/40 p-3 rounded-xl border border-orange-100/30 text-[#FF6B6B] font-bold">
                <span className="flex items-center gap-1">
                  Marge Commerciale Réalisée <ArrowRight className="w-3.5 h-3.5" />
                </span>
                <span className="font-mono text-base">{formatMoney(sigCalculations.margeCommerciale)}</span>
              </div>
            </div>

            {/* Level 2: Value Added */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center text-gray-500 pl-3">
                <span>Charges Externes de Conservation / Consommables (- Compte 65)</span>
                <span className="font-mono">-{formatMoney(sigCalculations.chargesExternes)}</span>
              </div>

              {/* Result 2: Valeur Ajoutée */}
              <div className="flex justify-between items-center bg-blue-50/40 p-3 rounded-xl border border-blue-100/30 text-blue-600 font-bold">
                <span className="flex items-center gap-1">
                  Valeur Ajoutée (Richesse Créée) <ArrowRight className="w-3.5 h-3.5" />
                </span>
                <span className="font-mono text-base">{formatMoney(sigCalculations.valeurAjoutee)}</span>
              </div>
            </div>

            {/* Level 3: EBITDA / EBE */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center text-gray-500 pl-3">
                <span>Charges Salariales de Main d'œuvre (- Compte 65 part salaires)</span>
                <span className="font-mono">-{formatMoney(sigCalculations.chargesSalaires)}</span>
              </div>

              {/* Result 3: EBE */}
              <div className="flex justify-between items-center bg-emerald-50/40 p-3 rounded-xl border border-emerald-100/30 text-emerald-600 font-bold">
                <span className="flex items-center gap-1">
                  Excédent Brut d'Exploitation (EBE / EBITDA) <ArrowRight className="w-3.5 h-3.5" />
                </span>
                <span className="font-mono text-base">{formatMoney(sigCalculations.ebe)}</span>
              </div>
            </div>

            {/* Level 4: Net Profit */}
            <div className="space-y-1.5">
              <div className="flex justify-between items-center text-gray-500 pl-3">
                <span>Pertes, Avaries et Spoliation de Poissons (- Compte 68)</span>
                <span className="font-mono text-[#EC4899] font-bold">-{formatMoney(sigCalculations.pertesStock)}</span>
              </div>

              {/* Result 4: Résultat Net Estimé */}
              <div className={`flex justify-between items-center p-3.5 rounded-xl border text-white font-bold ${
                sigCalculations.resultatNet >= 0 
                  ? 'bg-emerald-600 border-emerald-700 shadow-sm' 
                  : 'bg-pink-600 border-pink-700 shadow-sm'
              }`}>
                <span className="flex items-center gap-1.5 text-sm uppercase tracking-wide">
                  <FileCheck2 className="w-5 h-5 shrink-0" /> Résultat Net Estimé
                </span>
                <span className="font-mono text-lg">{formatMoney(sigCalculations.resultatNet)}</span>
              </div>
            </div>

          </div>

          <div className="p-3.5 bg-[#F8FAFC] rounded-xl border border-gray-100 text-[10px] text-gray-400 flex items-start gap-1.5 leading-relaxed">
            <HelpCircle className="w-4 h-4 text-gray-400 shrink-0 mt-0.5" />
            <p>
              Ce compte d'exploitation consolidé est dynamique. Toutes vos actions d'encaissement sur le POS, de déclarations de déchets, de frais courants ou de chargement d'arrivages recalculent instantanément ces indicateurs pour vous offrir une transparence totale sur la rentabilité de votre poissonnerie.
            </p>
          </div>

        </div>

      </div>

    </div>
  );
}
