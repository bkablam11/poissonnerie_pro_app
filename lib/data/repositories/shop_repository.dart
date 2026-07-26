import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/poissonnerie_models.dart';
import '../services/cloud_sync_service.dart';

class ShopState {
  final List<Product> products;
  final List<Sale> sales;
  final List<Arrival> purchases;
  final List<Loss> losses;
  final List<Contact> contacts;
  final List<LedgerEntry> ledger;
  final Map<String, String> settings;
  final bool isOnline;
  final bool isSyncing;
  final String? syncError;

  ShopState({
    required this.products,
    required this.sales,
    required this.purchases,
    required this.losses,
    required this.contacts,
    required this.ledger,
    required this.settings,
    this.isOnline = true,
    this.isSyncing = false,
    this.syncError,
  });

  ShopState copyWith({
    List<Product>? products,
    List<Sale>? sales,
    List<Arrival>? purchases,
    List<Loss>? losses,
    List<Contact>? contacts,
    List<LedgerEntry>? ledger,
    Map<String, String>? settings,
    bool? isOnline,
    bool? isSyncing,
    String? syncError,
  }) {
    return ShopState(
      products: products ?? this.products,
      sales: sales ?? this.sales,
      purchases: purchases ?? this.purchases,
      losses: losses ?? this.losses,
      contacts: contacts ?? this.contacts,
      ledger: ledger ?? this.ledger,
      settings: settings ?? this.settings,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError ?? this.syncError,
    );
  }

  int get pendingCount {
    int count = 0;
    for (var p in sales) {
      if (!p.isSynced) count++;
    }
    return count;
  }
}

class ShopRepository {
  late ShopState _state;
  final _stateController = StreamController<ShopState>.broadcast();

  // Service de synchronisation Cloud (Supabase, Firebase ou Mock par défaut)
  final CloudSyncService _cloudSyncService = MockCloudSyncService();

  Stream<ShopState> get stateStream => _stateController.stream;
  ShopState get currentState => _state;

  ShopRepository() {
    _loadSeedData();
    _loadState(); // Try loading persisted state from local physical DB
  }

  void dispose() {
    _stateController.close();
  }

  // Load from local storage (SharedPreferences database)
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString('shop_products');
      final salesJson = prefs.getString('shop_sales');
      final purchasesJson = prefs.getString('shop_purchases');
      final lossesJson = prefs.getString('shop_losses');
      final contactsJson = prefs.getString('shop_contacts');
      final ledgerJson = prefs.getString('shop_ledger');
      final settingsJson = prefs.getString('shop_settings');

