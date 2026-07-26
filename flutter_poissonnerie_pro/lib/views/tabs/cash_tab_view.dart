import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class CashTabView extends ConsumerStatefulWidget {
  const CashTabView({super.key});

  @override
  ConsumerState<CashTabView> createState() => _CashTabViewState();
}

class _CashTabViewState extends ConsumerState<CashTabView> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController(text: '15000');
  String _selectedCategory = 'Glace et Consommables';
  PaymentMode _paymentMode = PaymentMode.cash;

  final List<String> _categories = [
    'Glace et Consommables',
    'Emballage',
    'Électricité & Eau',
    'Transport & Carburant',
    'Salaires',
    'Divers',
  ];

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _submitExpense() {
    final label = _labelController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (label.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez spécifier un libellé et un montant de charge valides.')),
      );
      return;
    }

    ref.read(shopViewModelProvider.notifier).addExpense(
          label: label,
          amount: amount,
          paymentMode: _paymentMode,
          category: _selectedCategory,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Charge opérationnelle enregistrée dans la caisse.')),
    );

    setState(() {
      _labelController.clear();
      _paymentMode = PaymentMode.cash;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // Calculate Caisse 571 & Banque 521 Balances
    double cashDebit = 0.0;
    double cashCredit = 0.0;
    double bankDebit = 0.0;
    double bankCredit = 0.0;

    for (var entry in state.ledger) {
      if (entry.accountCode == '571') {
        if (entry.type == 'Débit') {
          cashDebit += entry.amount;
        } else {
          cashCredit += entry.amount;
        }
      } else if (entry.accountCode == '521') {
        if (entry.type == 'Débit') {
          bankDebit += entry.amount;
        } else {
          bankCredit += entry.amount;
        }
      }
    }

    final cashBalance = cashDebit - cashCredit;
    final bankBalance = bankDebit - bankCredit;

    // Filter Ledger Entries for Cash/Bank movements (571, 521)
    final treasuryLedger = state.ledger
        .where((entry) => entry.accountCode == '571' || entry.accountCode == '521')
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 1024;

    final cashCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPTE 571 — CAISSE PHYSIQUE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMoney(cashBalance, currency),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontFamily: 'Courier'),
                  ),
                ],
              ),
            ),
            const Icon(Icons.payments_rounded, color: Colors.orange, size: 24),
          ],
        ),
      ),
    );

    final bankCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPTE 521 — BANQUE & MOMO',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMoney(bankBalance, currency),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green, fontFamily: 'Courier'),
                  ),
                ],
              ),
            ),
            const Icon(Icons.account_balance_rounded, color: Colors.green, size: 24),
          ],
        ),
      ),
    );

    final formCard = Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFF6B6B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enregistrer des Frais de Fonctionnement',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            const Text('CATÉGORIE DE DÉPENSE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),

            // Label & Amount Column/Row
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LIBELLÉ DESCRIPTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _labelController,
                            decoration: const InputDecoration(hintText: 'Ex: Achat 5 sacs de glace', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MONTANT (CFA)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LIBELLÉ DESCRIPTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _labelController,
                              decoration: const InputDecoration(hintText: 'Ex: Achat 5 sacs de glace', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MONTANT (CFA)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // Payment Mode
            const Text('MODE DE RÈGLEMENT EFFECTUÉ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('ESPÈCES (CAISSE)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    selected: _paymentMode == PaymentMode.cash,
                    onSelected: (_) => setState(() => _paymentMode = PaymentMode.cash),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('BANQUE (MOMO)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    selected: _paymentMode == PaymentMode.bank,
                    onSelected: (_) => setState(() => _paymentMode = PaymentMode.bank),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Enregistrer & Sortir Espèces/Fonds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );

    final historyCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt_rounded, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grand Livre Trésorerie (Flux 571 / 521)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: treasuryLedger.isEmpty
                  ? Center(
                      child: Text('Aucun mouvement comptable.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    )
                  : ListView.builder(
                      itemCount: treasuryLedger.length,
                      itemBuilder: (context, idx) {
                        final item = treasuryLedger[idx];
                        final isDebit = item.type == 'Débit';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Compte: ${item.accountCode} (${item.accountName}) | ${item.paymentMode}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isDebit ? '+' : '-'} ${_formatMoney(item.amount, '')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                    color: isDebit ? Colors.green : Colors.pink,
                                  ),
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
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: isMobile
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cashCard,
                  const SizedBox(height: 8),
                  bankCard,
                  const SizedBox(height: 16),
                  formCard,
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: historyCard,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cashCard),
                    const SizedBox(width: 16),
                    Expanded(child: bankCard),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(child: formCard),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: historyCard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
