import React, { useState } from 'react';
import { useFishState } from './useFishState';

// Importing all 9 tabs
import { DashboardTab } from './components/DashboardTab';
import { PosTab } from './components/PosTab';
import { StockTab } from './components/StockTab';
import { PurchasesTab } from './components/PurchasesTab';
import { LossesTab } from './components/LossesTab';
import { CashTab } from './components/CashTab';
import { AccountingTab } from './components/AccountingTab';
import { ContactsTab } from './components/ContactsTab';
import { SettingsTab } from './components/SettingsTab';

// Importing Lucide Icons
import { 
  LayoutDashboard, 
  ShoppingBag, 
  Package, 
  Truck, 
  AlertTriangle, 
  Coins, 
  BookOpen, 
  Users, 
  Sliders, 
  Menu, 
  X, 
  Wifi, 
  WifiOff, 
  RefreshCw, 
  Activity,
  LogOut,
  Building,
  Info
} from 'lucide-react';

export default function App() {
  const {
    state,
    isOnline,
    isManualOffline,
    isSyncing,
    syncError,
    pendingCount,
    setOfflineMode,
    syncWithServer,
    resetToSeed,

    // Mutation operations
    addProduct,
    updateProduct,
    deleteProduct,
    addContact,
    updateContact,
    deleteContact,
    addSale,
    addPurchase,
    addLoss,
    addExpense,
    updateSettings,
  } = useFishState();

  // Active Tab Index (0-based)
  const [activeTab, setActiveTab] = useState(0);

  // Mobile drawer open state
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Navigation tabs config list
  const tabConfig = [
    { label: "Tableau de Bord", icon: LayoutDashboard },
    { label: "Point de Vente (POS)", icon: ShoppingBag },
    { label: "Gestion du Stock", icon: Package },
    { label: "Approvisionnements", icon: Truck },
    { label: "Gestion des Pertes", icon: AlertTriangle },
    { label: "Caisse & Trésorerie", icon: Coins },
    { label: "Comptabilité SYSCOHADA", icon: BookOpen },
    { label: "Annuaire Contacts", icon: Users },
    { label: "Configuration", icon: Sliders },
  ];

  // Dynamically render active tab view
  const renderActiveTab = () => {
    switch (activeTab) {
      case 0:
        return <DashboardTab state={state} onNavigateToTab={(idx) => setActiveTab(idx)} />;
      case 1:
        return (
          <PosTab 
            state={state} 
            onAddSale={addSale} 
            onNavigateToTab={(idx) => setActiveTab(idx)} 
          />
        );
      case 2:
        return (
          <StockTab 
            state={state} 
            onAddProduct={addProduct} 
            onUpdateProduct={updateProduct} 
            onDeleteProduct={deleteProduct} 
          />
        );
      case 3:
        return (
          <PurchasesTab 
            state={state} 
            onAddPurchase={addPurchase} 
            onNavigateToTab={(idx) => setActiveTab(idx)} 
          />
        );
      case 4:
        return (
          <LossesTab 
            state={state} 
            onAddLoss={addLoss} 
            onNavigateToTab={(idx) => setActiveTab(idx)} 
          />
        );
      case 5:
        return <CashTab state={state} onAddExpense={addExpense} />;
      case 6:
        return <AccountingTab state={state} />;
      case 7:
        return (
          <ContactsTab 
            state={state} 
            onAddContact={addContact} 
            onUpdateContact={updateContact} 
            onDeleteContact={deleteContact} 
          />
        );
      case 8:
        return (
          <SettingsTab 
            state={state} 
            isOnline={isOnline} 
            isSyncing={isSyncing} 
            syncError={syncError} 
            pendingCount={pendingCount} 
            onUpdateSettings={updateSettings} 
            onForceSync={() => syncWithServer(true)} 
            onResetToSeed={resetToSeed} 
          />
        );
      default:
        return <DashboardTab state={state} onNavigateToTab={(idx) => setActiveTab(idx)} />;
    }
  };

  return (
    <div className="min-h-screen bg-[#F5F6FA] text-slate-800 flex flex-col font-sans" id="app-root">
      
      {/* Network background-sync status bar */}
      <div className="bg-slate-900 text-white text-xs px-4 py-2 flex flex-col sm:flex-row sm:items-center justify-between gap-2 no-print">
        
        {/* Connection simulation badge */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5">
            {isOnline ? (
              <span className="flex items-center gap-1 text-emerald-400 font-bold">
                <Wifi className="w-4 h-4" /> Connecté
              </span>
            ) : (
              <span className="flex items-center gap-1 text-pink-400 font-bold">
                <WifiOff className="w-4 h-4 animate-pulse" /> Mode Hors Ligne
              </span>
            )}
          </div>
          
          {/* Force connection override (simulate online/offline) */}
          <div className="flex items-center gap-1 bg-slate-800 p-0.5 rounded-lg border border-slate-700">
            <button
              onClick={() => setOfflineMode(false)}
              className={`px-2 py-0.5 rounded-md text-[10px] font-semibold transition ${!isManualOffline ? 'bg-emerald-500 text-slate-900 shadow-sm' : 'text-gray-400 hover:text-white'}`}
            >
              En Ligne (Serveur)
            </button>
            <button
              onClick={() => setOfflineMode(true)}
              className={`px-2 py-0.5 rounded-md text-[10px] font-semibold transition ${isManualOffline ? 'bg-pink-500 text-white shadow-sm' : 'text-gray-400 hover:text-white'}`}
            >
              Simuler Hors Ligne
            </button>
          </div>
        </div>

        {/* Sync queue diagnostics */}
        <div className="flex items-center gap-3 text-xxs sm:text-xs">
          {pendingCount > 0 ? (
            <span className="text-orange-300 font-semibold animate-pulse flex items-center gap-1">
              <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
              {pendingCount} écritures locales en attente de synchronisation
            </span>
          ) : (
            <span className="text-emerald-400 font-medium flex items-center gap-1">
              ✓ Toutes les écritures locales sont synchronisées sur le cloud
            </span>
          )}

          {pendingCount > 0 && isOnline && (
            <button
              onClick={() => syncWithServer()}
              disabled={isSyncing}
              className="bg-[#FF6B6B] hover:bg-coral-dark text-white px-2.5 py-0.5 rounded-md font-semibold text-[10px] active:scale-95 transition"
            >
              Forcer Sync
            </button>
          )}
        </div>
      </div>

      {/* Main ERP Layout Panel */}
      <div className="flex-1 flex flex-row relative items-stretch">
        
        {/* DESKTOP SIDEBAR (Menu de navigation gauche persistant) */}
        <aside className="hidden lg:flex w-64 bg-[#2E3A4B] text-white flex-col justify-between py-6 px-4 shrink-0 no-print">
          
          {/* Logo & Corporate profile block */}
          <div className="space-y-6">
            <div className="flex items-center gap-3 px-2">
              <div className="w-10 h-10 rounded-xl bg-[#FF6B6B] flex items-center justify-center text-white text-lg font-black shadow-md shadow-slate-900/40">
                P
              </div>
              <div>
                <h2 className="font-extrabold text-sm leading-tight tracking-tight text-white">{state.settings.shopName}</h2>
                <span className="text-[9px] text-slate-300 tracking-wider uppercase font-semibold">ERP & POS Maritime</span>
              </div>
            </div>

            {/* Navigation links list */}
            <nav className="space-y-1">
              {tabConfig.map((tab, idx) => {
                const Icon = tab.icon;
                const isActive = activeTab === idx;

                return (
                  <button
                    key={tab.label}
                    onClick={() => setActiveTab(idx)}
                    className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold tracking-wide transition duration-150 cursor-pointer ${
                      isActive 
                        ? 'bg-[#FF6B6B] text-white shadow-sm shadow-[#FF6B6B]/20' 
                        : 'text-slate-300 hover:bg-slate-700/50 hover:text-white'
                    }`}
                  >
                    <Icon className="w-4 h-4 shrink-0" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Footer User Panel block */}
          <div className="border-t border-slate-700/60 pt-4 px-2 flex items-center justify-between">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-8 h-8 rounded-full bg-[#FF6B6B]/20 border border-[#FF6B6B]/40 flex items-center justify-center text-white font-bold text-xs shrink-0">
                A
              </div>
              <div className="min-w-0">
                <span className="text-xs font-bold block text-white truncate">Gérant Poisson</span>
                <span className="text-[9px] text-slate-400 block truncate">bkablam11@gmail.com</span>
              </div>
            </div>
            
            {/* Quick reset/logout trigger */}
            <button 
              onClick={resetToSeed}
              className="p-1.5 text-slate-400 hover:text-[#FF6B6B] hover:bg-slate-700/30 rounded-lg transition"
              title="Réinitialiser"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>

        </aside>

        {/* MOBILE UPPER APPBAR (visible on mobile only) */}
        <div className="lg:hidden bg-[#2E3A4B] text-white h-16 px-4 flex items-center justify-between shrink-0 border-b border-slate-700/30 no-print w-full">
          <div className="flex items-center gap-2.5">
            <button 
              onClick={() => setIsMobileMenuOpen(true)}
              className="p-1.5 hover:bg-slate-700 text-white rounded-lg transition"
            >
              <Menu className="w-6 h-6" />
            </button>
            <span className="font-extrabold text-sm tracking-tight">{state.settings.shopName}</span>
          </div>
          
          <div className="w-9 h-9 rounded-lg bg-[#FF6B6B] flex items-center justify-center text-white text-sm font-black">
            P
          </div>
        </div>

        {/* MOBILE SIDEBAR DRAWER OVERLAY (visible on hamburger tap) */}
        {isMobileMenuOpen && (
          <div className="fixed inset-0 z-50 flex lg:hidden bg-black/50 no-print animate-fadeIn">
            <div className="w-64 bg-[#2E3A4B] text-white flex flex-col justify-between p-5 space-y-6 shadow-xl animate-slideIn">
              
              <div className="space-y-5">
                <div className="flex items-center justify-between border-b border-slate-700/40 pb-4">
                  <div className="flex items-center gap-2.5">
                    <div className="w-10 h-10 rounded-lg bg-[#FF6B6B] flex items-center justify-center text-white text-base font-black">
                      P
                    </div>
                    <div>
                      <h3 className="font-bold text-xs leading-none text-white">{state.settings.shopName}</h3>
                      <span className="text-[9px] text-slate-400 uppercase font-semibold">ERP Poissonnerie</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setIsMobileMenuOpen(false)}
                    className="p-1 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                {/* Mobile Links */}
                <nav className="space-y-1">
                  {tabConfig.map((tab, idx) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === idx;

                    return (
                      <button
                        key={tab.label}
                        onClick={() => {
                          setActiveTab(idx);
                          setIsMobileMenuOpen(false);
                        }}
                        className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold tracking-wide transition cursor-pointer ${
                          isActive 
                            ? 'bg-[#FF6B6B] text-white' 
                            : 'text-slate-300 hover:bg-slate-700/50 hover:text-white'
                        }`}
                      >
                        <Icon className="w-4 h-4 shrink-0" />
                        <span>{tab.label}</span>
                      </button>
                    );
                  })}
                </nav>
              </div>

              {/* Bottom user profile */}
              <div className="border-t border-slate-700/50 pt-4 flex items-center justify-between text-xs">
                <div>
                  <span className="font-bold block text-white text-xs">Admin Poisson</span>
                  <span className="text-[9px] text-slate-400 block mt-0.5">bkablam11@gmail.com</span>
                </div>
                <button 
                  onClick={() => {
                    setIsMobileMenuOpen(false);
                    resetToSeed();
                  }}
                  className="p-1.5 text-slate-400 hover:text-[#FF6B6B] rounded-lg hover:bg-slate-700/30"
                >
                  <LogOut className="w-4 h-4" />
                </button>
              </div>

            </div>
          </div>
        )}

        {/* WORKSPACE CONTAINER WITH HEADER AND CONTENT */}
        <div className="flex-1 flex flex-col overflow-hidden">
          
          {/* Universal Header (desktop only) */}
          <header className="hidden lg:flex h-16 bg-white border-b border-gray-200 px-8 items-center justify-between shrink-0 no-print">
            <div className="flex items-center gap-4">
              <h1 className="text-base font-bold text-gray-800">{tabConfig[activeTab].label}</h1>
              {pendingCount === 0 ? (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider text-green-600 bg-green-50 border border-green-100 flex items-center gap-1">
                  ✓ Sync OK
                </span>
              ) : (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider text-orange-600 bg-orange-50 border border-orange-100 animate-pulse">
                  {pendingCount} En Attente
                </span>
              )}
            </div>
            
            <div className="flex items-center gap-6">
              <div className="text-right">
                <p className="text-[9px] text-gray-400 uppercase font-bold tracking-widest leading-none">Status Réseau</p>
                <p className="text-xs font-semibold text-gray-600 mt-1">
                  {isOnline ? "En Ligne" : "Hors Ligne"}
                </p>
              </div>
              {activeTab !== 1 && (
                <button 
                  onClick={() => setActiveTab(1)}
                  className="px-4 py-2 rounded-xl text-white text-xs font-semibold bg-[#FF6B6B] hover:bg-coral-dark transition-all duration-150 shadow-xs cursor-pointer active:scale-95"
                >
                  + Nouvelle Vente
                </button>
              )}
            </div>
          </header>

          {/* WORKSPACE AREA (where active tab is rendered) */}
          <main className="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8 max-w-7xl mx-auto w-full">
            {renderActiveTab()}
          </main>
        </div>

      </div>

    </div>
  );
}
