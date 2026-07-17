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
        return 'Poisson Congelé';
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
  final double purchasePrice; // Price per Kg in CFA
  final double sellingPrice;  // Price per Kg in CFA
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
}
