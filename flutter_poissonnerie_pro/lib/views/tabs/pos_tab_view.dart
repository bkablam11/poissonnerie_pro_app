import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class PosTabView extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const PosTabView({super.key, required this.onNavigate});

  @override
  ConsumerState<PosTabView> createState() => _PosTabViewState();
}

class _PosTabViewState extends ConsumerState<PosTabView> {
  final List<SaleItem> _cart = [];
  String? _selectedClientId;
  PaymentMode _paymentMode = PaymentMode.cash;
  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _addToCart(Product prod) {
    if (prod.stockKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rupture de Stock! Impossible de vendre.')),
      );
      return;
    }

    final existingIdx = _cart.indexWhere((item) => item.productId == prod.id);
    if (existingIdx != -1) {
      final currentQty = _cart[existingIdx].quantityKg;
      if (currentQty + 1 > prod.stockKg) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantité maximale atteinte en fonction du stock disponible.')),
        );
        return;
      }
      setState(() {
        _cart[existingIdx] = SaleItem(
          productId: prod.id,
          productName: prod.name,
          quantityKg: currentQty + 1,
          unitPrice: prod.sellingPrice,
        );
      });
    } else {
      setState(() {
        _cart.add(SaleItem(
          productId: prod.id,
          productName: prod.name,
          quantityKg: 1.0,
          unitPrice: prod.sellingPrice,
        ));
      });
    }
  }

  void _updateCartQuantity(int idx, double newQty, double maxStock) {
    if (newQty <= 0) {
      setState(() {
        _cart.removeAt(idx);
      });
      return;
    }
    if (newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock insuffisant pour cette quantité.')),
      );
      return;
    }
    setState(() {
      final item = _cart[idx];
      _cart[idx] = SaleItem(
        productId: item.productId,
        productName: item.productName,
        quantityKg: newQty,
        unitPrice: item.unitPrice,
      );
    });
  }

  double get _cartTotal => _cart.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  void _checkout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide.')),
      );
      return;
    }

    ref.read(shopViewModelProvider.notifier).addSale(
          items: List<SaleItem>.from(_cart),
          clientId: _selectedClientId,
          paymentMode: _paymentMode,
          total: _cartTotal,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vente enregistrée avec succès!')),
    );

    setState(() {
      _cart.clear();
      _selectedClientId = null;
      _paymentMode = PaymentMode.cash;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // Filtered Products
    final filteredProducts = state.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Clients
    final clients = state.contacts.where((c) => c.type == ContactType.client).toList();

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Row(
      children: [
        // Product Selection Grid Panel (Left)
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search & Category Filters Row
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un poisson...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 12),
                        // Horizontal Categories
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ChoiceChip(
                                label: const Text('Tout'),
                                selected: _selectedCategory == null,
                                onSelected: (_) => setState(() => _selectedCategory = null),
                              ),
                              const SizedBox(width: 8),
                              ...ProductCategory.values.map((cat) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(cat.label),
                                    selected: _selectedCategory == cat,
                                    onSelected: (_) => setState(() => _selectedCategory = cat),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Products list grid
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, idx) {
                      final p = filteredProducts[idx];
                      return Card(
                        child: InkWell(
                          onTap: () => _addToCart(p),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, py: 1),
                                      decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        p.category.label,
                                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatMoney(p.sellingPrice, currency),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                        ),
                                        Text(
                                          'Stock: ${p.stockKg.toStringAsFixed(1)} kg',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: p.stockKg <= p.minThresholdKg ? Colors.pink : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFFF6B6B),
                                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cart Checkout summary Column (Right)
        Container(
          width: 320,
          color: Colors.white,
          child: Column(
            children: [
              // Cart Header
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: Color(0xFFFF6B6B), size: 18),
                        SizedBox(width: 8),
                        Text('Panier de Vente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, py: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${_cart.length} items',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Cart item list
              Expanded(
                child: _cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Votre panier est vide', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _cart.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, idx) {
                          final item = _cart[idx];
                          final prod = state.products.firstWhere((p) => p.id == item.productId);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 16),
                                            onPressed: () => _updateCartQuantity(idx, item.quantityKg - 1, prod.stockKg),
                                          ),
                                          Text(
                                            '${item.quantityKg.toStringAsFixed(0)} kg',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 16),
                                            onPressed: () => _updateCartQuantity(idx, item.quantityKg + 1, prod.stockKg),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatMoney(item.subtotal, currency),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Billing customer selection & Action section
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer Dropdown selection
                    const Text('CLIENT DE LA TRANSACTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Client Comptant (Anonyme)', style: TextStyle(fontSize: 11)),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Client Comptant', style: TextStyle(fontSize: 11)),
                        ),
                        ...clients.map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(fontSize: 11)),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedClientId = val),
                    ),
                    const SizedBox(height: 12),

                    // Payment Mode Toggle Switch
                    const Text('RÈGLEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('ESPÈCES (571)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                            selected: _paymentMode == PaymentMode.cash,
                            onSelected: (_) => setState(() => _paymentMode = PaymentMode.cash),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('BANQUE (521)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                            selected: _paymentMode == PaymentMode.bank,
                            onSelected: (_) => setState(() => _paymentMode = PaymentMode.bank),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Calculation Block
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL À PAYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E3A4B))),
                        Text(
                          _formatMoney(_cartTotal, currency),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: Color(0xFFFF6B6B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submission checkout button
                    ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        disabledBackgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Valider & Imprimer Facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
