import { DBState, Product, Contact, Sale, Purchase, Loss, LedgerEntry } from './types';

export const INITIAL_PRODUCTS: Product[] = [
  {
    id: "prod-1",
    name: "Bar de Ligne Entier",
    category: "Poissons",
    avgPurchasePrice: 7000,
    sellingPrice: 12000,
    quantity: 45,
    alertThreshold: 15,
    unit: "kg",
    freshness: "Frais",
    updatedAt: Date.now() - 3600000,
    isSynced: true
  },
  {
    id: "prod-2",
    name: "Saumon Atlantique (Pavé)",
    category: "Poissons",
    avgPurchasePrice: 8500,
    sellingPrice: 14500,
    quantity: 28,
    alertThreshold: 10,
    unit: "kg",
    freshness: "Frais",
    updatedAt: Date.now() - 7200000,
    isSynced: true
  },
  {
    id: "prod-3",
    name: "Daurade Royale de Mer",
    category: "Poissons",
    avgPurchasePrice: 4000,
    sellingPrice: 7500,
    quantity: 8, // Stocks Bas!
    alertThreshold: 12,
    unit: "kg",
    freshness: "Sensible",
    updatedAt: Date.now() - 10800000,
    isSynced: true
  },
  {
    id: "prod-4",
    name: "Crevettes Tigrées Géantes",
    category: "Crustacés",
    avgPurchasePrice: 8000,
    sellingPrice: 14000,
    quantity: 35,
    alertThreshold: 10,
    unit: "kg",
    freshness: "Frais",
    updatedAt: Date.now() - 1500000,
    isSynced: true
  },
  {
    id: "prod-5",
    name: "Homard Bleu Vivant",
    category: "Crustacés",
    avgPurchasePrice: 18000,
    sellingPrice: 32000,
    quantity: 5,
    alertThreshold: 4,
    unit: "kg",
    freshness: "Sensible",
    updatedAt: Date.now() - 25000000,
    isSynced: true
  },
  {
    id: "prod-6",
    name: "Huîtres Marennes d'Oléron N°3",
    category: "Coquillages",
    avgPurchasePrice: 4500,
    sellingPrice: 8500,
    quantity: 12,
    alertThreshold: 10,
    unit: "kg",
    freshness: "Sensible",
    updatedAt: Date.now() - 1800000,
    isSynced: true
  },
  {
    id: "prod-7",
    name: "Noix de Saint-Jacques Franches",
    category: "Coquillages",
    avgPurchasePrice: 13000,
    sellingPrice: 24000,
    quantity: 3, // Stocks Bas!
    alertThreshold: 8,
    unit: "kg",
    freshness: "Sensible",
    updatedAt: Date.now() - 3000000,
    isSynced: true
  },
  {
    id: "prod-8",
    name: "Sole Meunière Vidée",
    category: "Poissons",
    avgPurchasePrice: 6000,
    sellingPrice: 10500,
    quantity: 18,
    alertThreshold: 8,
    unit: "kg",
    freshness: "Frais",
    updatedAt: Date.now() - 8600000,
    isSynced: true
  },
  {
    id: "prod-9",
    name: "Soupe de Poisson de Roche Maison",
    category: "Traiteur",
    avgPurchasePrice: 1500,
    sellingPrice: 3500,
    quantity: 40,
    alertThreshold: 15,
    unit: "pièce",
    freshness: "Moyen",
    updatedAt: Date.now() - 40000000,
    isSynced: true
  },
  {
    id: "prod-10",
    name: "Salade de Poulpe à la Provençale",
    category: "Traiteur",
    avgPurchasePrice: 3500,
    sellingPrice: 6800,
    quantity: 24,
    alertThreshold: 8,
    unit: "pièce",
    freshness: "Frais",
    updatedAt: Date.now() - 12000000,
    isSynced: true
  }
];

