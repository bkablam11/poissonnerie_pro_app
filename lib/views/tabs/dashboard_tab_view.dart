import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class DashboardTabView extends ConsumerWidget {
  final Function(int) onNavigate;

  const DashboardTabView({super.key, required this.onNavigate});

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  void _showDailyReportDialog(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';
    final now = DateTime.now();
    final todaySales = state.sales
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .toList();

    double totalCA = 0;
    double cashSales = 0;
    double bankSales = 0;
    double totalVolume = 0;
    final Map<String, double> itemQty = {};
    final Map<String, double> itemRevenue = {};
    final Map<String, String> itemNames = {};

    for (var s in todaySales) {
      totalCA += s.totalAmount;
      if (s.paymentMode == PaymentMode.cash) {
        cashSales += s.totalAmount;
      } else {
        bankSales += s.totalAmount;
      }
      for (var item in s.items) {
        totalVolume += item.quantityKg;
        itemQty[item.productId] =
            (itemQty[item.productId] ?? 0) + item.quantityKg;
        itemRevenue[item.productId] =
            (itemRevenue[item.productId] ?? 0) + item.subtotal;
        itemNames[item.productId] = item.productName;
      }
    }

    final sortedItems = itemQty.entries.toList()
      ..sort((a, b) =>
          (itemRevenue[b.key] ?? 0).compareTo(itemRevenue[a.key] ?? 0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Point Journalier de Caisse',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Date: ${now.day}/${now.month}/${now.year}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildReportRow(
                            'Tickets émis:', '${todaySales.length} reçu(s)'),
                        _buildReportRow('Volume Poisson:',
                            '${totalVolume.toStringAsFixed(1)} Pkts/Kg'),
                        const Divider(height: 12),
                        _buildReportRow('Espèces (571):',
                            _formatMoney(cashSales, currency)),
                        _buildReportRow(
                            'Banque (521):', _formatMoney(bankSales, currency)),
                        const Divider(height: 12),
                        _buildReportRow(
                            'TOTAL CA:', _formatMoney(totalCA, currency),
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DÉTAIL DES PRODUITS VENDUS AUJOURD\'HUI',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (sortedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Aucune vente enregistrée ce jour.',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 12)),
                    )
                  else
                    ...sortedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final e = entry.value;
                      final name = itemNames[e.key] ?? 'Inconnu';
                      final qty = e.value;
                      final rev = itemRevenue[e.key] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text('${idx + 1}. ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                            Text('${qty.toStringAsFixed(1)} Pkts',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(width: 8),
                            Text(_formatMoney(rev, currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B)),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Impression du Point Journalier envoyée !')),
                );
              },
              icon: const Icon(Icons.print_rounded,
                  size: 16, color: Colors.white),
              label: const Text('Imprimer Ticket',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBold ? Colors.black : Colors.grey.shade700)),
          Text(val,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: isBold ? const Color(0xFFFF6B6B) : Colors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // 1. Calculate Today's Sales
    final now = DateTime.now();
    final todaySales = state.sales
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day)
        .fold<double>(0.0, (sum, s) => sum + s.totalAmount);

    // 2. Calculate Stock Value
    final stockValue = state.products
        .fold<double>(0.0, (sum, p) => sum + (p.stockKg * p.purchasePrice));

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
      padding: EdgeInsets.all(
          MediaQuery.of(context).size.width >= 768 ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width >= 768 ? 24.0 : 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.settings["shopName"]} — ERP & POS',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width >= 768
                                ? 24
                                : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bienvenue sur votre espace de gestion commerciale maritime. Suivez vos stocks, ventes et flux financiers.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showDailyReportDialog(context, ref),
                    icon: const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 18),
                    label: const Text('Point Journalier',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // KPI Grid Layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 768 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                MediaQuery.of(context).size.width >= 768 ? 1.5 : 1.35,
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
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Low stock alert banner block
          if (lowStockProducts.isNotEmpty) ...[
            const Text(
              'ALERTES STOCK CRITIQUES',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                  letterSpacing: 1.1),
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
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Colors.pink),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  prod.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                    color: Colors.pink.shade100,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  prod.category.label,
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stock: ${prod.stockKg.toStringAsFixed(0)} Paquets',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Visual Analytics & Statistics Section
          const Text(
            'STATISTIQUES & ANALYTIQUES DU JOUR',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;

              // Compute Top 3 Selling Products
              final Map<String, double> productSalesQty = {};
              final Map<String, String> productNames = {};
              for (var sale in state.sales) {
                for (var item in sale.items) {
                  productSalesQty[item.productId] =
                      (productSalesQty[item.productId] ?? 0.0) +
                          item.quantityKg;
                  productNames[item.productId] = item.productName;
                }
              }
              final sortedProductSales = productSalesQty.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final topSellers = sortedProductSales.take(3).toList();

              // Compute Category Stock Weight distribution
              final Map<ProductCategory, double> categoryStock = {};
              double totalStockKg = 0.0;
              for (var cat in ProductCategory.values) {
                categoryStock[cat] = 0.0;
              }
              for (var p in state.products) {
                categoryStock[p.category] =
                    (categoryStock[p.category] ?? 0.0) + p.stockKg;
                totalStockKg += p.stockKg;
              }

              // Compute payment breakdown
              double cashSalesTotal = 0.0;
              double bankSalesTotal = 0.0;
              for (var sale in state.sales) {
                if (sale.paymentMode == PaymentMode.cash) {
                  cashSalesTotal += sale.totalAmount;
                } else {
                  bankSalesTotal += sale.totalAmount;
                }
              }
              final totalRevenue = cashSalesTotal + bankSalesTotal;

              final widgets = [
                // Card 1: Stock distribution by category
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pie_chart_rounded,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Répartition des Stocks',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        ...ProductCategory.values.map((cat) {
                          final stock = categoryStock[cat] ?? 0.0;
                          final double pct =
                              totalStockKg > 0 ? (stock / totalStockKg) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${stock.toStringAsFixed(1)} Pkts (${(pct * 100).toStringAsFixed(0)}%)',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: Colors.grey.shade100,
                                    color: cat == ProductCategory.poissonFrais
                                        ? const Color(0xFFFF6B6B)
                                        : cat == ProductCategory.poissonCongele
                                            ? Colors.blue.shade400
                                            : cat == ProductCategory.crustaces
                                                ? Colors.orange.shade400
                                                : cat ==
                                                        ProductCategory
                                                            .coquillages
                                                    ? Colors.purple.shade300
                                                    : Colors.blueGrey.shade400,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Card 2: Top Selling & Payment distribution
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Top 3 Ventes & Règlements',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Text(
                          'PRODUITS LES PLUS VENDUS (PKTS)',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        if (topSellers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: Text(
                                'Aucune vente enregistrée aujourd\'hui.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          )
                        else
                          ...topSellers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final name = productNames[item.key] ?? 'Inconnu';
                            final qty = item.value;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: idx == 0
                                        ? Colors.amber.shade100
                                        : idx == 1
                                            ? Colors.grey.shade200
                                            : Colors.orange.shade100,
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: idx == 0
                                            ? Colors.amber.shade900
                                            : idx == 1
                                                ? Colors.grey.shade800
                                                : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${qty.toStringAsFixed(1)} Paquets',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        const SizedBox(height: 16),
                        const Text(
                          'FLUX DE CAISSE (RÈGLEMENTS)',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Espèces (571) : ${_formatMoney(cashSalesTotal, currency)}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Banque (521) : ${_formatMoney(bankSalesTotal, currency)}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 10,
                            color: Colors.grey.shade100,
                            child: Row(
                              children: [
                                if (totalRevenue > 0) ...[
                                  Expanded(
                                    flex: (cashSalesTotal / totalRevenue * 100)
                                        .round(),
                                    child: Container(
                                        color: const Color(0xFFFF6B6B)),
                                  ),
                                  Expanded(
                                    flex: (bankSalesTotal / totalRevenue * 100)
                                        .round(),
                                    child: Container(color: Colors.green),
                                  ),
                                ] else
                                  Expanded(
                                    child:
                                        Container(color: Colors.grey.shade300),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: widgets[0]),
                    const SizedBox(width: 16),
                    Expanded(
                        child: widgets[2]
                            as Widget), // Card 2 is at index 2 in raw widgets list with the SizedBox
                  ],
                );
              } else {
                return Column(
                  children: [
                    widgets[0],
                    const SizedBox(height: 12),
                    widgets[2],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Quick Navigation Actions Shortcut Panel
          const Text(
            'RACCOURCIS ACTIONS RAPIDES',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1),
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

  Widget _buildKpiCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: color),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A4B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
