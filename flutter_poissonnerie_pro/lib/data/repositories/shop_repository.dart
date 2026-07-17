import 'dart:async';
import '../models/poissonnerie_models.dart';

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
    for (var p in sales) { if (!p.isSynced) count++; }
    return count;
  }
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String accountCode;
  final String accountName;
  final String type; // 'Débit' or 'Crédit'
  final double amount;
  final String label;
  final String paymentMode;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.accountCode,
    required this.accountName,
    required this.type,
    required this.amount,
    required this.label,
    required this.paymentMode,
  });
}

class ShopRepository {
  late ShopState _state;
  final _stateController = StreamController<ShopState>.broadcast();

  Stream<ShopState> get stateStream => _stateController.stream;
  ShopState get currentState => _state;

  ShopRepository() {
    _loadSeedData();
  }

  void dispose() {
    _stateController.close();
  }

  void toggleOnlineStatus() {
    _state = _state.copyWith(isOnline: !_state.isOnline);
    _stateController.add(_state);
    if (_state.isOnline) {
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (!_state.isOnline) {
      _state = _state.copyWith(syncError: "Impossible de synchroniser en mode hors-ligne.");
      _stateController.add(_state);
      return;
    }

    _state = _state.copyWith(isSyncing: true, syncError: null);
    _stateController.add(_state);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mark all as synced
    final updatedSales = _state.sales.map((s) => s.copyWith(isSynced: true)).toList();

    _state = _state.copyWith(
      isSyncing: false,
      sales: updatedSales,
      syncError: null,
    );
    _stateController.add(_state);
  }

  void addProduct(Product product) {
    final updatedProducts = List<Product>.from(_state.products)..insert(0, product);
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
  }

  void updateProduct(Product product) {
    final updatedProducts = _state.products.map((p) => p.id == product.id ? product : p).toList();
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
  }

  void deleteProduct(String id) {
    final updatedProducts = _state.products.where((p) => p.id != id).toList();
    _state = _state.copyWith(products: updatedProducts);
    _stateController.add(_state);
  }

  void addContact(Contact contact) {
    final updatedContacts = List<Contact>.from(_state.contacts)..insert(0, contact);
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
  }

  void updateContact(Contact contact) {
    final updatedContacts = _state.contacts.map((c) => c.id == contact.id ? contact : c).toList();
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
  }

  void deleteContact(String id) {
    final updatedContacts = _state.contacts.where((c) => c.id != id).toList();
    _state = _state.copyWith(contacts: updatedContacts);
    _stateController.add(_state);
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
    final debitAccountName = paymentMode == PaymentMode.cash ? 'Caisse' : 'Banque';

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
    final matchIdx = updatedProducts.indexWhere((p) => p.name.toLowerCase() == fishName.toLowerCase());

    if (matchIdx != -1) {
      final matched = updatedProducts[matchIdx];
      final currentTotalVal = matched.stockKg * matched.purchasePrice;
      final newTotalVal = quantityKg * purchaseCost;
      final finalQty = matched.stockKg + quantityKg;
      final newWeightedAvg = finalQty > 0 ? ((currentTotalVal + newTotalVal) / finalQty) : purchaseCost;

      updatedProducts[matchIdx] = matched.copyWith(
        stockKg: finalQty,
        purchasePrice: newWeightedAvg,
        sellingPrice: suggestedSellingPrice,
      );
    } else {
      updatedProducts.insert(0, Product(
        id: 'prod-${now.millisecondsSinceEpoch}',
        name: fishName,
        category: ProductCategory.poissonFrais,
        stockKg: quantityKg,
        purchasePrice: purchaseCost,
        sellingPrice: suggestedSellingPrice,
        minThresholdKg: 10.0,
      ));
    }

    _state = _state.copyWith(
      purchases: [newArrival, ..._state.purchases],
      products: updatedProducts,
      ledger: [ledgerDebit, ledgerCredit, ..._state.ledger],
    );
    _stateController.add(_state);
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
  }

  void addExpense({
    required String label,
    required double amount,
    required PaymentMode paymentMode,
    required String category,
  }) {
    final now = DateTime.now();
    final newExpense = Expense(
      id: 'exp-${now.millisecondsSinceEpoch}',
      label: label,
      amount: amount,
      paymentMode: paymentMode,
      category: category,
      date: now,
    );

    // Ledger entry (Double entry):
    // Debit 65 (Autres charges / Frais de fonctionnement)
    // Credit 571 (Caisse) or 521 (Banque)
    final creditAccount = paymentMode == PaymentMode.cash ? '571' : '521';
    final creditAccountName = paymentMode == PaymentMode.cash ? 'Caisse' : 'Banque';

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
  }

  void updateSettings(Map<String, String> settings) {
    _state = _state.copyWith(settings: settings);
    _stateController.add(_state);
  }

  void resetToSeed() {
    _loadSeedData();
  }

  void _loadSeedData() {
    final now = DateTime.now();

    final seedProducts = [
      Product(id: 'prod-1', name: 'Bar de Ligne Entier', category: ProductCategory.poissonFrais, stockKg: 45.0, purchasePrice: 7000, sellingPrice: 12000, minThresholdKg: 15.0),
      Product(id: 'prod-2', name: 'Saumon Atlantique (Pavé)', category: ProductCategory.poissonCongele, stockKg: 28.0, purchasePrice: 8500, sellingPrice: 14500, minThresholdKg: 10.0),
      Product(id: 'prod-3', name: 'Daurade Royale de Mer', category: ProductCategory.poissonFrais, stockKg: 8.0, purchasePrice: 4000, sellingPrice: 7500, minThresholdKg: 12.0),
      Product(id: 'prod-4', name: 'Crevettes Tigrées Géantes', category: ProductCategory.crustaces, stockKg: 35.0, purchasePrice: 8000, sellingPrice: 14000, minThresholdKg: 10.0),
      Product(id: 'prod-5', name: 'Homard Bleu Vivant', category: ProductCategory.crustaces, stockKg: 5.0, purchasePrice: 18000, sellingPrice: 32000, minThresholdKg: 4.0),
      Product(id: 'prod-6', name: 'Huîtres Marennes d’Oléron N°3', category: ProductCategory.coquillages, stockKg: 12.0, purchasePrice: 4500, sellingPrice: 8500, minThresholdKg: 10.0),
      Product(id: 'prod-7', name: 'Noix de Saint-Jacques Franches', category: ProductCategory.coquillages, stockKg: 3.0, purchasePrice: 13000, sellingPrice: 24000, minThresholdKg: 8.0),
    ];

    final seedContacts = [
      Contact(id: 'cont-1', name: 'Sénégal Pêche SA', phone: '+221 33 849 11 22', type: ContactType.fournisseur, balance: -450000.0),
      Contact(id: 'cont-2', name: 'Marée d’Abidjan Grossiste', phone: '+225 07 45 12 34 56', type: ContactType.fournisseur, balance: 0.0),
      Contact(id: 'cont-3', name: 'Hôtel du Golfe Abidjan', phone: '+225 27 22 44 88 00', type: ContactType.client, balance: 150000.0),
      Contact(id: 'cont-4', name: 'Restaurant Le Phare Solaire', phone: '+225 05 66 77 88 99', type: ContactType.client, balance: 250000.0),
    ];

    final seedSales = [
      Sale(
        id: 'sale-1',
        customerName: 'Hôtel du Golfe Abidjan',
        items: [
          SaleItem(productId: 'prod-1', productName: 'Bar de Ligne Entier', quantityKg: 5, unitPrice: 12000),
          SaleItem(productId: 'prod-4', productName: 'Crevettes Tigrées Géantes', quantityKg: 3, unitPrice: 14000),
        ],
        totalAmount: 120360,
        paymentMode: PaymentMode.bank,
        date: now.subtract(const Duration(days: 3)),
        isSynced: true,
      ),
      Sale(
        id: 'sale-2',
        customerName: 'Client Comptant',
        items: [
          SaleItem(productId: 'prod-2', productName: 'Saumon Atlantique (Pavé)', quantityKg: 4, unitPrice: 14500),
        ],
        totalAmount: 108560,
        paymentMode: PaymentMode.cash,
        date: now.subtract(const Duration(days: 2)),
        isSynced: true,
      ),
    ];

    final seedLedger = [
      LedgerEntry(id: 'led-1', date: now.subtract(const Duration(days: 30)), accountCode: '101', accountName: 'Capital', type: 'Crédit', amount: 10000000, label: 'Apport de capital initial', paymentMode: 'Autre'),
      LedgerEntry(id: 'led-2', date: now.subtract(const Duration(days: 30)), accountCode: '521', accountName: 'Banque', type: 'Débit', amount: 8000000, label: 'Versement capital Banque', paymentMode: 'Banque'),
      LedgerEntry(id: 'led-3', date: now.subtract(const Duration(days: 30)), accountCode: '571', accountName: 'Caisse', type: 'Débit', amount: 2000000, label: 'Alimentation caisse', paymentMode: 'Espèces'),
      LedgerEntry(id: 'led-f1', date: now.subtract(const Duration(days: 6)), accountCode: '65', accountName: 'Autres Charges / Frais', type: 'Débit', amount: 35000, label: 'Frais de Glace écailleuse', paymentMode: 'Espèces'),
      LedgerEntry(id: 'led-f2', date: now.subtract(const Duration(days: 6)), accountCode: '571', accountName: 'Caisse', type: 'Crédit', amount: 35000, label: 'Paiement Glace écailleuse', paymentMode: 'Espèces'),
    ];

    final seedSettings = {
      'shopName': 'Poissonnerie Pro',
      'address': '12 Port de Pêche, Abidjan, Côte d’Ivoire',
      'phone': '+225 07 45 12 34 56',
      'taxId': 'CC-9876543-A',
      'currency': 'FCFA',
      'vatRate': '18',
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