export const INITIAL_CONTACTS: Contact[] = [
  {
    id: "cont-1",
    name: "Sénégal Pêche SA",
    type: "Fournisseur",
    phone: "+221 33 849 11 22",
    address: "Port Autonome de Dakar, Sénégal",
    email: "contact@senegalpeche.sn",
    notes: "Fournisseur principal de poissons de ligne sauvages. Livraison bi-hebdomadaire par cargo réfrigéré.",
    balance: 450000, // Nous leur devons 450,000 FCFA
    updatedAt: Date.now() - 50000000,
    isSynced: true
  },
  {
    id: "cont-2",
    name: "Marée d'Abidjan Grossiste",
    type: "Fournisseur",
    phone: "+225 07 45 12 34 56",
    address: "Nouveau Port de Pêche, Vridi, Abidjan",
    email: "commandes@maree-abidjan.ci",
    notes: "Approvisionnement rapide en crustacés locaux (crabes, langoustes, crevettes) et thon de fraîcheur supérieure.",
    balance: 0,
    updatedAt: Date.now() - 60000000,
    isSynced: true
  },
  {
    id: "cont-3",
    name: "Hôtel du Golfe Abidjan",
    type: "Client",
    phone: "+225 27 22 44 88 00",
    address: "Boulevard de la RCI, Cocody, Abidjan",
    email: "fnb@hoteldugolfe.ci",
    notes: "Client VIP. Règlement à 30 jours fin de mois. Livraisons tous les mardis et vendredis matin.",
    balance: 150000, // Ils nous doivent 150,000 FCFA
    updatedAt: Date.now() - 40000000,
    isSynced: true
  },
  {
    id: "cont-4",
    name: "Restaurant Le Phare Solaire",
    type: "Client",
    phone: "+225 05 66 77 88 99",
    address: "Zone 4, Rue du Canal, Marcory, Abidjan",
    email: "lephare-solaire@aviso.ci",
    notes: "Restaurant gastronomique. Grand consommateur de homards bleus et noix de Saint-Jacques.",
    balance: 250000, // Ils nous doivent 250,000 FCFA
    updatedAt: Date.now() - 30000000,
    isSynced: true
  },
  {
    id: "cont-5",
    name: "Mme Diallo Fatoumata",
    type: "Client",
    phone: "+225 07 11 22 33 44",
    address: "Riviera 3, Abidjan",
    email: "fdiallo@gmail.com",
    notes: "Cliente régulière, achète beaucoup de traiteur et bar pour les repas de famille du weekend.",
    balance: 0,
    updatedAt: Date.now() - 20000000,
    isSynced: true
  }
];

// Helper to construct historical dates
const getPastDateString = (daysAgo: number): string => {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString();
};

export const INITIAL_SALES: Sale[] = [
  {
    id: "sale-1",
    items: [
      { productId: "prod-1", name: "Bar de Ligne Entier", quantity: 5, price: 12000, unit: "kg" },
      { productId: "prod-4", name: "Crevettes Tigrées Géantes", quantity: 3, price: 14000, unit: "kg" }
    ],
    subtotal: 102000,
    vat: 18360,
    total: 120360,
    clientId: "cont-3",
    clientName: "Hôtel du Golfe Abidjan",
    paymentMode: "Chèque",
    date: getPastDateString(6),
    updatedAt: Date.now() - 5 * 86400000,
    isSynced: true
  },
  {
    id: "sale-2",
    items: [
      { productId: "prod-2", name: "Saumon Atlantique (Pavé)", quantity: 4, price: 14500, unit: "kg" },
      { productId: "prod-10", name: "Salade de Poulpe à la Provençale", quantity: 5, price: 6800, unit: "pièce" }
    ],
    subtotal: 92000,
    vat: 16560,
    total: 108560,
    clientId: null,
    clientName: "Client Comptant",
    paymentMode: "Espèces",
    date: getPastDateString(5),
    updatedAt: Date.now() - 4 * 86400000,
    isSynced: true
  },
  {
    id: "sale-3",
    items: [
      { productId: "prod-5", name: "Homard Bleu Vivant", quantity: 3, price: 32000, unit: "kg" },
      { productId: "prod-7", name: "Noix de Saint-Jacques Franches", quantity: 2, price: 24000, unit: "kg" }
    ],
    subtotal: 144000,
    vat: 25920,
    total: 169920,
    clientId: "cont-4",
    clientName: "Restaurant Le Phare Solaire",
    paymentMode: "Mobile Money / Virement",
    date: getPastDateString(4),
    updatedAt: Date.now() - 3 * 86400000,
    isSynced: true
  },
  {
    id: "sale-4",
    items: [
      { productId: "prod-1", name: "Bar de Ligne Entier", quantity: 12, price: 12000, unit: "kg" },
      { productId: "prod-9", name: "Soupe de Poisson de Roche Maison", quantity: 10, price: 3500, unit: "pièce" }
    ],
    subtotal: 179000,
    vat: 32220,
    total: 211220,
    clientId: "cont-3",
    clientName: "Hôtel du Golfe Abidjan",
    paymentMode: "Mobile Money / Virement",
    date: getPastDateString(3),
    updatedAt: Date.now() - 2 * 86400000,
    isSynced: true
  },
  {
    id: "sale-5",
    items: [
      { productId: "prod-6", name: "Huîtres Marennes d'Oléron N°3", quantity: 8, price: 8500, unit: "kg" },
      { productId: "prod-8", name: "Sole Meunière Vidée", quantity: 5, price: 10500, unit: "kg" }
    ],
    subtotal: 120500,
    vat: 21690,
    total: 142190,
    clientId: null,
    clientName: "Client Comptant",
    paymentMode: "Espèces",
    date: getPastDateString(2),
    updatedAt: Date.now() - 1 * 86400000,
    isSynced: true
  },
  {
    id: "sale-6",
    items: [
      { productId: "prod-2", name: "Saumon Atlantique (Pavé)", quantity: 6, price: 14500, unit: "kg" },
      { productId: "prod-4", name: "Crevettes Tigrées Géantes", quantity: 4, price: 14000, unit: "kg" }
    ],
    subtotal: 143000,
    vat: 25740,
    total: 168740,
    clientId: "cont-5",
    clientName: "Mme Diallo Fatoumata",
    paymentMode: "Espèces",
    date: getPastDateString(1),
    updatedAt: Date.now() - 12 * 3600000,
    isSynced: true
  }
];

