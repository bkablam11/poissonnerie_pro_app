import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class PurchasesTabView extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const PurchasesTabView({super.key, required this.onNavigate});

  @override
  ConsumerState<PurchasesTabView> createState() => _PurchasesTabViewState();
}

class _PurchasesTabViewState extends ConsumerState<PurchasesTabView> {
  String? _selectedSupplierId;
  final _fishNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '20.0');
  final _purchaseCostController = TextEditingController(text: '3000');
  final _suggestedPriceController = TextEditingController(text: '5000');

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _submitArrival() {
    final supplierId = _selectedSupplierId;
    final fishName = _fishNameController.text.trim();
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final cost = double.tryParse(_purchaseCostController.text) ?? 0.0;
    final suggested = double.tryParse(_suggestedPriceController.text) ?? 0.0;

    if (supplierId == null || fishName.isEmpty || qty <= 0 || cost <= 0 || suggested <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir correctement tous les champs de l’approvisionnement.')),
      );
      return;
    }

    ref.read(shopViewModelProvider.notifier).addArrival(
          supplierId: supplierId,
          fishName: fishName,
          quantityKg: qty,
          purchaseCost: cost,
          suggestedSellingPrice: suggested,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouvel arrivage enregistré et stocks ajustés avec succès!')),
    );

    setState(() {
      _fishNameController.clear();
      _selectedSupplierId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // Suppliers
    final suppliers = state.contacts.where((c) => c.type == ContactType.fournisseur).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registration Form Panel (Left)
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_rounded, color: Color(0xFFFF6B6B), size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Enregistrer un Nouvel Arrivage de Poisson',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E3A4B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Supplier choice
                      const Text('FOURNISSEUR CONCERNÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        hint: const Text('Sélectionner le fournisseur grossiste', style: TextStyle(fontSize: 12)),
                        items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setState(() => _selectedSupplierId = val),
                      ),
                      const SizedBox(height: 16),

                      // Fish Name
                      const Text('VARIÉTÉ / NOM DU POISSON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fishNameController,
                        decoration: const InputDecoration(hintText: 'Ex: Capitaine, Mérou, Sole, etc.', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      ),
                      const SizedBox(height: 16),

                      // Quantity and Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('QUANTITÉ (KG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('COÛT D’ACHAT (CFA/KG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _purchaseCostController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Suggested retail price
                      const Text('PRIX DE VENTE CONSEILLÉ (CFA/KG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _suggestedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submitArrival,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Enregistrer l’Arrivage & Payer au Port', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Arrivals History Log List (Right)
          Expanded(
            flex: 5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_rounded, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Historique des Approvisionnements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B))),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: state.purchases.isEmpty
                          ? Center(
                              child: Text('Aucun arrivage enregistré pour le moment', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            )
                          : ListView.builder(
                              itemCount: state.purchases.length,
                              itemBuilder: (context, idx) {
                                final item = state.purchases[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.fishName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            Text(
                                              '${item.quantityKg.toStringAsFixed(0)} kg',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Grossiste: ${item.supplierName}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            Text(_formatMoney(item.totalCost, currency), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
