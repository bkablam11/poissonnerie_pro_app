import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poissonnerie_models.dart';

/// Contrat abstrait pour la synchronisation Cloud.
/// Vous pouvez implémenter ce contrat avec le fournisseur de votre choix (Firebase ou Supabase).
abstract class CloudSyncService {
  /// Envoie les ventes non synchronisées vers le cloud
  Future<bool> pushSales(List<Sale> sales);

  /// Synchronise la liste des produits avec le catalogue central
  Future<bool> pushProducts(List<Product> products);

  /// Synchronise les approvisionnements (achats)
  Future<bool> pushPurchases(List<Arrival> purchases);

  /// Synchronise les pertes enregistrées
  Future<bool> pushLosses(List<Loss> losses);

  /// Synchronise les contacts (clients et fournisseurs)
  Future<bool> pushContacts(List<Contact> contacts);

  /// Synchronise le grand livre comptable (entrées double-entrée)
  Future<bool> pushLedger(List<LedgerEntry> ledger);

  /// Récupère la dernière version consolidée du catalogue de produits depuis le Cloud
  Future<List<Product>> fetchLatestProducts();

  /// Récupère la liste de tous les contacts enregistrés sur le serveur central
  Future<List<Contact>> fetchLatestContacts();
}

// ============================================================================
// 1. IMPLÉMÈNTATION EN PRODUCTION DE SUPABASE (Dynamique & Clé en Main)
// ============================================================================
class SupabaseSyncService implements CloudSyncService {
  final String url;
  final String anonKey;
  SupabaseClient? _client;

  SupabaseSyncService({required this.url, required this.anonKey});

  SupabaseClient get client {
    _client ??= SupabaseClient(url, anonKey);
    return _client!;
  }

