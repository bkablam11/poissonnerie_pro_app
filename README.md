# flutter_poissonnerie_pro

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Bien que l'application soit 100% fonctionnelle avec des jeux de données d'exemple, voici les étapes recommandées pour la finaliser en produit commercialisable :
Persistance locale robuste (Base de données physique) :
Actuellement : Les données sont stockées en mémoire vive (RAM) via Riverpod. Si vous fermez et rouvrez l'application, les données reviennent à l'état initial.
À faire : Connecter un moteur de persistance locale comme Sqflite, Isar ou Hive pour sauvegarder les ventes et les écritures comptables de manière permanente sur le téléphone de l'utilisateur.

Véritable synchronisation API Cloud :
Actuellement : La synchronisation cloud et le mode hors-ligne sont entièrement simulés de manière réaliste avec un minuteur (Stream).
À faire : Brancher les requêtes sur une vraie API ou un Backend de synchronisation (par exemple Supabase ou Firebase) pour centraliser les données de plusieurs poissonneries.


Mise en page des reçus physiques :
Actuellement : L'imprimante Bluetooth est connectée et scannée avec succès.
À faire : Finaliser le template d'impression (le ticket de caisse en octets ESC/POS) pour sortir le ticket physique sur l'imprimante thermique.
Gestion des rôles (Authentification) :
À faire : Ajouter un écran de connexion simple (PIN de caisse) pour séparer les actions autorisées par le "Caissier" (Ventes, Pertes) de celles du "Gérant" (Comptabilité, Paramètres).

[
  {
    "id": "POI-001",
    "name": "PELON (lokor-lokor)",
    "category": "poissonCongele",
    "stockKg": 8.0,
    "purchasePrice": 16500.0,
    "sellingPrice": 18500.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-002",
    "name": "BELLE DAME",
    "category": "poissonCongele",
    "stockKg": 3.0,
    "purchasePrice": 9000.0,
    "sellingPrice": 11500.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-003",
    "name": "MACHOIRON",
    "category": "poissonCongele",
    "stockKg": 11.0,
    "purchasePrice": 8500.0,
    "sellingPrice": 11000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-004",
    "name": "MULLET",
    "category": "poissonCongele",
    "stockKg": 0.0,
    "purchasePrice": 17000.0,
    "sellingPrice": 17500.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-005",
    "name": "LAME",
    "category": "poissonCongele",
    "stockKg": 2.0,
    "purchasePrice": 19000.0,
    "sellingPrice": 20000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-006",
    "name": "APPOLLO 300/500 (MOYEN)",
    "category": "poissonCongele",
    "stockKg": 5.0,
    "purchasePrice": 27500.0,
    "sellingPrice": 29000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-007",
    "name": "CARPE 300/500 (MOYEN)",
    "category": "poissonCongele",
    "stockKg": 13.0,
    "purchasePrice": 10000.0,
    "sellingPrice": 12000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-008",
    "name": "CARPE 500/800 (GRAND)",
    "category": "poissonCongele",
    "stockKg": 6.0,
    "purchasePrice": 11500.0,
    "sellingPrice": 13000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-009",
    "name": "CARPE ROUGE M (GRAND)",
    "category": "poissonCongele",
    "stockKg": 0.0,
    "purchasePrice": 21000.0,
    "sellingPrice": 22500.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-010",
    "name": "CARPE ROUGE P (MOYEN)",
    "category": "poissonCongele",
    "stockKg": 1.0,
    "purchasePrice": 21000.0,
    "sellingPrice": 22000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-011",
    "name": "CARPE ROUGE 2P (PETIT)",
    "category": "poissonCongele",
    "stockKg": 4.0,
    "purchasePrice": 14500.0,
    "sellingPrice": 16000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-012",
    "name": "MAQUEREAU 500/1500 (GRAND)",
    "category": "poissonCongele",
    "stockKg": 4.0,
    "purchasePrice": 25000.0,
    "sellingPrice": 27000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-013",
    "name": "MAQUEREAU 250/400 (MOYEN)",
    "category": "poissonCongele",
    "stockKg": 59.0,
    "purchasePrice": 25500.0,
    "sellingPrice": 27000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-014",
    "name": "APPOLLO 300/600 (MOYEN)",
    "category": "poissonCongele",
    "stockKg": 28.0,
    "purchasePrice": 25500.0,
    "sellingPrice": 29000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-015",
    "name": "APPOLLO 200/400 (PETIT)",
    "category": "poissonCongele",
    "stockKg": 6.0,
    "purchasePrice": 22500.0,
    "sellingPrice": 26000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-016",
    "name": "APPOLLO 500/900 (GRAND)",
    "category": "poissonCongele",
    "stockKg": 25.0,
    "purchasePrice": 27500.0,
    "sellingPrice": 29000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-017",
    "name": "MANGNE SARDINE",
    "category": "poissonCongele",
    "stockKg": 21.0,
    "purchasePrice": 15000.0,
    "sellingPrice": 17000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-018",
    "name": "MANGNE SIMPLE MOYEN (SARDEB...)",
    "category": "poissonCongele",
    "stockKg": 0.0,
    "purchasePrice": 17000.0,
    "sellingPrice": 19000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-019",
    "name": "TOMBOLA (BLUEWHIT_20)",
    "category": "poissonCongele",
    "stockKg": 29.0,
    "purchasePrice": 14000.0,
    "sellingPrice": 16000.0,
    "minThresholdKg": 5.0
  },
  {
    "id": "POI-020",
    "name": "MULLET_29_05_26",
    "category": "poissonCongele",
    "stockKg": 31.0,
    "purchasePrice": 18000.0,
    "sellingPrice": 19500.0,
    "minThresholdKg": 10.0
  },
  {
    "id": "POI-021",
    "name": "CARPE 500/800_29_05_26",
    "category": "poissonCongele",
    "stockKg": 20.0,
    "purchasePrice": 11000.0,
    "sellingPrice": 13000.0,
    "minThresholdKg": 10.0
  },
  {
    "id": "POI-022",
    "name": "CARPE ROUGE P_29_05_26",
    "category": "poissonCongele",
    "stockKg": 0.0,
    "purchasePrice": 21000.0,
    "sellingPrice": 22500.0,
    "minThresholdKg": 10.0
  }
]