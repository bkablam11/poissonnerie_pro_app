import 'package:uuid/uuid.dart';

enum ProductCategory {
  poissonFrais,
  poissonCongele,
  crustaces,
  coquillages,
  divers
}

extension CategoryExtension on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.poissonFrais:
        return 'Poisson Frais';
      case ProductCategory.poissonCongele:
        return 'Poisson Congelé (Paquet/Carton)';
      case ProductCategory.crustaces:
        return 'Crustacés';
      case ProductCategory.coquillages:
        return 'Coquillages';
      case ProductCategory.divers:
        return 'Divers / Autre';
    }
  }
}

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final double stockKg;
  final double purchasePrice; // Price in CFA
  final double sellingPrice;  // Price in CFA
  final double minThresholdKg;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.stockKg,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minThresholdKg,
  });

  bool get isLowStock => stockKg <= minThresholdKg;
  bool get isOutOfStock => stockKg <= 0;

  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    double? stockKg,
    double? purchasePrice,
    double? sellingPrice,
    double? minThresholdKg,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stockKg: stockKg ?? this.stockKg,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minThresholdKg: minThresholdKg ?? this.minThresholdKg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'stockKg': stockKg,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'minThresholdKg': minThresholdKg,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: ProductCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductCategory.poissonCongele,
      ),
      stockKg: (map['stockKg'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      minThresholdKg: (map['minThresholdKg'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final double quantityKg;
  final double unitPrice;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitPrice,
  });

  double get subtotal => quantityKg * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityKg': quantityKg,
      'unitPrice': unitPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

enum PaymentMode {
  cash, // Account 571
  bank  // Account 521 (Mobile Money / Bank)
}

extension PaymentModeExtension on PaymentMode {
  String get label => this == PaymentMode.cash ? 'Espèces (571)' : 'Banque & Mobile Money (521)';
}

class Sale {
  final String id;
  final String? customerName;
  final List<SaleItem> items;
  final double totalAmount;
  final PaymentMode paymentMode;
  final DateTime date;
  final bool isSynced;

  Sale({
    required this.id,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    required this.date,
    this.isSynced = false,
  });

  Sale copyWith({
    String? id,
    String? customerName,
    List<SaleItem>? items,
    double? totalAmount,
    PaymentMode? paymentMode,
    DateTime? date,
    bool? isSynced,
  }) {
    return Sale(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMode': paymentMode.name,
      'date': date.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] ?? '',
      customerName: map['customerName'],
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => SaleItem.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['paymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      isSynced: map['isSynced'] ?? false,
    );
  }
}

class Arrival {
  final String id;
  final String supplierName;
  final String fishName;
  final double quantityKg;
  final double unitPurchaseCost;
  final double suggestedSellingPrice;
  final DateTime date;

  Arrival({
    required this.id,
    required this.supplierName,
    required this.fishName,
    required this.quantityKg,
    required this.unitPurchaseCost,
    required this.suggestedSellingPrice,
    required this.date,
  });

  double get totalCost => quantityKg * unitPurchaseCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierName': supplierName,
      'fishName': fishName,
      'quantityKg': quantityKg,
      'unitPurchaseCost': unitPurchaseCost,
      'suggestedSellingPrice': suggestedSellingPrice,
      'date': date.toIso8601String(),
    };
  }

  factory Arrival.fromMap(Map<String, dynamic> map) {
    return Arrival(
      id: map['id'] ?? '',
      supplierName: map['supplierName'] ?? '',
      fishName: map['fishName'] ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      unitPurchaseCost: (map['unitPurchaseCost'] as num?)?.toDouble() ?? 0.0,
      suggestedSellingPrice: (map['suggestedSellingPrice'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}

enum LossReason {
  perime,
  avarie,
  spoliation,
  surstock
}

extension LossReasonExtension on LossReason {
  String get label {
    switch (this) {
      case LossReason.perime:
        return 'Périmé / Pourri';
      case LossReason.avarie:
        return 'Avarie Congélateur';
      case LossReason.spoliation:
        return 'Vol / Perte Spéciale';
      case LossReason.surstock:
        return 'Excédent gâché';
    }
  }
}

class Loss {
  final String id;
  final String productId;
  final String productName;
  final double quantityKg;
  final double unitCost;
  final LossReason reason;
  final DateTime date;

  Loss({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitCost,
    required this.reason,
    required this.date,
  });

  double get totalLossValue => quantityKg * unitCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantityKg': quantityKg,
      'unitCost': unitCost,
      'reason': reason.name,
      'date': date.toIso8601String(),
    };
  }

  factory Loss.fromMap(Map<String, dynamic> map) {
    return Loss(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      reason: LossReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => LossReason.avarie,
      ),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}

enum ContactType {
  client,
  fournisseur
}

class Contact {
  final String id;
  final String name;
  final String phone;
  final ContactType type;
  final double balance; // Positive = owes us, Negative = we owe them

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.balance = 0.0,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    ContactType? type,
    double? balance,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type.name,
      'balance': balance,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: ContactType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContactType.client,
      ),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Expense {
  final String id;
  final String label;
  final double amount;
  final PaymentMode paymentMode; // Cash (571) or Bank/MoMo (521)
  final String category; // e.g. "Glace", "Électricité", "Transport", "Emballage"
  final DateTime date;

  Expense({
    required this.id,
    required this.label,
    required this.amount,
    required this.paymentMode,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'paymentMode': paymentMode.name,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['paymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      category: map['category'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'accountCode': accountCode,
      'accountName': accountName,
      'type': type,
      'amount': amount,
      'label': label,
      'paymentMode': paymentMode,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      accountCode: map['accountCode'] ?? '',
      accountName: map['accountName'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] ?? '',
      paymentMode: map['paymentMode'] ?? '',
    );
  }
}
