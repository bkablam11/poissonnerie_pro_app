import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class DashboardTabView extends ConsumerWidget {
  final Function(int) onNavigate;

  const DashboardTabView({super.key, required this.onNavigate});

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // 1. Calculate Today's Sales
    final now = DateTime.now();
    final todaySales = state.sales
        .where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day)
        .fold<double>(0.0, (sum, s) => sum + s.totalAmount);

    // 2. Calculate Stock Value
    final stockValue = state.products.fold<double>(0.0, (sum, p) => sum + (p.stockKg * p.purchasePrice));

    // 3. Calculate 7-Day Losses
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weeklyLosses = state.losses
        .where((l) => l.date.isAfter(sevenDaysAgo))
        .fold<double>(0.0, (sum, l) => sum + l.totalLossValue);

    // 4. Calculate Treasury Balance
    // Start with starting ledger state
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
    final totalTreasury = (cashDebit - cashCredit) + (bankDebit - bankCredit);

    // 5. Gather low-stock alerts
    final lowStockProducts = state.products.where((p) => p.isLowStock).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.settings['shopName']} — ERP & POS',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bienvenue sur votre espace de gestion commerciale maritime. Suivez vos stocks, ventes et flux financiers.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // KPI Grid Layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 768 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                context,
                title: 'VENTES DU JOUR',
                value: _formatMoney(todaySales, currency),
                icon: Icons.payments_rounded,
                color: const Color(0xFFFF6B6B),
              ),
              _buildKpiCard(
                context,
                title: 'VALEUR DU STOCK',
                value: _formatMoney(stockValue, currency),
                icon: Icons.inventory_2_rounded,
                color: Colors.blue,
              ),
              _buildKpiCard(
                context,
                title: 'PERTES (7 JOURS)',
                value: _formatMoney(weeklyLosses, currency),
                icon: Icons.delete_sweep_rounded,
                color: Colors.pink,
              ),
              _buildKpiCard(
                context,
                title: 'TRÉSORERIE DISPO',
                value: _formatMoney(totalTreasury, currency),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.emerald,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Low stock alert banner block
          if (lowStockProducts.isNotEmpty) ...[
            const Text(
              'ALERTES STOCK CRITIQUES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade100, width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: lowStockProducts.map((prod) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.pink),
                            const SizedBox(width: 8),
                            Text(
                              prod.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, py: 1),
                              decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                prod.category.label,
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.pink),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Stock: ${prod.stockKg.toStringAsFixed(1)} kg (Seuil: ${prod.minThresholdKg.toStringAsFixed(1)} kg)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Navigation Actions Shortcut Panel
          const Text(
            'RACCOURCIS ACTIONS RAPIDES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildShortcutButton(
                context,
                label: 'POS Vente',
                icon: Icons.add_shopping_cart,
                color: const Color(0xFFFF6B6B),
                onTap: () => onNavigate(1),
              ),
              const SizedBox(width: 12),
              _buildShortcutButton(
                context,
                label: 'Arrivage Poisson',
                icon: Icons.local_shipping_rounded,
                color: Colors.blue,
                onTap: () => onNavigate(3),
              ),
              const SizedBox(width: 12),
              _buildShortcutButton(
                context,
                label: 'Déclarer Perte',
                icon: Icons.delete_forever_rounded,
                color: Colors.pink,
                onTap: () => onNavigate(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.1,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E3A4B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
