import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/poissonnerie_models.dart';
import '../data/repositories/shop_repository.dart';

enum UserRole {
  none,
  cashier, // Caissier (Ventes, Pertes)
  manager, // Gérant (Comptabilité, Paramètres, Stock, Arrivages, etc.)
}

final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.none);

// Create a single instance provider for our repository
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final repo = ShopRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Create the StateNotifier to manage and publish the UI state
class ShopViewModel extends StateNotifier<ShopState> {
  final ShopRepository _repository;
  StreamSubscription<ShopState>? _subscription;

  ShopViewModel(this._repository) : super(_repository.currentState) {
    // Listen to changes in the repository stream
    _subscription = _repository.stateStream.listen((newState) {
      state = newState;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void toggleOnlineStatus() {
    _repository.toggleOnlineStatus();
  }

  Future<void> syncOfflineData() async {
    await _repository.triggerSync();
  }

  void resetToSeed() {
    _repository.resetToSeed();
  }

  // Products
  void addProduct(Product p) => _repository.addProduct(p);
  void updateProduct(Product p) => _repository.updateProduct(p);
  void deleteProduct(String id) => _repository.deleteProduct(id);

  // Contacts
  void addContact(Contact c) => _repository.addContact(c);
  void updateContact(Contact c) => _repository.updateContact(c);
  void deleteContact(String id) => _repository.deleteContact(id);

  // Operations
  void addSale({
    required List<SaleItem> items,
    required String? clientId,
    required PaymentMode paymentMode,
    required double total,
  }) {
    _repository.addSale(
      items: items,
      clientId: clientId,
      paymentMode: paymentMode,
      total: total,
    );
  }

  void addArrival({
    required String supplierId,
    required String fishName,
    required double quantityKg,
    required double purchaseCost,
    required double suggestedSellingPrice,
  }) {
    _repository.addArrival(
      supplierId: supplierId,
      fishName: fishName,
      quantityKg: quantityKg,
      purchaseCost: purchaseCost,
      suggestedSellingPrice: suggestedSellingPrice,
    );
  }

  void addLoss({
    required String productId,
    required double quantityKg,
    required LossReason reason,
  }) {
    _repository.addLoss(
      productId: productId,
      quantityKg: quantityKg,
      reason: reason,
    );
  }

  void addExpense({
    required String label,
    required double amount,
    required PaymentMode paymentMode,
    required String category,
  }) {
    _repository.addExpense(
      label: label,
      amount: amount,
      paymentMode: paymentMode,
      category: category,
    );
  }

  void updateSettings(Map<String, String> settings) {
    _repository.updateSettings(settings);
  }
}

// Publish the ViewModel as a Riverpod StateNotifierProvider
final shopViewModelProvider = StateNotifierProvider<ShopViewModel, ShopState>((ref) {
  final repo = ref.watch(shopRepositoryProvider);
  return ShopViewModel(repo);
});
