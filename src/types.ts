export interface Product {
  id: string;
  name: string;
  category: 'Poissons' | 'Crustacés' | 'Coquillages' | 'Traiteur';
  avgPurchasePrice: number;
  sellingPrice: number;
  quantity: number; // in kg or piece
  alertThreshold: number;
  unit: 'kg' | 'pièce';
  freshness: 'Frais' | 'Moyen' | 'Périssable' | 'Sensible'; // Freshness / perishability indicator
  updatedAt: number;
  isSynced: boolean;
}

export interface SaleItem {
  productId: string;
  name: string;
  quantity: number;
  price: number;
  unit: 'kg' | 'pièce';
}

export interface Sale {
  id: string;
  items: SaleItem[];
  subtotal: number;
  vat: number;
  total: number;
  clientId: string | null; // references Contact.id
  clientName: string | null;
  paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
  date: string; // ISO String
  updatedAt: number;
  isSynced: boolean;
}

export interface PurchaseItem {
  productId: string;
  name: string;
  quantity: number;
  price: number; // Unit purchase price
  unit: 'kg' | 'pièce';
}

export interface Purchase {
  id: string;
  supplierId: string; // references Contact.id
  supplierName: string;
  items: PurchaseItem[];
  total: number;
  paymentMode: 'Espèces' | 'Chèque' | 'Mobile Money / Virement';
  date: string; // ISO String
  updatedAt: number;
  isSynced: boolean;
}

export interface Loss {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unit: 'kg' | 'pièce';
  reason: 'Périmé' | 'Altéré' | 'Invendu' | 'Erreur de découpe' | 'Autre';
  notes: string;
  estimatedCost: number; // quantity * avgPurchasePrice
  date: string; // ISO String
  updatedAt: number;
  isSynced: boolean;
}

export interface Contact {
  id: string;
  name: string;
  type: 'Client' | 'Fournisseur' | 'Deux';
  phone: string;
  address: string;
  email: string;
  notes: string;
  balance: number; // For clients, positive means they owe us. For suppliers, positive means we owe them.
  updatedAt: number;
  isSynced: boolean;
}

export interface LedgerEntry {
  id: string;
  date: string; // ISO String
  accountCode: string; // SYSCOHADA Code (e.g., 571, 521, 601, 701, 2182, 101, 65, 68)
  accountName: string;
  type: 'Débit' | 'Crédit'; // Debit increases Assets/Expenses, Credit increases Liabilities/Equity/Revenue
  amount: number;
  label: string;
  paymentMode: 'Espèces' | 'Banque' | 'Autre';
  updatedAt: number;
  isSynced: boolean;
}

export interface ChartDataPoint {
  day: string;
  ventes: number;
  depenses: number;
}

export interface Settings {
  shopName: string;
  address: string;
  phone: string;
  taxId: string;
  currency: string;
  vatRate: number;
  lastSync: number | null;
}

export interface DBState {
  products: Product[];
  sales: Sale[];
  purchases: Purchase[];
  losses: Loss[];
  contacts: Contact[];
  ledger: LedgerEntry[];
  settings: Settings;
}
