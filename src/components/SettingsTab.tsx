import React, { useState } from 'react';
import { DBState, Settings } from '../types';
import { 
  Sliders, 
  Save, 
  Database, 
  CloudLightning, 
  Trash2, 
  Download, 
  Building, 
  HelpCircle,
  Clock,
  CheckCircle,
  RefreshCw,
  ServerCrash
} from 'lucide-react';

interface SettingsTabProps {
  state: DBState;
  isOnline: boolean;
  isSyncing: boolean;
  syncError: string | null;
  pendingCount: number;
  onUpdateSettings: (settings: Settings) => void;
  onForceSync: () => void;
  onResetToSeed: () => void;
}

export function SettingsTab({
  state,
  isOnline,
  isSyncing,
  syncError,
  pendingCount,
  onUpdateSettings,
  onForceSync,
  onResetToSeed
}: SettingsTabProps) {
  const { settings } = state;

  // Form profile states
  const [shopName, setShopName] = useState(settings.shopName);
  const [address, setAddress] = useState(settings.address);
  const [phone, setPhone] = useState(settings.phone);
  const [taxId, setTaxId] = useState(settings.taxId);
  const [currency, setCurrency] = useState(settings.currency);
  const [vatRate, setVatRate] = useState(settings.vatRate);

  const [isSuccess, setIsSuccess] = useState(false);

  const handleProfileSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onUpdateSettings({
      shopName,
      address,
      phone,
      taxId,
      currency,
      vatRate: Number(vatRate),
      lastSync: settings.lastSync
    });

    setIsSuccess(true);
    setTimeout(() => setIsSuccess(false), 2500);
  };

  // Triggers down of complete client state
  const handleExportJSON = () => {
    try {
      const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(state, null, 2));
      const downloadAnchor = document.createElement('a');
      downloadAnchor.setAttribute("href", dataStr);
      downloadAnchor.setAttribute("download", `poissonnerie_pro_backup_${new Date().toISOString().split('T')[0]}.json`);
      document.body.appendChild(downloadAnchor);
      downloadAnchor.click();
      downloadAnchor.remove();
    } catch (e) {
      alert("Échec de l'exportation du fichier.");
    }
  };

  return (
    <div className="space-y-6" id="settings-tab">
      
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Profile Settings (Col Span 7) */}
        <div className="lg:col-span-7 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center gap-2 border-b border-gray-50 pb-3">
            <Building className="w-5 h-5 text-[#FF6B6B]" />
            <h2 className="text-base font-bold text-gray-900">Profil de la Poissonnerie & Préférences</h2>
          </div>

          {isSuccess && (
            <div className="p-3.5 bg-emerald-50 text-emerald-800 border border-emerald-100 rounded-xl text-xs font-semibold flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-emerald-600" />
              Préférences enregistrées localement !
            </div>
          )}

          <form onSubmit={handleProfileSubmit} className="space-y-4 text-xs">
            
            {/* Business name */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Raison Sociale / Nom Commercial *</label>
              <input
                type="text"
                required
                value={shopName}
                onChange={(e) => setShopName(e.target.value)}
                placeholder="Ex: Poissonnerie Pro"
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold"
              />
            </div>

            {/* Address */}
            <div className="space-y-1">
              <label className="font-bold text-gray-500 uppercase tracking-wider block">Adresse Géographique *</label>
              <input
                type="text"
                required
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="Ex: Abidjan, Côte d'Ivoire"
                className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold"
              />
            </div>

            {/* Telephone & Tax details */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Téléphone de l'Échoppe *</label>
                <input
                  type="text"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Ex: +225..."
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs"
                />
              </div>

              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Numéro de Compte Contribuable (ID Fiscal)</label>
                <input
                  type="text"
                  value={taxId}
                  onChange={(e) => setTaxId(e.target.value)}
                  placeholder="Ex: CC-0123456"
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-mono"
                />
              </div>
            </div>

            {/* Currency & VAT Rates */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Devise Monétaire Actuelle</label>
                <select
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                >
                  <option value="FCFA">Franc CFA (FCFA)</option>
                  <option value="EUR">Euro (€)</option>
                  <option value="USD">Dollar Américain ($)</option>
                  <option value="CAD">Dollar Canadien ($)</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Taux de TVA applicable (%)</label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  value={vatRate || 0}
                  onChange={(e) => setVatRate(Number(e.target.value))}
                  placeholder="Ex: 18"
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold text-center font-mono"
                />
              </div>
            </div>

            {/* Submit changes Button */}
            <button
              type="submit"
              className="w-full py-2.5 bg-[#FF6B6B] hover:bg-coral-dark text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-xs transition"
            >
              <Save className="w-4 h-4" /> Enregistrer les Paramètres
            </button>

          </form>
        </div>

        {/* Database & Sync Utility (Col Span 5) */}
        <div className="lg:col-span-5 bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-5">
          <div className="flex items-center gap-2 border-b border-gray-50 pb-3">
            <Database className="w-5 h-5 text-gray-500" />
            <h2 className="text-base font-bold text-gray-900">Synchronisation & Sauvegardes</h2>
          </div>

          {/* Sync Information Details */}
          <div className="p-4 bg-slate-50 border border-gray-100 rounded-xl space-y-3 text-xs text-gray-600">
            <div className="flex justify-between items-center">
              <span>Status Réseau :</span>
              <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase ${
                isOnline 
                  ? 'bg-emerald-100 text-emerald-800' 
                  : 'bg-pink-100 text-[#EC4899]'
              }`}>
                {isOnline ? "En Ligne" : "Hors Ligne"}
              </span>
            </div>

            <div className="flex justify-between items-center font-mono">
              <span>Modifications en attente :</span>
              <span className={`font-bold px-2 py-0.5 rounded ${pendingCount > 0 ? 'bg-orange-100 text-orange-700 animate-pulse' : 'bg-slate-200 text-slate-700'}`}>
                {pendingCount} écritures
              </span>
            </div>

            {settings.lastSync && (
              <div className="flex justify-between items-center text-[10px] text-gray-400">
                <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> Dernière Sync :</span>
                <span>{new Date(settings.lastSync).toLocaleString('fr-FR')}</span>
              </div>
            )}
          </div>

          {/* Display sync errors if any */}
          {syncError && (
            <div className="p-3 bg-pink-50 border border-pink-100 rounded-xl text-[10px] text-pink-700 font-medium flex items-start gap-1.5">
              <ServerCrash className="w-4 h-4 shrink-0 text-[#EC4899]" />
              <p>{syncError}</p>
            </div>
          )}

          {/* Synchronization and local tools */}
          <div className="space-y-3">
            
            {/* Forced manual Sync */}
            <button
              onClick={onForceSync}
              disabled={isSyncing}
              className="w-full py-2.5 bg-slate-100 hover:bg-[#FF6B6B]/10 text-gray-700 hover:text-[#FF6B6B] font-semibold rounded-xl text-xs flex items-center justify-center gap-1.5 border border-gray-200 transition cursor-pointer disabled:opacity-40"
            >
              <RefreshCw className={`w-4 h-4 ${isSyncing ? 'animate-spin' : ''}`} /> 
              {isSyncing ? "Synchronisation en cours..." : "Forcer la Synchronisation"}
            </button>

            {/* Export DB */}
            <button
              onClick={handleExportJSON}
              className="w-full py-2.5 bg-slate-100 hover:bg-slate-200 text-gray-700 font-semibold rounded-xl text-xs flex items-center justify-center gap-1.5 border border-gray-200 transition cursor-pointer"
            >
              <Download className="w-4 h-4" /> Sauvegarder la base (Format JSON)
            </button>

            <div className="border-t border-gray-100 pt-4 mt-2">
              <h4 className="text-[10px] font-black text-gray-400 uppercase tracking-wider mb-2">Zone de Danger</h4>
              {/* Reset to Seeds */}
              <button
                onClick={onResetToSeed}
                className="w-full py-2.5 bg-pink-50 hover:bg-pink-100 text-[#EC4899] hover:text-pink-700 font-semibold rounded-xl text-xs flex items-center justify-center gap-1.5 border border-pink-100 transition cursor-pointer active:scale-98"
              >
                <Trash2 className="w-4 h-4" /> Réinitialiser la Base Locale
              </button>
            </div>

          </div>

          <div className="text-[10px] text-gray-400 leading-relaxed flex items-start gap-1.5 p-1 bg-slate-50/50 rounded-lg">
            <HelpCircle className="w-4.5 h-4.5 shrink-0 text-gray-400 mt-0.5" />
            <p>
              La synchronisation cloud transmet toutes vos données locales (modifiées hors ligne) de manière sécurisée en fusionnant les entrées sur des clés d'identifications uniques et des horodatages fiables.
            </p>
          </div>

        </div>

      </div>

    </div>
  );
}
