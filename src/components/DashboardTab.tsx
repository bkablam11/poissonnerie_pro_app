import React, { useMemo } from 'react';
import { DBState, LedgerEntry, Product } from '../types';
import { 
  TrendingUp, 
  TrendingDown, 
  Package, 
  DollarSign, 
  AlertTriangle, 
  CreditCard, 
  Inbox, 
  ArrowUpRight,
  ShieldCheck,
  Percent
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  Tooltip, 
  Legend, 
  PieChart, 
  Pie, 
  Cell,
  BarChart,
  Bar
} from 'recharts';

interface DashboardTabProps {
  state: DBState;
  onNavigateToTab: (index: number) => void;
}

// Accounting helper to get balances dynamically from ledger
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

export function DashboardTab({ state, onNavigateToTab }: DashboardTabProps) {
  const { products, sales, losses, ledger, settings } = state;

  // Format currency helper
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { 
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // 1. KPI Calculations
  const todaySales = useMemo(() => {
    const todayStr = new Date().toISOString().split('T')[0];
    return sales
      .filter(s => s.date.startsWith(todayStr))
      .reduce((sum, s) => sum + s.total, 0);
  }, [sales]);

  const stockValue = useMemo(() => {
    return products.reduce((sum, p) => sum + (p.quantity * p.avgPurchasePrice), 0);
  }, [products]);

  const weeklyLosses = useMemo(() => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    return losses
      .filter(l => new Date(l.date) >= sevenDaysAgo)
      .reduce((sum, l) => sum + l.estimatedCost, 0);
  }, [losses]);

  const caisseBalance = useMemo(() => getAccountBalance(ledger, '571'), [ledger]);
  const banqueBalance = useMemo(() => getAccountBalance(ledger, '521'), [ledger]);
  const totalTreasury = caisseBalance + banqueBalance;

  // 2. Alert stocks below threshold
  const lowStockItems = useMemo(() => {
    return products.filter(p => p.quantity <= p.alertThreshold);
  }, [products]);

  // 3. Recharts Area Chart: 7-day Sales vs. Expenses
  const salesVsExpensesData = useMemo(() => {
    const dataPoints = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];

      // Sum sales
      const daySales = sales
        .filter(s => s.date.startsWith(dateStr))
        .reduce((sum, s) => sum + s.total, 0);

      // Sum expenses from ledger: 601 (purchases), 65 (charges), 68 (losses)
      const dayExpenses = ledger
        .filter(entry => entry.date.startsWith(dateStr) && entry.type === 'Débit' && ['601', '65', '68'].includes(entry.accountCode))
        .reduce((sum, entry) => sum + entry.amount, 0);

      dataPoints.push({
        day: d.toLocaleDateString('fr-FR', { weekday: 'short' }),
        Ventes: daySales,
        Dépenses: dayExpenses,
      });
    }
    return dataPoints;
  }, [sales, ledger]);

  // 4. Recharts Pie Chart: Sales by product category
  const pieData = useMemo(() => {
    const catMap: { [key: string]: number } = {
      'Poissons': 0,
      'Crustacés': 0,
      'Coquillages': 0,
      'Traiteur': 0
    };

    sales.forEach(sale => {
      sale.items.forEach(item => {
        // Find product category
        const prod = products.find(p => p.id === item.productId);
        const cat = prod ? prod.category : 'Poissons'; // Fallback
        catMap[cat] = (catMap[cat] || 0) + (item.quantity * item.price);
      });
    });

    return Object.keys(catMap).map(key => ({
      name: key,
      value: catMap[key]
    })).filter(item => item.value > 0);
  }, [sales, products]);

  // Pie chart colors matching the design system
  const PIE_COLORS = {
    'Poissons': '#3B82F6',   // Azure blue
    'Crustacés': '#FF6B6B',  // Coral primary
    'Coquillages': '#EC4899', // Fuchsia loss / alert
    'Traiteur': '#22C55E'    // Success emerald
  };

  return (
    <div className="space-y-6" id="dashboard-tab">
      
      {/* Top Welcome Title */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-gray-900">
            {settings.shopName} — ERP & POS
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            Tableau d'analyse et d'activité financière de votre poissonnerie en temps réel.
          </p>
        </div>
        <div className="flex items-center gap-2 bg-emerald-50 text-emerald-700 px-4 py-2 rounded-xl text-sm font-semibold border border-emerald-100">
          <ShieldCheck className="w-5 h-5 text-emerald-600 animate-pulse" />
          <span>Base Locale Sécurisée (Offline-First Active)</span>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        
        {/* KPI 1: Today's Sales */}
        <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex items-start justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-[10px] font-bold uppercase tracking-wider">Ventes du Jour</span>
            <div className="text-2xl font-bold text-gray-900 font-mono tracking-tight">
              {formatMoney(todaySales)}
            </div>
            <div className="flex items-center text-xs text-emerald-600 font-medium">
              <ArrowUpRight className="w-3 h-3 mr-0.5" />
              <span>Enregistrements directs</span>
            </div>
          </div>
          <div className="p-3 rounded-xl bg-orange-50 text-[#FF6B6B]">
            <TrendingUp className="w-6 h-6" />
          </div>
        </div>

        {/* KPI 2: Stock Purchase Value */}
        <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex items-start justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-[10px] font-bold uppercase tracking-wider">Valeur du Stock</span>
            <div className="text-2xl font-bold text-gray-900 font-mono tracking-tight">
              {formatMoney(stockValue)}
            </div>
            <div className="text-xs text-gray-500 font-medium">
              Basé sur le Prix d'Achat Moyen
            </div>
          </div>
          <div className="p-3 rounded-xl bg-blue-50 text-blue-600">
            <Package className="w-6 h-6" />
          </div>
        </div>

        {/* KPI 3: Weekly Losses */}
        <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex items-start justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-[10px] font-bold uppercase tracking-wider">Pertes (7j)</span>
            <div className="text-2xl font-bold text-[#EC4899] font-mono tracking-tight">
              {formatMoney(weeklyLosses)}
            </div>
            <div className="text-xs text-[#EC4899] font-medium flex items-center">
              <TrendingDown className="w-3. h-3 mr-0.5" />
              <span>Spoliation et Déchets</span>
            </div>
          </div>
          <div className="p-3 rounded-xl bg-pink-50 text-pink-600">
            <AlertTriangle className="w-6 h-6" />
          </div>
        </div>

        {/* KPI 4: Total Cash + Bank Treasury */}
        <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex items-start justify-between">
          <div className="space-y-2">
            <span className="text-gray-400 text-[10px] font-bold uppercase tracking-wider">Trésorerie Disponible</span>
            <div className="text-2xl font-bold text-emerald-600 font-mono tracking-tight">
              {formatMoney(totalTreasury)}
            </div>
            <div className="text-xs text-gray-500 font-medium flex items-center gap-1.5">
              <span className="inline-block w-2 h-2 rounded-full bg-orange-400"></span>
              <span>Caisse : {formatMoney(caisseBalance)}</span>
            </div>
          </div>
          <div className="p-3 rounded-xl bg-emerald-50 text-emerald-600">
            <CreditCard className="w-6 h-6" />
          </div>
        </div>

      </div>

      {/* Main Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Sales vs Expenses 7-Day Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-bold text-gray-900">Activité des 7 Derniers Jours</h2>
              <p className="text-xs text-gray-400">Comparaison financière entre le Chiffre d'Affaires et les dépenses d'approvisionnement / charges.</p>
            </div>
            <span className="text-xs font-semibold text-gray-500 bg-gray-100 px-2.5 py-1 rounded-md">Hebdomadaire</span>
          </div>

          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={salesVsExpensesData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorVentes" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22C55E" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#22C55E" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorExpenses" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#FF6B6B" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#FF6B6B" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#94A3B8' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#94A3B8' }} axisLine={false} tickLine={false} />
                <Tooltip 
                  contentStyle={{ background: '#FFF', borderRadius: '12px', border: '1px solid #F1F5F9', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.05)' }} 
                  formatter={(val: number) => [formatMoney(val), ""]}
                />
                <Legend iconType="circle" wrapperStyle={{ fontSize: 12, paddingTop: 10 }} />
                <Area type="monotone" dataKey="Ventes" stroke="#22C55E" strokeWidth={2} fillOpacity={1} fill="url(#colorVentes)" />
                <Area type="monotone" dataKey="Dépenses" stroke="#FF6B6B" strokeWidth={2} fillOpacity={1} fill="url(#colorExpenses)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Category Split Chart */}
        <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm flex flex-col justify-between">
          <div className="space-y-1">
            <h2 className="text-base font-bold text-gray-900">Ventes par Catégorie</h2>
            <p className="text-xs text-gray-400">Répartition volumétrique du Chiffre d'Affaires global.</p>
          </div>

          <div className="h-52 w-full flex items-center justify-center relative">
            {pieData.length === 0 ? (
              <div className="text-center text-gray-400 text-sm">
                <Inbox className="w-10 h-10 mx-auto opacity-40 mb-2" />
                Aucune vente enregistrée
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={80}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={PIE_COLORS[entry.name as keyof typeof PIE_COLORS] || '#CBD5E1'} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(val: number) => [formatMoney(val), ""]} />
                </PieChart>
              </ResponsiveContainer>
            )}
            {pieData.length > 0 && (
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xs text-gray-400 font-semibold uppercase tracking-wider">Top Vente</span>
                <span className="text-lg font-extrabold text-gray-700">Seafood</span>
              </div>
            )}
          </div>

          {/* Legend Table */}
          <div className="space-y-2 mt-2">
            {['Poissons', 'Crustacés', 'Coquillages', 'Traiteur'].map((cat) => {
              const matched = pieData.find(d => d.name === cat);
              const amount = matched ? matched.value : 0;
              const totalAmount = pieData.reduce((acc, curr) => acc + curr.value, 0);
              const percentage = totalAmount > 0 ? Math.round((amount / totalAmount) * 100) : 0;

              return (
                <div key={cat} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: PIE_COLORS[cat as keyof typeof PIE_COLORS] }}></span>
                    <span className="font-medium text-gray-600">{cat}</span>
                  </div>
                  <div className="font-mono text-gray-500 font-semibold">
                    {formatMoney(amount)} <span className="text-gray-400 font-normal ml-1">({percentage}%)</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

      </div>

      {/* Stocks Bas / Alertes Widget Panel */}
      <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-pink-600" />
            <h2 className="text-base font-bold text-gray-900">
              Alertes de Stock Bas ({lowStockItems.length})
            </h2>
          </div>
          <button 
            onClick={() => onNavigateToTab(2)} // Navigate to stocks
            className="text-xs font-semibold text-[#FF6B6B] hover:text-coral-dark flex items-center gap-0.5 hover:underline"
          >
            S'approvisionner <ArrowUpRight className="w-3.5 h-3.5" />
          </button>
        </div>

        {lowStockItems.length === 0 ? (
          <div className="bg-emerald-50 text-emerald-800 p-4 rounded-xl text-sm font-medium border border-emerald-100 flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-emerald-600" />
            Excellent ! Tous vos articles dépassent leur seuil de sécurité d'inventaire.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {lowStockItems.map((prod) => (
              <div 
                key={prod.id} 
                className="flex items-center justify-between p-3.5 rounded-xl border border-pink-100 bg-pink-50/30 hover:bg-pink-50/50 transition duration-150"
              >
                <div>
                  <h4 className="font-semibold text-gray-900 text-sm">{prod.name}</h4>
                  <div className="flex items-center gap-2 text-xs text-gray-400 mt-1">
                    <span>Seuil: {prod.alertThreshold} {prod.unit}</span>
                    <span>•</span>
                    <span className="text-pink-600 font-semibold bg-pink-100/70 px-1.5 py-0.5 rounded">Sensible / À Commander</span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-base font-bold font-mono text-[#EC4899]">
                    {prod.quantity} {prod.unit}
                  </div>
                  <span className="text-xxs text-gray-400 uppercase tracking-wider block mt-0.5">Dispo</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

    </div>
  );
}