export const INITIAL_PURCHASES: Purchase[] = [
  {
    id: "purch-1",
    supplierId: "cont-1",
    supplierName: "Sénégal Pêche SA",
    items: [
      { productId: "prod-1", name: "Bar de Ligne Entier", quantity: 20, price: 7000, unit: "kg" },
      { productId: "prod-2", name: "Saumon Atlantique (Pavé)", quantity: 15, price: 8500, unit: "kg" }
    ],
    total: 267500,
    paymentMode: "Mobile Money / Virement",
    date: getPastDateString(5),
    updatedAt: Date.now() - 4 * 86400000,
    isSynced: true
  },
  {
    id: "purch-2",
    supplierId: "cont-2",
    supplierName: "Marée d'Abidjan Grossiste",
    items: [
      { productId: "prod-4", name: "Crevettes Tigrées Géantes", quantity: 25, price: 8000, unit: "kg" },
      { productId: "prod-5", name: "Homard Bleu Vivant", quantity: 5, price: 18000, unit: "kg" }
    ],
    total: 290000,
    paymentMode: "Espèces",
    date: getPastDateString(2),
    updatedAt: Date.now() - 1 * 86400000,
    isSynced: true
  }
];

export const INITIAL_LOSSES: Loss[] = [
  {
    id: "loss-1",
    productId: "prod-3",
    productName: "Daurade Royale de Mer",
    quantity: 3,
    unit: "kg",
    reason: "Périmé",
    notes: "Oublié dans le bac secondaire, altération de la fraîcheur cutanée (perte d'éclat). Saisie pour sécurité.",
    estimatedCost: 12000,
    date: getPastDateString(4),
    updatedAt: Date.now() - 3 * 86400000,
    isSynced: true
  },
  {
    id: "loss-2",
    productId: "prod-8",
    productName: "Sole Meunière Vidée",
    quantity: 1.5,
    unit: "kg",
    reason: "Erreur de découpe",
    notes: "Sole abîmée lors de l'opération de filetage par le nouvel apprenti.",
    estimatedCost: 9000,
    date: getPastDateString(2),
    updatedAt: Date.now() - 1 * 86400000,
    isSynced: true
  }
];

