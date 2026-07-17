import { useState, useEffect, useCallback, useRef } from 'react';
import { DBState, Product, Contact, Sale, Purchase, Loss, LedgerEntry, Settings } from './types';
import { INITIAL_STATE } from './seedData';

const LOCAL_STORAGE_KEY = 'fish_manager_pro_db';
const MANUAL_OFFLINE_KEY = 'fish_manager_pro_manual_offline';

export function useFishState() {
  const [state, setState] = useState<DBState>(() => {
    const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        console.error("Error loading local state, fallback to seed data", e);
      }
    }
    return INITIAL_STATE;
  });

  // Track if physical internet is available vs. simulated offline toggle
  const [isManualOffline, setIsManualOffline] = useState<boolean>(() => {
    return localStorage.getItem(MANUAL_OFFLINE_KEY) === 'true';
  });
  const [isNetworkOnline, setIsNetworkOnline] = useState<boolean>(navigator.onLine);
  
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncError, setSyncError] = useState<string | null>(null);

  // Effective connection status
  const isOnline = isNetworkOnline && !isManualOffline;

  // Sync count: sum of items with isSynced === false
  const getPendingCount = useCallback(() => {
    let count = 0;
    state.products.forEach(p => { if (!p.isSynced) count++; });
    state.sales.forEach(s => { if (!s.isSynced) count++; });
    state.purchases.forEach(p => { if (!p.isSynced) count++; });
    state.losses.forEach(l => { if (!l.isSynced) count++; });
    state.contacts.forEach(c => { if (!c.isSynced) count++; });
    state.ledger.forEach(l => { if (!l.isSynced) count++; });
    return count;
  }, [state]);

  const pendingCount = getPendingCount();

  // Listen for actual network status changes
  useEffect(() => {
    const handleOnline = () => setIsNetworkOnline(true);
    const handleOffline = () => setIsNetworkOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Save state to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  // Handle manual offline toggle
  const setOfflineMode = useCallback((offline: boolean) => {
    setIsManualOffline(offline);
    localStorage.setItem(MANUAL_OFFLINE_KEY, String(offline));
  }, []);

  // Synchronize data with the distant server
  const syncWithServer = useCallback(async (force = false) => {
    if (!isOnline && !force) {
      setSyncError("Impossible de synchroniser : appareil hors ligne.");
      return;
    }

    setIsSyncing(true);
    setSyncError(null);

    try {
      // Gather all local state
      // We send our entire current local database, and the server merges based on newer timestamps
      const response = await fetch('/api/sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(state),
      });

      if (!response.ok) {
        throw new Error(`Erreur serveur : ${response.statusText}`);
      }

      const resData = await response.json();
      if (resData.success && resData.data) {
        // Server sends back fully merged DB
        const serverDB: DBState = resData.data;

        // Mark all as synced on client side
        const syncedState: DBState = {
          products: serverDB.products.map(p => ({ ...p, isSynced: true })),
          sales: serverDB.sales.map(s => ({ ...s, isSynced: true })),
          purchases: serverDB.purchases.map(p => ({ ...p, isSynced: true })),
          losses: serverDB.losses.map(l => ({ ...l, isSynced: true })),
          contacts: serverDB.contacts.map(c => ({ ...c, isSynced: true })),
          ledger: serverDB.ledger.map(l => ({ ...l, isSynced: true })),
          settings: {
            ...serverDB.settings,
            lastSync: Date.now()
          }
        };

        setState(syncedState);
      } else {
        throw new Error(resData.message || "Erreur de synchronisation inconnue.");
      }
    } catch (err: any) {
      console.error("Sync error:", err);
      setSyncError(err.message || "Échec de la connexion avec le serveur distant.");
    } finally {
      setIsSyncing(false);
    }
  }, [state, isOnline]);

  // Attempt automatic background synchronization if online and there are unsynced items
  const syncTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  useEffect(() => {
    if (isOnline && pendingCount > 0) {
      // Debounce the auto-sync to avoid spamming the server
      if (syncTimeoutRef.current) {
        clearTimeout(syncTimeoutRef.current);
      }
      syncTimeoutRef.current = setTimeout(() => {
        syncWithServer();
      }, 5000); // Sync 5 seconds after last change
    }

    return () => {
      if (syncTimeoutRef.current) {
        clearTimeout(syncTimeoutRef.current);
      }
    };
  }, [isOnline, pendingCount, syncWithServer]);

  // Force local reset to seed data
  const resetToSeed = useCallback(() => {
    if (window.confirm("Êtes-vous sûr de vouloir réinitialiser toutes les données locales aux valeurs de départ ?")) {
      setState(INITIAL_STATE);
      // Try to notify server to clear as well
      fetch('/api/sync/reset', { method: 'POST' }).catch(() => {});
    }
  }, []);

  // --- MUTATIONS ---

  // Helper to save generic table changes with appropriate timestamp & unsynced flag
  const updateTable = <K extends keyof DBState>(key: K, updatedList: DBState[K]) => {
    setState(prev => ({
      ...prev,
      [key]: updatedList,
      updatedAt: Date.now()
    }));
  };

  // 1. PRODUCTS MUTATIONS
  const addProduct = useCallback((product: Omit<Product, 'id' | 'updatedAt' | 'isSynced'>) => {
    const newProduct: Product = {
      ...product,
      id: `prod-${Date.now()}`,
      updatedAt: Date.now(),
      isSynced: false
    };
    setState(prev => ({
      ...prev,
      products: [newProduct, ...prev.products]
    }));
  }, []);

  const updateProduct = useCallback((product: Product) => {
    const updated: Product = {
      ...product,
      updatedAt: Date.now(),
      isSynced: false
    };
    setState(prev => ({
      ...prev,
      products: prev.products.map(p => p.id === product.id ? updated : p)
    }));
  }, []);

  const deleteProduct = useCallback((id: string) => {
    setState(prev => ({
      ...prev,
      products: prev.products.filter(p => p.id !== id)
    }));
  }, []);

  // 2. CONTACTS MUTATIONS
  const addContact = useCallback((contact: Omit<Contact, 'id' | 'updatedAt' | 'isSynced'>) => {
    const newContact: Contact = {
      ...contact,
      id: `cont-${Date.now()}`,
      updatedAt: Date.now(),
      isSynced: false
    };
    setState(prev => ({
      ...prev,
      contacts: [newContact, ...prev.contacts]
    }));
  }, []);

  const updateContact = useCallback((contact: Contact) => {
    const updated: Contact = {
      ...contact,
      updatedAt: Date.now(),
      isSynced: false
    };
    setState(prev => ({
      ...prev,
      contacts: prev.contacts.map(c => c.id === contact.id ? updated : c)
    }));
  }, []);

  const deleteContact = useCallback((id: string) => {
    setState(prev => ({
      ...prev,
      contacts: prev.contacts.filter(c => c.id !== id)
    }));
  }, []);

  // 3. SALES POS MUTATION (Complex: updates stock, appends Ledger and ledger cash/bank)
  const addSale = useCallback((saleData: {
    items: { productId: string; name: string; quantity: number; price: number; unit: 'kg' | 'pièce' }[];
    clientId: string | null;
    paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
    subtotal: number;
    vat: number;
    total: number;
  }) => {
    const saleId = `sale-${Date.now()}`;
    const timestamp = Date.now();
    const dateStr = new Date().toISOString();

    // Find client name if any
    let clientName = "Client Comptant";
    if (saleData.clientId) {
      const contact = state.contacts.find(c => c.id === saleData.clientId);
      if (contact) clientName = contact.name;
    }

    const newSale: Sale = {
      id: saleId,
      items: saleData.items,
      subtotal: saleData.subtotal,
      vat: saleData.vat,
      total: saleData.total,
      clientId: saleData.clientId,
      clientName: clientName,
      paymentMode: saleData.paymentMode,
      date: dateStr,
      updatedAt: timestamp,
      isSynced: false
    };

    // Prepare ledger entries (Double Entry System)
    // Credit 701 (Ventes de marchandises) with sales total
    // Debit 571 (Caisse) or 521 (Banque) with sales total
    const ledgerDebitAccount = saleData.paymentMode === 'Espèces' ? '571' : '521';
    const ledgerDebitAccountName = saleData.paymentMode === 'Espèces' ? 'Caisse' : 'Banque';

    const ledgerEntries: LedgerEntry[] = [
      {
        id: `led-${Date.now()}-s1`,
        date: dateStr,
        accountCode: ledgerDebitAccount,
        accountName: ledgerDebitAccountName,
        type: 'Débit',
        amount: saleData.total,
        label: `Vente POS réf ${saleId} (${clientName})`,
        paymentMode: saleData.paymentMode === 'Espèces' ? 'Espèces' : 'Banque',
        updatedAt: timestamp,
        isSynced: false
      },
      {
        id: `led-${Date.now()}-s2`,
        date: dateStr,
        accountCode: '701',
        accountName: 'Ventes de marchandises',
        type: 'Crédit',
        amount: saleData.total,
        label: `Facture vente POS réf ${saleId}`,
        paymentMode: 'Autre',
        updatedAt: timestamp,
        isSynced: false
      }
    ];

    // Update stocks (Deduct sold quantity)
    const updatedProducts = state.products.map(prod => {
      const soldItem = saleData.items.find(item => item.productId === prod.id);
      if (soldItem) {
        return {
          ...prod,
          quantity: Math.max(0, prod.quantity - soldItem.quantity),
          updatedAt: timestamp,
          isSynced: false
        };
      }
      return prod;
    });

    // Update client balance if they bought on credit/chèque and they are a real contact
    // For simplicity, we assume client purchases increase their balance (what they owe us) if they pay via Chèque or Virement, or we just keep contacts updated.
    const updatedContacts = state.contacts.map(c => {
      if (c.id === saleData.clientId && (saleData.paymentMode === 'Chèque' || saleData.paymentMode === 'Mobile Money / Virement')) {
        return {
          ...c,
          balance: c.balance + saleData.total,
          updatedAt: timestamp,
          isSynced: false
        };
      }
      return c;
    });

    setState(prev => ({
      ...prev,
      sales: [newSale, ...prev.sales],
      products: updatedProducts,
      contacts: updatedContacts,
      ledger: [...ledgerEntries, ...prev.ledger],
      updatedAt: timestamp
    }));
  }, [state.contacts, state.products]);

  // 4. PURCHASES MUTATION (Increases stock, appends Ledger)
  const addPurchase = useCallback((purchaseData: {
    supplierId: string;
    items: { productId: string; name: string; quantity: number; price: number; unit: 'kg' | 'pièce' }[];
    total: number;
    paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
  }) => {
    const purchaseId = `purch-${Date.now()}`;
    const timestamp = Date.now();
    const dateStr = new Date().toISOString();

    const supplier = state.contacts.find(c => c.id === purchaseData.supplierId);
    const supplierName = supplier ? supplier.name : "Fournisseur Inconnu";

    const newPurchase: Purchase = {
      id: purchaseId,
      supplierId: purchaseData.supplierId,
      supplierName: supplierName,
      items: purchaseData.items,
      total: purchaseData.total,
      paymentMode: purchaseData.paymentMode,
      date: dateStr,
      updatedAt: timestamp,
      isSynced: false
    };

    // Ledger (Double Entry):
    // Debit 601 (Achats de marchandises)
    // Credit 571 (Caisse) or 521 (Banque)
    const ledgerCreditAccount = purchaseData.paymentMode === 'Espèces' ? '571' : '521';
    const ledgerCreditAccountName = purchaseData.paymentMode === 'Espèces' ? 'Caisse' : 'Banque';

    const ledgerEntries: LedgerEntry[] = [
      {
        id: `led-${Date.now()}-p1`,
        date: dateStr,
        accountCode: '601',
        accountName: 'Achats de marchandises',
        type: 'Débit',
        amount: purchaseData.total,
        label: `Approvisionnement réf ${purchaseId} (${supplierName})`,
        paymentMode: 'Autre',
        updatedAt: timestamp,
        isSynced: false
      },
      {
        id: `led-${Date.now()}-p2`,
        date: dateStr,
        accountCode: ledgerCreditAccount,
        accountName: ledgerCreditAccountName,
        type: 'Crédit',
        amount: purchaseData.total,
        label: `Paiement approvisionnement réf ${purchaseId}`,
        paymentMode: purchaseData.paymentMode === 'Espèces' ? 'Espèces' : 'Banque',
        updatedAt: timestamp,
        isSynced: false
      }
    ];

    // Update stocks (Increase bought quantity, recalculate weighted average cost if changed)
    const updatedProducts = state.products.map(prod => {
      const boughtItem = purchaseData.items.find(item => item.productId === prod.id);
      if (boughtItem) {
        // Recalculate average purchase price: weighted average
        const currentTotalCost = prod.quantity * prod.avgPurchasePrice;
        const incomingCost = boughtItem.quantity * boughtItem.price;
        const totalQty = prod.quantity + boughtItem.quantity;
        const newAvgPrice = totalQty > 0 ? Math.round((currentTotalCost + incomingCost) / totalQty) : prod.avgPurchasePrice;

        return {
          ...prod,
          quantity: totalQty,
          avgPurchasePrice: newAvgPrice,
          updatedAt: timestamp,
          isSynced: false
        };
      }
      return prod;
    });

    setState(prev => ({
      ...prev,
      purchases: [newPurchase, ...prev.purchases],
      products: updatedProducts,
      ledger: [...ledgerEntries, ...prev.ledger],
      updatedAt: timestamp
    }));
  }, [state.contacts, state.products]);

  // 5. LOSSES MUTATION (Decreases stock, appends ledger expense)
  const addLoss = useCallback((lossData: {
    productId: string;
    quantity: number;
    reason: 'Périmé' | 'Altéré' | 'Invendu' | 'Erreur de découpe' | 'Autre';
    notes: string;
  }) => {
    const timestamp = Date.now();
    const dateStr = new Date().toISOString();

    const product = state.products.find(p => p.id === lossData.productId);
    if (!product) return;

    const estimatedCost = Math.round(lossData.quantity * product.avgPurchasePrice);

    const newLoss: Loss = {
      id: `loss-${Date.now()}`,
      productId: lossData.productId,
      productName: product.name,
      quantity: lossData.quantity,
      unit: product.unit,
      reason: lossData.reason,
      notes: lossData.notes,
      estimatedCost: estimatedCost,
      date: dateStr,
      updatedAt: timestamp,
      isSynced: false
    };

    // Ledger (Double Entry):
    // Debit 68 (Charges exceptionnelles - Pertes)
    // Credit 601 (Achats de marchandises - to reduce stock value)
    const ledgerEntries: LedgerEntry[] = [
      {
        id: `led-${Date.now()}-l1`,
        date: dateStr,
        accountCode: '68',
        accountName: 'Charges exceptionnelles / Pertes',
        type: 'Débit',
        amount: estimatedCost,
        label: `Perte sur ${product.name} (${lossData.reason})`,
        paymentMode: 'Autre',
        updatedAt: timestamp,
        isSynced: false
      },
      {
        id: `led-${Date.now()}-l2`,
        date: dateStr,
        accountCode: '601',
        accountName: 'Achats de marchandises',
        type: 'Crédit',
        amount: estimatedCost,
        label: `Sortie de stock pour perte: ${product.name}`,
        paymentMode: 'Autre',
        updatedAt: timestamp,
        isSynced: false
      }
    ];

    // Deduct quantity from products
    const updatedProducts = state.products.map(p => {
      if (p.id === lossData.productId) {
        return {
          ...p,
          quantity: Math.max(0, p.quantity - lossData.quantity),
          updatedAt: timestamp,
          isSynced: false
        };
      }
      return p;
    });

    setState(prev => ({
      ...prev,
      losses: [newLoss, ...prev.losses],
      products: updatedProducts,
      ledger: [...ledgerEntries, ...prev.ledger],
      updatedAt: timestamp
    }));
  }, [state.products]);

  // 6. FINANCIAL EXPENSES MUTATION (Salaries, electricity, ice, etc.)
  const addExpense = useCallback((expenseData: {
    amount: number;
    category: 'Glace et Consommables' | 'Emballage' | 'Électricité & Eau' | 'Transport & Carburant' | 'Salaires' | 'Divers';
    paymentMode: 'Caisse' | 'Banque';
    label: string;
  }) => {
    const timestamp = Date.now();
    const dateStr = new Date().toISOString();

    const ledgerAccountCredit = expenseData.paymentMode === 'Caisse' ? '571' : '521';
    const ledgerAccountCreditName = expenseData.paymentMode === 'Caisse' ? 'Caisse' : 'Banque';

    const ledgerEntries: LedgerEntry[] = [
      {
        id: `led-${Date.now()}-e1`,
        date: dateStr,
        accountCode: '65',
        accountName: 'Autres Charges / Frais',
        type: 'Débit',
        amount: expenseData.amount,
        label: `${expenseData.category}: ${expenseData.label}`,
        paymentMode: expenseData.paymentMode === 'Caisse' ? 'Espèces' : 'Banque',
        updatedAt: timestamp,
        isSynced: false
      },
      {
        id: `led-${Date.now()}-e2`,
        date: dateStr,
        accountCode: ledgerAccountCredit,
        accountName: ledgerAccountCreditName,
        type: 'Crédit',
        amount: expenseData.amount,
        label: `Règlement frais - ${expenseData.label}`,
        paymentMode: expenseData.paymentMode === 'Caisse' ? 'Espèces' : 'Banque',
        updatedAt: timestamp,
        isSynced: false
      }
    ];

    setState(prev => ({
      ...prev,
      ledger: [...ledgerEntries, ...prev.ledger],
      updatedAt: timestamp
    }));
  }, []);

  // 7. SETTINGS MUTATION
  const updateSettings = useCallback((settings: Settings) => {
    setState(prev => ({
      ...prev,
      settings: {
        ...settings,
      },
      updatedAt: Date.now()
    }));
  }, []);

  return {
    state,
    isOnline,
    isManualOffline,
    isSyncing,
    syncError,
    pendingCount,
    setOfflineMode,
    syncWithServer,
    resetToSeed,

    // Mutation Operations
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
  };
}
