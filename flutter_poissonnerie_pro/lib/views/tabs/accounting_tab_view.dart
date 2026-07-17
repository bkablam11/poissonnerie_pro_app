import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../home_screen.dart';

class AccountingTabView extends ConsumerWidget {
  const AccountingTabView({super.key});

  String _formatMoney(double amount, String currency) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    return '${amount < 0 ? '-' : ''}$formatted $currency';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // 1. Compile Balances for SYSCOHADA Accounts
    final Map<String, Map<String, dynamic>> accountBalances = {
      '101': {'name': 'Capital', 'debit': 0.0, 'credit': 0.0},
      '2182': {'name': 'Matériel d’équipement (assets)', 'debit': 0.0, 'credit': 0.0},
      '571': {'name': 'Caisse (Fonds Physiques)', 'debit': 0.0, 'credit': 0.0},
      '521': {'name': 'Banque & Mobile Money', 'debit': 0.0, 'credit': 0.0},
      '601': {'name': 'Achats de marchandises (poissons)', 'debit': 0.0, 'credit': 0.0},
      '65': {'name': 'Autres charges / Glace & Transport', 'debit': 0.0, 'credit': 0.0},
      '68': {'name': 'Charges exceptionnelles / Pertes', 'debit': 0.0, 'credit': 0.0},
      '701': {'name': 'Ventes de marchandises (CA)', 'debit': 0.0, 'credit': 0.0},
    };

    for (var entry in state.ledger) {
      final code = entry.accountCode;
      if (accountBalances.containsKey(code)) {
        if (entry.type == 'Débit') {
          accountBalances[code]!['debit'] = accountBalances[code]!['debit'] + entry.amount;
        } else {
          accountBalances[code]!['credit'] = accountBalances[code]!['credit'] + entry.amount;
        }
      }
    }

    // 2. Calculations for Intermediate Balances (SIG)
    final ca = accountBalances['701']!['credit'] - accountBalances['701']!['debit'];
    final achats = accountBalances['601']!['debit'] - accountBalances['601']!['credit'];
    final marge = ca - achats;
    final servicesExterieurs = accountBalances['65']!['debit'] - accountBalances['65']!['credit'];
    final valeurAjoutee = marge - servicesExterieurs;
    final pertes = accountBalances['68']!['debit'] - accountBalances['68']!['credit'];
    final resultatNet = valeurAjoutee - pertes;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SYSCOHADA Ledger accounts (Left)
          Expanded(
            flex: 6,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_rounded, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Plan de Comptes SYSCOHADA (Balance)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF2E3A4B))),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView(
                        children: accountBalances.entries.map((entry) {
                          final code = entry.key;
                          final data = entry.value;
                          final debit = data['debit'] as double;
                          final credit = data['credit'] as double;
                          double balance = 0.0;
                          String balType = 'Débiteur';

                          if (code == '101' || code == '701') {
                            balance = credit - debit;
                            balType = 'Créditeur';
                          } else {
                            balance = debit - credit;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$code — ${data['name']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Débit: ${_formatMoney(debit, '')} | Crédit: ${_formatMoney(credit, '')}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatMoney(balance, currency),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Courier'),
                                      ),
                                      Text(balType, style: TextStyle(fontSize: 8, color: balance >= 0 ? Colors.green : Colors.pink, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Soldes Intermédiaires de Gestion (SIG) (Right)
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
                        Icon(Icons.insights_rounded, color: Color(0xFFFF6B6B), size: 20),
                        SizedBox(width: 8),
                        Text('Soldes Intermédiaires de Gestion (SIG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF2E3A4B))),
                      ],
                    ),
                    const Divider(height: 24),

                    // SIG 1: CA
                    _buildSigItem(
                      title: 'CHIFFRE D’AFFAIRES BRUT (701)',
                      value: _formatMoney(ca, currency),
                      desc: 'Somme cumulée de toutes les factures de ventes POS.',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // SIG 2: Marge
                    _buildSigItem(
                      title: 'MARGE COMMERCIALE',
                      value: _formatMoney(marge, currency),
                      desc: 'Ventes de poissons moins coût d’achat d’approvisionnement.',
                      color: marge >= 0 ? Colors.green : Colors.pink,
                    ),
                    const SizedBox(height: 12),

                    // SIG 3: VA
                    _buildSigItem(
                      title: 'VALEUR AJOUTÉE (VA)',
                      value: _formatMoney(valeurAjoutee, currency),
                      desc: 'Marge commerciale restante après paiement de la glace, transport, eau, électricité.',
                      color: valeurAjoutee >= 0 ? Colors.teal : Colors.pink,
                    ),
                    const SizedBox(height: 12),

                    // SIG 4: Résultat Net
                    _buildSigItem(
                      title: 'RÉSULTAT NET COMPTABLE',
                      value: _formatMoney(resultatNet, currency),
                      desc: 'Solde final après déduction des pertes exceptionnelles de stock gâté.',
                      color: resultatNet >= 0 ? Colors.emerald : Colors.pink,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSigItem({required String title, required String value, required String desc, required Color color, bool isBold = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isBold ? color.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBold ? color.withOpacity(0.2) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.black, letterSpacing: 1.1, color: Color(0xFF2E3A4B)),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: color, fontFamily: 'Courier'),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