  @override
  Future<bool> pushSales(List<Sale> sales) async {
    try {
      final supabaseClient = client;
      for (final sale in sales) {
        // 1. Enregistrer l'en-tête de la vente
        await supabaseClient.from('sales').upsert({
          'id': sale.id,
          'customer_name': sale.customerName,
          'total_amount': sale.totalAmount,
          'payment_mode': sale.paymentMode.name,
          'date': sale.date.toIso8601String(),
        });

        // 2. Nettoyer et réinsérer les éléments pour éviter les doublons
        await supabaseClient.from('sale_items').delete().eq('sale_id', sale.id);

        final itemsData = sale.items.map((item) => {
          'sale_id': sale.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity_kg': item.quantityKg,
          'unit_price': item.unitPrice,
        }).toList();

        if (itemsData.isNotEmpty) {
          await supabaseClient.from('sale_items').insert(itemsData);
        }
      }
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Sales) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushProducts(List<Product> products) async {
    try {
      final supabaseClient = client;
      final data = products.map((p) => {
        'id': p.id,
        'name': p.name,
        'category': p.category.name,
        'stock_kg': p.stockKg,
        'purchase_price': p.purchasePrice,
        'selling_price': p.sellingPrice,
        'min_threshold_kg': p.minThresholdKg,
      }).toList();
      await supabaseClient.from('products').upsert(data);
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Products) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushPurchases(List<Arrival> purchases) async {
    try {
      final supabaseClient = client;
      final data = purchases.map((p) => {
        'id': p.id,
        'supplier_name': p.supplierName,
        'fish_name': p.fishName,
        'quantity_kg': p.quantityKg,
        'unit_purchase_cost': p.unitPurchaseCost,
        'suggested_selling_price': p.suggestedSellingPrice,
        'date': p.date.toIso8601String(),
      }).toList();
      await supabaseClient.from('purchases').upsert(data);
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Purchases) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushLosses(List<Loss> losses) async {
    try {
      final supabaseClient = client;
      final data = losses.map((l) => {
        'id': l.id,
        'product_id': l.productId,
        'product_name': l.productName,
        'quantity_kg': l.quantityKg,
        'unit_cost': l.unitCost,
        'reason': l.reason.name,
        'date': l.date.toIso8601String(),
      }).toList();
      await supabaseClient.from('losses').upsert(data);
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Losses) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushContacts(List<Contact> contacts) async {
    try {
      final supabaseClient = client;
      final data = contacts.map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'type': c.type.name,
        'balance': c.balance,
      }).toList();
      await supabaseClient.from('contacts').upsert(data);
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Contacts) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushLedger(List<LedgerEntry> ledger) async {
    try {
      final supabaseClient = client;
      final data = ledger.map((l) => {
        'id': l.id,
        'date': l.date.toIso8601String(),
        'account_code': l.accountCode,
        'account_name': l.accountName,
        'type': l.type,
        'amount': l.amount,
        'label': l.label,
        'payment_mode': l.paymentMode,
      }).toList();
      await supabaseClient.from('ledger').upsert(data);
      return true;
    } catch (e) {
      print("Erreur de synchronisation Supabase (Ledger) : $e");
      return false;
    }
  }

  @override
  Future<List<Product>> fetchLatestProducts() async {
    try {
      final supabaseClient = client;
      final response = await supabaseClient.from('products').select();
      return (response as List).map((map) {
        return Product(
          id: map['id'] ?? '',
          name: map['name'] ?? '',
          category: ProductCategory.values.firstWhere(
            (e) => e.name == map['category'],
            orElse: () => ProductCategory.poissonCongele,
          ),
          stockKg: (map['stock_kg'] as num?)?.toDouble() ?? 0.0,
          purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
          minThresholdKg: (map['min_threshold_kg'] as num?)?.toDouble() ?? 5.0,
        );
      }).toList();
    } catch (e) {
      print("Erreur de chargement Supabase (Products) : $e");
      return [];
    }
  }

  @override
  Future<List<Contact>> fetchLatestContacts() async {
    try {
      final supabaseClient = client;
      final response = await supabaseClient.from('contacts').select();
      return (response as List).map((map) {
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
      }).toList();
    } catch (e) {
      print("Erreur de chargement Supabase (Contacts) : $e");
      return [];
    }
  }
}

// ============================================================================
// 2. IMPLÉMÈNTATION EN PRODUCTION DE FIREBASE FIRESTORE (Exemple Clé en Main)
// ============================================================================
/*
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSyncService implements CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> pushSales(List<Sale> sales) async {
    try {
      final batch = _firestore.batch();
      for (final sale in sales) {
        final docRef = _firestore.collection('sales').doc(sale.id);
        batch.set(docRef, {
          'id': sale.id,
          'customerName': sale.customerName,
          'totalAmount': sale.totalAmount,
          'paymentMode': sale.paymentMode.name,
          'date': sale.date.toIso8601String(),
          'items': sale.items.map((i) => i.toMap()).toList(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Sales) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushProducts(List<Product> products) async {
    try {
      final batch = _firestore.batch();
      for (final prod in products) {
        final docRef = _firestore.collection('products').doc(prod.id);
        batch.set(docRef, prod.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Products) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushPurchases(List<Arrival> purchases) async {
    try {
      final batch = _firestore.batch();
      for (final purchase in purchases) {
        final docRef = _firestore.collection('purchases').doc(purchase.id);
        batch.set(docRef, purchase.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Purchases) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushLosses(List<Loss> losses) async {
    try {
      final batch = _firestore.batch();
      for (final loss in losses) {
        final docRef = _firestore.collection('losses').doc(loss.id);
        batch.set(docRef, loss.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Losses) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushContacts(List<Contact> contacts) async {
    try {
      final batch = _firestore.batch();
      for (final contact in contacts) {
        final docRef = _firestore.collection('contacts').doc(contact.id);
        batch.set(docRef, contact.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Contacts) : $e");
      return false;
    }
  }

  @override
  Future<bool> pushLedger(List<LedgerEntry> ledger) async {
    try {
      final batch = _firestore.batch();
      for (final entry in ledger) {
        final docRef = _firestore.collection('ledger').doc(entry.id);
        batch.set(docRef, entry.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur de synchronisation Firebase (Ledger) : $e");
      return false;
    }
  }

  @override
  Future<List<Product>> fetchLatestProducts() async {
    final query = await _firestore.collection('products').get();
    return query.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  @override
  Future<List<Contact>> fetchLatestContacts() async {
    final query = await _firestore.collection('contacts').get();
    return query.docs.map((doc) => Contact.fromMap(doc.data())).toList();
  }
}
*/

// ============================================================================
// 3. SERVICE SIMULÉ (MOCK) - Actif par défaut pour compiler le code
// ============================================================================
class MockCloudSyncService implements CloudSyncService {
  @override
  Future<bool> pushSales(List<Sale> sales) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  @override
  Future<bool> pushProducts(List<Product> products) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<bool> pushPurchases(List<Arrival> purchases) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<bool> pushLosses(List<Loss> losses) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<bool> pushContacts(List<Contact> contacts) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<bool> pushLedger(List<LedgerEntry> ledger) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  @override
  Future<List<Product>> fetchLatestProducts() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return []; // Retourne une liste vide pour la démo hors-ligne simulée
  }

  @override
  Future<List<Contact>> fetchLatestContacts() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [];
  }
}
