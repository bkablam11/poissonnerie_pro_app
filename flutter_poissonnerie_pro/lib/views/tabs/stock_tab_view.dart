import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class StockTabView extends ConsumerStatefulWidget {
  const StockTabView({super.key});

  @override
  ConsumerState<StockTabView> createState() => _StockTabViewState();
}

class _StockTabViewState extends ConsumerState<StockTabView> {
  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _showProductDialog([Product? prod]) {
    final isEdit = prod != null;
    final nameController = TextEditingController(text: isEdit ? prod.name : '');
    final purchasePriceController = TextEditingController(text: isEdit ? prod.purchasePrice.toStringAsFixed(0) : '3000');
    final sellingPriceController = TextEditingController(text: isEdit ? prod.sellingPrice.toStringAsFixed(0) : '5000');
    final stockController = TextEditingController(text: isEdit ? prod.stockKg.toStringAsFixed(1) : '10.0');
    final minThresholdController = TextEditingController(text: isEdit ? prod.minThresholdKg.toStringAsFixed(1) : '10.0');
    ProductCategory category = isEdit ? prod.category : ProductCategory.poissonFrais;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Modifier le Produit' : 'Ajouter un Produit au Catalogue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom du Poisson / Article'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductCategory>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: ProductCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purchasePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix d’Achat Moyen Pondéré (CFA/Kg)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix de Vente Conseillé (CFA/Kg)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock Actuel (Kg)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minThresholdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Seuil Alerte (Kg)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final pPrice = double.tryParse(purchasePriceController.text) ?? 0.0;
                    final sPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
                    final stock = double.tryParse(stockController.text) ?? 0.0;
                    final minThr = double.tryParse(minThresholdController.text) ?? 10.0;

                    if (name.isEmpty) return;

                    final notifier = ref.read(shopViewModelProvider.notifier);
                    if (isEdit) {
                      notifier.updateProduct(Product(
                        id: prod.id,
                        name: name,
                        category: category,
                        stockKg: stock,
                        purchasePrice: pPrice,
                        sellingPrice: sPrice,
                        minThresholdKg: minThr,
                      ));
                    } else {
                      notifier.addProduct(Product(
                        id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        category: category,
                        stockKg: stock,
                        purchasePrice: pPrice,
                        sellingPrice: sPrice,
                        minThresholdKg: minThr,
                      ));
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Produit mis à jour.' : 'Produit enregistré dans le catalogue.')),
                    );
                  },
                  child: Text(isEdit ? 'Enregistrer' : 'Ajouter', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    final filteredProducts = state.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Panel & Add Trigger Header Row
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: 'Chercher un poisson...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<ProductCategory>(
                    value: _selectedCategory,
                    hint: const Text('Toutes catégories', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes catégories', style: TextStyle(fontSize: 12))),
                      ...ProductCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.label, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text('Nouveau Poisson', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inventory Table Ledger view
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('POISSON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('STOCK (KG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('PAMP (CFA/KG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('PRIX VENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('STATUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: filteredProducts.map((p) {
                    final isLow = p.isLowStock;
                    final isOut = p.isOutOfStock;

                    return DataRow(
                      cells: [
                        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                        DataCell(Text(p.category.label, style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Text(
                            '${p.stockKg.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.black),
                            ),
                          ),
                        ),
                        DataCell(Text(_formatMoney(p.purchasePrice, currency), style: const TextStyle(fontSize: 12, fontFamily: 'Courier'))),
                        DataCell(Text(_formatMoney(p.sellingPrice, currency), style: const TextStyle(fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, py: 2),
                            decoration: BoxDecoration(
                              color: isOut
                                  ? Colors.red.shade50
                                  : (isLow ? Colors.orange.shade50 : Colors.green.shade50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOut ? 'SÉCURISÉ' : (isLow ? 'STOCKS BAS' : 'DISPO'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.green),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 18),
                                onPressed: () => _showProductDialog(p),
                                tooltip: 'Modifier',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.pink, size: 18),
                                onPressed: () {
                                  ref.read(shopViewModelProvider.notifier).deleteProduct(p.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit archivé.')));
                                },
                                tooltip: 'Archiver / Supprimer',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