      if (productsJson != null || salesJson != null || contactsJson != null) {
        List<Product> products = _state.products;
        if (productsJson != null) {
          final List decoded = jsonDecode(productsJson);
          products = decoded.map((x) => Product.fromMap(x)).toList();
        }

        List<Sale> sales = _state.sales;
        if (salesJson != null) {
          final List decoded = jsonDecode(salesJson);
          sales = decoded.map((x) => Sale.fromMap(x)).toList();
        }

        List<Arrival> purchases = _state.purchases;
        if (purchasesJson != null) {
          final List decoded = jsonDecode(purchasesJson);
          purchases = decoded.map((x) => Arrival.fromMap(x)).toList();
        }

        List<Loss> losses = _state.losses;
        if (lossesJson != null) {
          final List decoded = jsonDecode(lossesJson);
          losses = decoded.map((x) => Loss.fromMap(x)).toList();
        }

        List<Contact> contacts = _state.contacts;
        if (contactsJson != null) {
          final List decoded = jsonDecode(contactsJson);
          contacts = decoded.map((x) => Contact.fromMap(x)).toList();
        }

        List<LedgerEntry> ledger = _state.ledger;
        if (ledgerJson != null) {
          final List decoded = jsonDecode(ledgerJson);
          ledger = decoded.map((x) => LedgerEntry.fromMap(x)).toList();
        }

        Map<String, String> settings = Map.from(_state.settings);
        if (settingsJson != null) {
          final Map<String, dynamic> decoded = jsonDecode(settingsJson);
          settings = decoded.map((k, v) => MapEntry(k, v.toString()));
        }

        // Migrate old default demo PINs (2222 and 0000) to user's custom PINs (6465 and 1007)
        if (settings['managerPin'] == '2222' ||
            settings['managerPin'] == null) {
          settings['managerPin'] = '6465';
        }
        if (settings['adminPin'] == '0000' || settings['adminPin'] == null) {
          settings['adminPin'] = '1007';
        }
        if (settings['cashierPin'] == null) {
          settings['cashierPin'] = '1111';
        }

        _state = ShopState(
          products: products,
          sales: sales,
          purchases: purchases,
          losses: losses,
          contacts: contacts,
          ledger: ledger,
          settings: settings,
        );
        _stateController.add(_state);
      }
    } catch (e) {
      print("Error loading persistent state: $e");
    }
  }

  // Save state to local database
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_products',
          jsonEncode(_state.products.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_sales',
          jsonEncode(_state.sales.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_purchases',
          jsonEncode(_state.purchases.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_losses',
          jsonEncode(_state.losses.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_contacts',
          jsonEncode(_state.contacts.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_ledger',
          jsonEncode(_state.ledger.map((e) => e.toMap()).toList()));
      await prefs.setString('shop_settings', jsonEncode(_state.settings));
    } catch (e) {
      print("Error saving persistent state: $e");
    }
  }

  void toggleOnlineStatus() {
    _state = _state.copyWith(isOnline: !_state.isOnline);
    _stateController.add(_state);
    _saveState();
    if (_state.isOnline) {
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (!_state.isOnline) {
      _state = _state.copyWith(
          syncError: "Impossible de synchroniser en mode hors-ligne.");
      _stateController.add(_state);
      return;
    }

    _state = _state.copyWith(isSyncing: true, syncError: null);
    _stateController.add(_state);

    try {
      // 1. Récupérer les ventes non synchronisées
      final unsyncedSales = _state.sales.where((s) => !s.isSynced).toList();

      // Choisir le service dynamique de synchro
      String url = _state.settings['supabaseUrl'] ?? '';
      String anonKey = _state.settings['supabaseAnonKey'] ?? '';

      // Fallback sur le fichier .env si les paramètres de l'application sont vides
      if (url.isEmpty || anonKey.isEmpty) {
        url = dotenv.env['SUPABASE_URL'] ?? '';
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        // Éviter d'utiliser la valeur de placeholder par défaut
        if (url == 'https://VOTRE_PROJET_ID.supabase.co' ||
            anonKey == 'VOTRE_CLE_API_ANONYME') {
          url = '';
          anonKey = '';
        }
      }

      final CloudSyncService activeSyncService =
          (url.isNotEmpty && anonKey.isNotEmpty)
              ? SupabaseSyncService(url: url, anonKey: anonKey)
              : _cloudSyncService;

      // 2. Synchroniser de manière séquentielle et ordonnée pour respecter les clés étrangères
      // On synchronise d'abord les référentiels (Produits et Contacts) qui servent de clés étrangères
      final productsSuccess =
          await activeSyncService.pushProducts(_state.products);
      final contactsSuccess =
          await activeSyncService.pushContacts(_state.contacts);

      // On synchronise ensuite les flux transactionnels (Ventes, Achats, Pertes, Grand Livre)
      bool salesSuccess = true;
      if (unsyncedSales.isNotEmpty) {
        salesSuccess = await activeSyncService.pushSales(unsyncedSales);
      }
      final purchasesSuccess =
          await activeSyncService.pushPurchases(_state.purchases);
      final lossesSuccess = await activeSyncService.pushLosses(_state.losses);
      final ledgerSuccess = await activeSyncService.pushLedger(_state.ledger);

      final allSuccess = productsSuccess &&
          contactsSuccess &&
          salesSuccess &&
          purchasesSuccess &&
          lossesSuccess &&
          ledgerSuccess;

      if (allSuccess) {
        // Marquer toutes les ventes locales comme synchronisées
        final updatedSales =
            _state.sales.map((s) => s.copyWith(isSynced: true)).toList();

        // Optionnel : Vous pouvez aussi rafraîchir la liste locale des produits et contacts
        // avec les données les plus récentes consolidées du cloud
        final latestProducts = await activeSyncService.fetchLatestProducts();
        final latestContacts = await activeSyncService.fetchLatestContacts();

        _state = _state.copyWith(
          isSyncing: false,
          sales: updatedSales,
          products:
              latestProducts.isNotEmpty ? latestProducts : _state.products,
          contacts:
              latestContacts.isNotEmpty ? latestContacts : _state.contacts,
          syncError: null,
        );
      } else {
        _state = _state.copyWith(
          isSyncing: false,
          syncError: "Échec partiel de la synchronisation avec le cloud.",
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        isSyncing: false,
        syncError: "Erreur de connexion cloud : ${e.toString()}",
      );
    }

    _stateController.add(_state);
    _saveState();
  }

  void addProduct(Product product) {
    final updatedProducts = List<Product>.from(_state.products)
      ..insert(0, product);
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
    _saveState();
  }

  void updateProduct(Product product) {
    final updatedProducts =
        _state.products.map((p) => p.id == product.id ? product : p).toList();
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
    _saveState();
  }

  void deleteProduct(String id) {
    final updatedProducts = _state.products.where((p) => p.id != id).toList();
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
    _saveState();
  }

  void importProducts(List<Product> newProducts, {bool overwrite = false}) {
    List<Product> updatedList;
    if (overwrite) {
      updatedList = newProducts;
    } else {
      updatedList = List<Product>.from(_state.products);
      for (final p in newProducts) {
        final index = updatedList.indexWhere((existing) =>
            existing.id == p.id ||
            existing.name.trim().toLowerCase() == p.name.trim().toLowerCase());
        if (index >= 0) {
          updatedList[index] = p; // Update existing
        } else {
          updatedList.insert(0, p); // Append new
        }
      }
    }
    _state = _state.copyWith(products: updatedList);
    _stateController.add(_state);
    _saveState();
  }

  void addContact(Contact contact) {
    final updatedContacts = List<Contact>.from(_state.contacts)
      ..insert(0, contact);
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
    _saveState();
  }

  void updateContact(Contact contact) {
    final updatedContacts =
        _state.contacts.map((c) => c.id == contact.id ? contact : c).toList();
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
    _saveState();
  }

  void deleteContact(String id) {
    final updatedContacts = _state.contacts.where((c) => c.id != id).toList();
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
    _saveState();
  }

  void importContacts(List<Contact> newContacts, {bool overwrite = false}) {
    List<Contact> updatedList;
    if (overwrite) {
      updatedList = newContacts;
    } else {
      updatedList = List<Contact>.from(_state.contacts);
      for (final c in newContacts) {
        final index = updatedList.indexWhere((existing) =>
            existing.id == c.id ||
            existing.name.trim().toLowerCase() == c.name.trim().toLowerCase());
        if (index >= 0) {
          updatedList[index] = c; // Update existing
        } else {
          updatedList.insert(0, c); // Append new
        }
      }
    }
    _state = _state.copyWith(contacts: updatedList);
    _stateController.add(_state);
    _saveState();
  }

  void addSale({
    required List<SaleItem> items,
    required String? clientId,
    required PaymentMode paymentMode,
    required double total,
  }) {
    final saleId = 'sale-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    String clientName = "Client Comptant";
    if (clientId != null) {
      final contact = _state.contacts.firstWhere((c) => c.id == clientId);
      clientName = contact.name;
    }

    final newSale = Sale(
      id: saleId,
      customerName: clientName,
      items: items,
      totalAmount: total,
      paymentMode: paymentMode,
      date: now,
      isSynced: false,
    );

    // Double-entry bookkeeping:
    // Debit 571 (Caisse) or 521 (Banque) with total
    // Credit 701 (Vente de marchandises) with total
    final debitAccount = paymentMode == PaymentMode.cash ? '571' : '521';
    final debitAccountName =
        paymentMode == PaymentMode.cash ? 'Caisse' : 'Banque';

    final ledgerDebit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-s1',
      date: now,
      accountCode: debitAccount,
      accountName: debitAccountName,
      type: 'Débit',
      amount: total,
      label: 'Vente POS réf $saleId ($clientName)',
      paymentMode: paymentMode == PaymentMode.cash ? 'Espèces' : 'Banque',
    );

    final ledgerCredit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-s2',
      date: now,
      accountCode: '701',
      accountName: 'Ventes de marchandises',
      type: 'Crédit',
      amount: total,
      label: 'Facture vente POS réf $saleId',
      paymentMode: 'Autre',
    );

    // Update stocks (Deduct quantities)
    final updatedProducts = _state.products.map((prod) {
      final soldItem = items.where((item) => item.productId == prod.id);
      if (soldItem.isNotEmpty) {
        final finalStock = prod.stockKg - soldItem.first.quantityKg;
        return prod.copyWith(stockKg: finalStock < 0 ? 0.0 : finalStock);
      }
      return prod;
    }).toList();

    // Update Client balance if needed
    final updatedContacts = _state.contacts.map((c) {
      if (c.id == clientId && paymentMode == PaymentMode.bank) {
        return c.copyWith(balance: c.balance + total);
      }
      return c;
    }).toList();

    _state = _state.copyWith(
      sales: [newSale, ..._state.sales],
      products: updatedProducts,
      contacts: updatedContacts,
      ledger: [ledgerDebit, ledgerCredit, ..._state.ledger],
    );
    _stateController.add(_state);
    _saveState();

    if (_state.isOnline) {
      triggerSync();
    }
  }

  void addArrival({
    required String supplierId,
    required String fishName,
    required double quantityKg,
    required double purchaseCost,
    required double suggestedSellingPrice,
  }) {
    final now = DateTime.now();
    final arrivalId = 'purch-${now.millisecondsSinceEpoch}';

    final supplier = _state.contacts.firstWhere((c) => c.id == supplierId);

    final newArrival = Arrival(
      id: arrivalId,
      supplierName: supplier.name,
      fishName: fishName,
      quantityKg: quantityKg,
      unitPurchaseCost: purchaseCost,
      suggestedSellingPrice: suggestedSellingPrice,
      date: now,
    );

    // Ledger entries (Double entry):
    // Debit 601 (Achats de marchandises)
    // Credit 571 (Caisse) or 521 (Banque)
    final ledgerDebit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-p1',
      date: now,
      accountCode: '601',
      accountName: 'Achats de marchandises',
      type: 'Débit',
      amount: quantityKg * purchaseCost,
      label: 'Approvisionnement réf $arrivalId (${supplier.name})',
      paymentMode: 'Autre',
    );

    final ledgerCredit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-p2',
      date: now,
      accountCode: '571', // Caisse by default for raw fish buying in ports
      accountName: 'Caisse',
      type: 'Crédit',
      amount: quantityKg * purchaseCost,
      label: 'Paiement approvisionnement réf $arrivalId',
      paymentMode: 'Espèces',
    );

    // Update stock or add new product if not exists
    List<Product> updatedProducts = List<Product>.from(_state.products);
    final matchIdx = updatedProducts
        .indexWhere((p) => p.name.toLowerCase() == fishName.toLowerCase());

    if (matchIdx != -1) {
      final matched = updatedProducts[matchIdx];
      final currentTotalVal = matched.stockKg * matched.purchasePrice;
      final newTotalVal = quantityKg * purchaseCost;
      final finalQty = matched.stockKg + quantityKg;
      final newWeightedAvg = finalQty > 0
          ? ((currentTotalVal + newTotalVal) / finalQty)
          : purchaseCost;

      updatedProducts[matchIdx] = matched.copyWith(
        stockKg: finalQty,
        purchasePrice: newWeightedAvg,
        sellingPrice: suggestedSellingPrice,
      );
    } else {
      updatedProducts.insert(
          0,
          Product(
            id: 'prod-${now.millisecondsSinceEpoch}',
            name: fishName,
            category: ProductCategory.poissonCongele,
            stockKg: quantityKg,
            purchasePrice: purchaseCost,
            sellingPrice: suggestedSellingPrice,
            minThresholdKg: 5.0,
          ));
    }

    _state = _state.copyWith(
      purchases: [newArrival, ..._state.purchases],
      products: updatedProducts,
      ledger: [ledgerDebit, ledgerCredit, ..._state.ledger],
    );
    _stateController.add(_state);
    _saveState();
  }

  void addLoss({
    required String productId,
    required double quantityKg,
    required LossReason reason,
  }) {
    final now = DateTime.now();
    final product = _state.products.firstWhere((p) => p.id == productId);
    final estimatedCost = quantityKg * product.purchasePrice;

    final newLoss = Loss(
      id: 'loss-${now.millisecondsSinceEpoch}',
      productId: productId,
      productName: product.name,
      quantityKg: quantityKg,
      unitCost: product.purchasePrice,
      reason: reason,
      date: now,
    );

    // Double entry:
    // Debit 68 (Charges exceptionnelles - Pertes)
    // Credit 601 (Achats de marchandises)
    final ledgerDebit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-l1',
      date: now,
      accountCode: '68',
      accountName: 'Charges exceptionnelles / Pertes',
      type: 'Débit',
      amount: estimatedCost,
      label: 'Perte sur ${product.name} (${reason.label})',
      paymentMode: 'Autre',
    );

    final ledgerCredit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-l2',
      date: now,
      accountCode: '601',
      accountName: 'Achats de marchandises',
      type: 'Crédit',
      amount: estimatedCost,
      label: 'Sortie de stock pour perte: ${product.name}',
      paymentMode: 'Autre',
    );

    final updatedProducts = _state.products.map((p) {
      if (p.id == productId) {
        final finalStock = p.stockKg - quantityKg;
        return p.copyWith(stockKg: finalStock < 0 ? 0.0 : finalStock);
      }
      return p;
    }).toList();

    _state = _state.copyWith(
      losses: [newLoss, ..._state.losses],
      products: updatedProducts,
      ledger: [ledgerDebit, ledgerCredit, ..._state.ledger],
    );
    _stateController.add(_state);
    _saveState();
  }

  void addExpense({
    required String label,
    required double amount,
    required PaymentMode paymentMode,
    required String category,
  }) {
    final now = DateTime.now();

    // Ledger entry (Double entry):
    // Debit 65 (Autres charges / Frais de fonctionnement)
    // Credit 571 (Caisse) or 521 (Banque)
    final creditAccount = paymentMode == PaymentMode.cash ? '571' : '521';
    final creditAccountName =
        paymentMode == PaymentMode.cash ? 'Caisse' : 'Banque';

    final ledgerDebit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-e1',
      date: now,
      accountCode: '65',
      accountName: 'Autres Charges / Frais',
      type: 'Débit',
      amount: amount,
      label: '$category: $label',
      paymentMode: paymentMode == PaymentMode.cash ? 'Espèces' : 'Banque',
    );

    final ledgerCredit = LedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}-e2',
      date: now,
      accountCode: creditAccount,
      accountName: creditAccountName,
      type: 'Crédit',
      amount: amount,
      label: 'Règlement frais - $label',
      paymentMode: paymentMode == PaymentMode.cash ? 'Espèces' : 'Banque',
    );

    _state = _state.copyWith(
      ledger: [ledgerDebit, ledgerCredit, ..._state.ledger],
    );
    _stateController.add(_state);
    _saveState();
  }

  void updateSettings(Map<String, String> settings) {
    _state = _state.copyWith(settings: settings);
    _stateController.add(_state);
    _saveState();
  }

  void resetToSeed() {
    _loadSeedData();
    _saveState();
  }

  void _loadSeedData() {
    final now = DateTime.now();

    final seedProducts = [
      Product(
          id: 'POI-001',
          name: 'PELON (lokor-lokor)',
          category: ProductCategory.poissonCongele,
          stockKg: 9.0,
          purchasePrice: 16500,
          sellingPrice: 18500,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-002',
          name: 'BELLE DAME',
          category: ProductCategory.poissonCongele,
          stockKg: 4.0,
          purchasePrice: 9000,
          sellingPrice: 11500,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-003',
          name: 'MACHOIRON',
          category: ProductCategory.poissonCongele,
          stockKg: 12.0,
          purchasePrice: 8500,
          sellingPrice: 11000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-004',
          name: 'MULLET',
          category: ProductCategory.poissonCongele,
          stockKg: 0.0,
          purchasePrice: 17000,
          sellingPrice: 17500,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-005',
          name: 'LAME',
          category: ProductCategory.poissonCongele,
          stockKg: 2.0,
          purchasePrice: 19000,
          sellingPrice: 20000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-006',
          name: 'APPOLLO 300/500 (MOYEN)',
          category: ProductCategory.poissonCongele,
          stockKg: 5.0,
          purchasePrice: 27500,
          sellingPrice: 29000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-007',
          name: 'CARPE 300/500 (MOYEN)',
          category: ProductCategory.poissonCongele,
          stockKg: 13.0,
          purchasePrice: 10000,
          sellingPrice: 12000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-008',
          name: 'CARPE 500/800 (GRAND)',
          category: ProductCategory.poissonCongele,
          stockKg: 6.0,
          purchasePrice: 11500,
          sellingPrice: 13000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-009',
          name: 'CARPE ROUGE M (GRAND)',
          category: ProductCategory.poissonCongele,
          stockKg: 0.0,
          purchasePrice: 21000,
          sellingPrice: 22500,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-010',
          name: 'CARPE ROUGE P (MOYEN)',
          category: ProductCategory.poissonCongele,
          stockKg: 1.0,
          purchasePrice: 21000,
          sellingPrice: 22000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-011',
          name: 'CARPE ROUGE 2P (PETIT)',
          category: ProductCategory.poissonCongele,
          stockKg: 4.0,
          purchasePrice: 14500,
          sellingPrice: 16000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-012',
          name: 'MAQUEREAU 500/1500 (GRAND)',
          category: ProductCategory.poissonCongele,
          stockKg: 4.0,
          purchasePrice: 25000,
          sellingPrice: 27000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-013',
          name: 'MAQUEREAU 250/400 (MOYEN)',
          category: ProductCategory.poissonCongele,
          stockKg: 59.0,
          purchasePrice: 25500,
          sellingPrice: 27000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-014',
          name: 'APPOLLO 300/600 (MOYEN)',
          category: ProductCategory.poissonCongele,
          stockKg: 28.0,
          purchasePrice: 25500,
          sellingPrice: 29000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-015',
          name: 'APPOLLO 200/400 (PETIT)',
          category: ProductCategory.poissonCongele,
          stockKg: 6.0,
          purchasePrice: 22500,
          sellingPrice: 26000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-016',
          name: 'APPOLLO 500/900 (GRAND)',
          category: ProductCategory.poissonCongele,
          stockKg: 25.0,
          purchasePrice: 27500,
          sellingPrice: 29000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-017',
          name: 'MANGNE SARDINE',
          category: ProductCategory.poissonCongele,
          stockKg: 21.0,
          purchasePrice: 15000,
          sellingPrice: 17000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-018',
          name: 'MANGNE SIMPLE MOYEN (SARDEB...)',
          category: ProductCategory.poissonCongele,
          stockKg: 0.0,
          purchasePrice: 17000,
          sellingPrice: 19000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-019',
          name: 'TOMBOLA (BLUEWHIT_20)',
          category: ProductCategory.poissonCongele,
          stockKg: 29.0,
          purchasePrice: 14000,
          sellingPrice: 16000,
          minThresholdKg: 5.0),
      Product(
          id: 'POI-020',
          name: 'MULLET_29_05_26',
          category: ProductCategory.poissonCongele,
          stockKg: 31.0,
          purchasePrice: 18000,
          sellingPrice: 19500,
          minThresholdKg: 10.0),
      Product(
          id: 'POI-021',
          name: 'CARPE 500/800_29_05_26',
          category: ProductCategory.poissonCongele,
          stockKg: 20.0,
          purchasePrice: 11000,
          sellingPrice: 13000,
          minThresholdKg: 10.0),
      Product(
          id: 'POI-022',
          name: 'CARPE ROUGE P_29_05_26',
          category: ProductCategory.poissonCongele,
          stockKg: 0.0,
          purchasePrice: 21000,
          sellingPrice: 22500,
          minThresholdKg: 10.0),
    ];

    final seedContacts = [
      Contact(
          id: 'FOU-001',
          name: 'SONAL',
          phone: '07 07 20 33 22 (M. KOUAKOU)',
          type: ContactType.fournisseur,
          balance: 0.0),
      Contact(
          id: 'CLI-001',
          name: 'client1',
          phone: '0748782205',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-002',
          name: 'Mme Adeline',
          phone: '05 45 42 01 63',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-003',
          name: 'Mme Elisa',
          phone: '05 96 92 43 28',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-004',
          name: 'Mme Safiatou',
          phone: '05 64 69 46 72',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-005',
          name: 'Mme CHANTAL',
          phone: '05 04 01 71 35',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-006',
          name: 'MME ADELE',
          phone: '01 53 04 60',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-007',
          name: 'TUO NAWA',
          phone: '07 10 39 36 09',
          type: ContactType.client,
          balance: 0.0),
      Contact(
          id: 'CLI-008',
          name: 'M. FULGENCE',
          phone: '07 68 47 18 25',
          type: ContactType.client,
          balance: 0.0),
    ];

    final seedSales = [
      Sale(
        id: 'sale-1',
        customerName: 'client1',
        items: [
          SaleItem(
              productId: 'POI-001',
              productName: 'PELON (lokor-lokor)',
              quantityKg: 2,
              unitPrice: 18500),
          SaleItem(
              productId: 'POI-002',
              productName: 'BELLE DAME',
              quantityKg: 1,
              unitPrice: 11500),
        ],
        totalAmount: 48500,
        paymentMode: PaymentMode.cash,
        date: now.subtract(const Duration(days: 3)),
        isSynced: true,
      ),
      Sale(
        id: 'sale-2',
        customerName: 'Mme Adeline',
        items: [
          SaleItem(
              productId: 'POI-003',
              productName: 'MACHOIRON',
              quantityKg: 3,
              unitPrice: 11000),
        ],
        totalAmount: 33000,
        paymentMode: PaymentMode.cash,
        date: now.subtract(const Duration(days: 2)),
        isSynced: true,
      ),
    ];

    final seedLedger = [
      LedgerEntry(
          id: 'led-1',
          date: now.subtract(const Duration(days: 30)),
          accountCode: '101',
          accountName: 'Capital',
          type: 'Crédit',
          amount: 5000000,
          label: 'Apport de capital initial',
          paymentMode: 'Autre'),
      LedgerEntry(
          id: 'led-2',
          date: now.subtract(const Duration(days: 30)),
          accountCode: '521',
          accountName: 'Banque',
          type: 'Débit',
          amount: 4000000,
          label: 'Versement capital Banque',
          paymentMode: 'Banque'),
      LedgerEntry(
          id: 'led-3',
          date: now.subtract(const Duration(days: 30)),
          accountCode: '571',
          accountName: 'Caisse',
          type: 'Débit',
          amount: 1000000,
          label: 'Alimentation caisse',
          paymentMode: 'Espèces'),
    ];

    final seedSettings = {
      'shopName': 'Poissonnerie Pro',
      'address': 'Gros de Bouaké, Côte d’Ivoire',
      'phone': '+225 07 07 20 33 22',
      'taxId': 'CC-0123456-B',
      'currency': 'FCFA',
      'vatRate': '18',
      'cashierPin': '1111',
      'managerPin': '6465',
      'adminPin': '1007',
    };

    _state = ShopState(
      products: seedProducts,
      sales: seedSales,
      purchases: [],
      losses: [],
      contacts: seedContacts,
      ledger: seedLedger,
      settings: seedSettings,
    );
    _stateController.add(_state);
  }
}
