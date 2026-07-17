import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class LossesTabView extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const LossesTabView({super.key, required this.onNavigate});

  @override
  ConsumerState<LossesTabView> createState() => _LossesTabViewState();
}

class _LossesTabViewState extends ConsumerState<LossesTabView> {
  String? _selectedProductId;
  final _quantityController = TextEditingController(text: '2.0');
  LossReason _selectedReason = LossReason.perime;

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _submitLoss() {
    final productId = _selectedProductId;
    final qty = double.tryParse(_quantityController.text) ?? 0.0;

    if (productId == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit et inscrire un poids correct.')),
      );
      return;
    }

    final prod = ref.read(shopViewModelProvider).products.firstWhere((p) => p.id == productId);
    if (qty > prod.stockKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le stock restant de ce poisson est insuffisant pour enregistrer cette perte.')),
      );
      return;
    }

    ref.read(shopViewModelProvider.notifier).addLoss(
          productId: productId,
          quantityKg: qty,
          reason: _selectedReason,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Déclaration de perte enregistrée dans le grand livre.')),
    );

    setState(() {
      _selectedProductId = null;
      _selectedReason = LossReason.perime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // Calculate total losses sum
    final totalLosses = state.losses.fold<double>(0.0, (sum, l) => sum + l.totalLossValue);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column Form
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Losses KPI Header Summary card
                  Card(
                    color: Colors.pink.shade50.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.analytics_rounded, color: Colors.pink.shade600, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL DES PERTES ET SPOILS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                _formatMoney(totalLosses, currency),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.black, color: Colors.pink.shade700, fontFamily: 'Courier'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, color: Colors.pink, size: 22),
                              SizedBox(width: 12),
                              Text('Déclarer une Perte de Poisson', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Select Fish
                          const Text('POISSON CONCERNÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedProductId,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            hint: const Text('Sélectionner le poisson altéré', style: TextStyle(fontSize: 12)),
                            items: state.products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (Dispo: ${p.stockKg.toStringAsFixed(1)} kg)', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) => setState(() => _selectedProductId = val),
                          ),
                          const SizedBox(height: 16),

                          // Quantity Kg & Reason Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('POIDS PERDU (KG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                                    const Text('MOTIF DU GÂCHAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<LossReason>(
                                      value: _selectedReason,
                                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                      items: LossReason.values.map((reason) => DropdownMenuItem(value: reason, child: Text(reason.label, style: const TextStyle(fontSize: 12)))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedReason = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _submitLoss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Soumettre la Déclaration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Right Column: Registry Ledger Log List
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
                        Text('Registre de Spoliation & Déchets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B))),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: state.losses.isEmpty
                          ? Center(
                              child: Text('Aucune perte déclarée récemment.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            )
                          : ListView.builder(
                              itemCount: state.losses.length,
                              itemBuilder: (context, idx) {
                                final item = state.losses[idx];
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
                                              item.productName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            Text(
                                              '- ${item.quantityKg.toStringAsFixed(1)} kg',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Motif: ${item.reason.label}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            Text(_formatMoney(item.totalLossValue, currency), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
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