// Standard double entry SYSCOHADA template
export const INITIAL_LEDGER: LedgerEntry[] = [
  // Capital investment
  { id: "led-1", date: getPastDateString(30), accountCode: "101", accountName: "Capital", type: "Crédit", amount: 10000000, label: "Apport de capital initial", paymentMode: "Autre", updatedAt: Date.now() - 30 * 86400000, isSynced: true },
  { id: "led-2", date: getPastDateString(30), accountCode: "521", accountName: "Banque", type: "Débit", amount: 8000000, label: "Versement capital initial Banque", paymentMode: "Banque", updatedAt: Date.now() - 30 * 86400000, isSynced: true },
  { id: "led-3", date: getPastDateString(30), accountCode: "571", accountName: "Caisse", type: "Débit", amount: 2000000, label: "Alimentation caisse de démarrage", paymentMode: "Espèces", updatedAt: Date.now() - 30 * 86400000, isSynced: true },

  // Cold store purchase (assets)
  { id: "led-4", date: getPastDateString(25), accountCode: "2182", accountName: "Matériel d'équipement", type: "Débit", amount: 3500000, label: "Achat 2 Congélateurs industriels vitrés", paymentMode: "Banque", updatedAt: Date.now() - 25 * 86400000, isSynced: true },
  { id: "led-5", date: getPastDateString(25), accountCode: "521", accountName: "Banque", type: "Crédit", amount: 3500000, label: "Paiement congélateurs", paymentMode: "Banque", updatedAt: Date.now() - 25 * 86400000, isSynced: true },

  // Operational Expenses (Ice, Salary, Rent, Electricity)
  { id: "led-f1", date: getPastDateString(6), accountCode: "65", accountName: "Autres Charges / Frais", type: "Débit", amount: 35000, label: "Frais de Glace écailleuse (Conservation)", paymentMode: "Espèces", updatedAt: Date.now() - 5 * 86400000, isSynced: true },
  { id: "led-f2", date: getPastDateString(6), accountCode: "571", accountName: "Caisse", type: "Crédit", amount: 35000, label: "Paiement Glace écailleuse", paymentMode: "Espèces", updatedAt: Date.now() - 5 * 86400000, isSynced: true },

  { id: "led-f3", date: getPastDateString(4), accountCode: "65", accountName: "Autres Charges / Frais", type: "Débit", amount: 25000, label: "Achat Emballages isothermes et cartons de transport", paymentMode: "Espèces", updatedAt: Date.now() - 3 * 86400000, isSynced: true },
  { id: "led-f4", date: getPastDateString(4), accountCode: "571", accountName: "Caisse", type: "Crédit", amount: 25000, label: "Paiement Carton/Emballage", paymentMode: "Espèces", updatedAt: Date.now() - 3 * 86400000, isSynced: true },

  // Purchases bookkeeping integration
  { id: "led-p1_1", date: getPastDateString(5), accountCode: "601", accountName: "Achats de marchandises", type: "Débit", amount: 267500, label: "Achat marchandise Sénégal Pêche SA", paymentMode: "Banque", updatedAt: Date.now() - 4 * 86400000, isSynced: true },
  { id: "led-p1_2", date: getPastDateString(5), accountCode: "521", accountName: "Banque", type: "Crédit", amount: 267500, label: "Paiement Achat Sénégal Pêche SA", paymentMode: "Banque", updatedAt: Date.now() - 4 * 86400000, isSynced: true },

  { id: "led-p2_1", date: getPastDateString(2), accountCode: "601", accountName: "Achats de marchandises", type: "Débit", amount: 290000, label: "Achat crustacés Marée d'Abidjan", paymentMode: "Espèces", updatedAt: Date.now() - 1 * 86400000, isSynced: true },
  { id: "led-p2_2", date: getPastDateString(2), accountCode: "571", accountName: "Caisse", type: "Crédit", amount: 290000, label: "Paiement cash Marée d'Abidjan", paymentMode: "Espèces", updatedAt: Date.now() - 1 * 86400000, isSynced: true },

  // Sales bookkeeping integration
  { id: "led-s1_1", date: getPastDateString(6), accountCode: "521", accountName: "Banque", type: "Débit", amount: 120360, label: "Vente Hotel du Golfe (Chèque)", paymentMode: "Banque", updatedAt: Date.now() - 5 * 86400000, isSynced: true },
  { id: "led-s1_2", date: getPastDateString(6), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 120360, label: "Facture Vente Hotel du Golfe", paymentMode: "Autre", updatedAt: Date.now() - 5 * 86400000, isSynced: true },

  { id: "led-s2_1", date: getPastDateString(5), accountCode: "571", accountName: "Caisse", type: "Débit", amount: 108560, label: "Ventes Poissonnerie Comptant", paymentMode: "Espèces", updatedAt: Date.now() - 4 * 86400000, isSynced: true },
  { id: "led-s2_2", date: getPastDateString(5), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 108560, label: "Facture Ventes Comptant", paymentMode: "Autre", updatedAt: Date.now() - 4 * 86400000, isSynced: true },

  { id: "led-s3_1", date: getPastDateString(4), accountCode: "521", accountName: "Banque", type: "Débit", amount: 169920, label: "Vente Le Phare Solaire (Virement)", paymentMode: "Banque", updatedAt: Date.now() - 3 * 86400000, isSynced: true },
  { id: "led-s3_2", date: getPastDateString(4), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 169920, label: "Facture Vente Le Phare Solaire", paymentMode: "Autre", updatedAt: Date.now() - 3 * 86400000, isSynced: true },

  { id: "led-s4_1", date: getPastDateString(3), accountCode: "521", accountName: "Banque", type: "Débit", amount: 211220, label: "Vente Hotel du Golfe (Virement)", paymentMode: "Banque", updatedAt: Date.now() - 2 * 86400000, isSynced: true },
  { id: "led-s4_2", date: getPastDateString(3), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 211220, label: "Facture Vente Hotel du Golfe", paymentMode: "Autre", updatedAt: Date.now() - 2 * 86400000, isSynced: true },

  { id: "led-s5_1", date: getPastDateString(2), accountCode: "571", accountName: "Caisse", type: "Débit", amount: 142190, label: "Ventes Poissonnerie Comptant", paymentMode: "Espèces", updatedAt: Date.now() - 1 * 86400000, isSynced: true },
  { id: "led-s5_2", date: getPastDateString(2), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 142190, label: "Facture Ventes Comptant", paymentMode: "Autre", updatedAt: Date.now() - 1 * 86400000, isSynced: true },

  { id: "led-s6_1", date: getPastDateString(1), accountCode: "571", accountName: "Caisse", type: "Débit", amount: 168740, label: "Vente Mme Diallo Fatoumata (Momo)", paymentMode: "Espèces", updatedAt: Date.now() - 12 * 3600000, isSynced: true },
  { id: "led-s6_2", date: getPastDateString(1), accountCode: "701", accountName: "Ventes de marchandises", type: "Crédit", amount: 168740, label: "Facture Vente Mme Diallo", paymentMode: "Autre", updatedAt: Date.now() - 12 * 3600000, isSynced: true },

  // Losses accounting
  { id: "led-l1_1", date: getPastDateString(4), accountCode: "68", accountName: "Charges exceptionnelles (Pertes)", type: "Débit", amount: 12000, label: "Déclaration de perte: Daurade Royale (Périmé)", paymentMode: "Autre", updatedAt: Date.now() - 3 * 86400000, isSynced: true },
  { id: "led-l1_2", date: getPastDateString(4), accountCode: "601", accountName: "Achats de marchandises", type: "Crédit", amount: 12000, label: "Sortie stock pour pertes", paymentMode: "Autre", updatedAt: Date.now() - 3 * 86400000, isSynced: true },

  { id: "led-l2_1", date: getPastDateString(2), accountCode: "68", accountName: "Charges exceptionnelles (Pertes)", type: "Débit", amount: 9000, label: "Déclaration de perte: Sole Meunière (Découpe)", paymentMode: "Autre", updatedAt: Date.now() - 1 * 86400000, isSynced: true },
  { id: "led-l2_2", date: getPastDateString(2), accountCode: "601", accountName: "Achats de marchandises", type: "Crédit", amount: 9000, label: "Sortie stock pour pertes", paymentMode: "Autre", updatedAt: Date.now() - 1 * 86400000, isSynced: true }
];

export const DEFAULT_SETTINGS = {
  shopName: "Poissonnerie Pro",
  address: "12 Port de Pêche, Abidjan, Côte d'Ivoire",
  phone: "+225 07 45 12 34 56",
  taxId: "CC-9876543-A",
  currency: "FCFA",
  vatRate: 18,
  lastSync: Date.now()
};

export const INITIAL_STATE: DBState = {
  products: INITIAL_PRODUCTS,
  sales: INITIAL_SALES,
  purchases: INITIAL_PURCHASES,
  losses: INITIAL_LOSSES,
  contacts: INITIAL_CONTACTS,
  ledger: INITIAL_LEDGER,
  settings: DEFAULT_SETTINGS
};
