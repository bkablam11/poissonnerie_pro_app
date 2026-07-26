import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/shop_view_model.dart';
import 'pin_login_screen.dart';

// Import our tabs
import 'tabs/dashboard_tab_view.dart';
import 'tabs/pos_tab_view.dart';
import 'tabs/stock_tab_view.dart';
import 'tabs/purchases_tab_view.dart';
import 'tabs/losses_tab_view.dart';
import 'tabs/cash_tab_view.dart';
import 'tabs/accounting_tab_view.dart';
import 'tabs/contacts_tab_view.dart';
import 'tabs/settings_tab_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _activeTabIdx = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Tableau de Bord', 'icon': Icons.dashboard_rounded},
    {'label': 'Caisse / POS', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Gestion de Stock', 'icon': Icons.inventory_2_rounded},
    {'label': 'Arrivages / Achats', 'icon': Icons.local_shipping_rounded},
    {'label': 'Gestion des Pertes', 'icon': Icons.delete_sweep_rounded},
    {'label': 'Caisse & Dépenses', 'icon': Icons.account_balance_wallet_rounded},
    {'label': 'Compta SYSCOHADA', 'icon': Icons.menu_book_rounded},
    {'label': 'Contacts', 'icon': Icons.people_alt_rounded},
    {'label': 'Paramètres', 'icon': Icons.settings_suggest_rounded},
  ];

  Widget _buildActiveTab(int index) {
    switch (index) {
      case 0:
        return DashboardTabView(onNavigate: (idx) => setState(() => _activeTabIdx = idx));
      case 1:
        return PosTabView(onNavigate: (idx) => setState(() => _activeTabIdx = idx));
      case 2:
        return const StockTabView();
      case 3:
        return PurchasesTabView(onNavigate: (idx) => setState(() => _activeTabIdx = idx));
      case 4:
        return LossesTabView(onNavigate: (idx) => setState(() => _activeTabIdx = idx));
      case 5:
        return const CashTabView();
      case 6:
        return const AccountingTabView();
      case 7:
        return const ContactsTabView();
      case 8:
        return const SettingsTabView();
      default:
        return DashboardTabView(onNavigate: (idx) => setState(() => _activeTabIdx = idx));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopViewModelProvider);
    final activeRole = ref.watch(userRoleProvider);

    if (activeRole == UserRole.none) {
      return PinLoginScreen(
        onLoginSuccess: (role) {
          setState(() {
            _activeTabIdx = (role == UserRole.cashier) ? 1 : 0;
          });
          ref.read(userRoleProvider.notifier).state = role;
        },
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar for Desktop
          if (isDesktop)
            Container(
              width: 260,
              color: const Color(0xFF2E3A4B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'P',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopState.settings['shopName'] ?? 'Poissonnerie Pro',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                'ERP MARITIME',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 1),

                  // Tab Buttons
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      itemCount: _tabs.length,
                      itemBuilder: (context, idx) {
                        final isActive = _activeTabIdx == idx;
                        final tab = _tabs[idx];
                        final isLockedForCashier = activeRole == UserRole.cashier && idx != 1 && idx != 4;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: InkWell(
                            onTap: () {
                              if (isLockedForCashier) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔒 Section réservée au Gérant (PIN requis).'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setState(() => _activeTabIdx = idx);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFFF6B6B) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLockedForCashier ? Icons.lock_outline : tab['icon'],
                                      size: 20,
                                      color: isLockedForCashier
                                          ? Colors.white30
                                          : (isActive ? Colors.white : Colors.white54),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        tab['label'],
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isLockedForCashier
                                              ? Colors.white30
                                              : (isActive ? Colors.white : Colors.white70),
                                        ),
                                      ),
                                    ),
                                    if (isLockedForCashier)
                                      const Icon(Icons.lock, size: 12, color: Colors.white24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 1),

                  // Sidebar Footer
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                              child: Text(
                                activeRole == UserRole.manager ? 'G' : 'C',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeRole == UserRole.manager ? 'Gérant' : 'Caissier',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Connecté',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                ref.read(userRoleProvider.notifier).state = UserRole.none;
                              },
                              tooltip: 'Déconnexion',
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                              onPressed: () => ref.read(shopViewModelProvider.notifier).resetToSeed(),
                              tooltip: 'Réinitialiser les données',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main workspace Area
          Expanded(
            child: Column(
              children: [
                // Top Custom Header
                Container(
                  height: 64,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (!isDesktop)
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu_rounded),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          Text(
                            _tabs[_activeTabIdx]['label'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sync Status Badge
                          if (shopState.pendingCount == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 10, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDesktop ? '✓ Sync OK' : 'Sync',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 8,
                                    height: 8,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDesktop ? '${shopState.pendingCount} En Attente' : '${shopState.pendingCount}',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Right Header action elements
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref.read(shopViewModelProvider.notifier).toggleOnlineStatus(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: shopState.isOnline ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isDesktop
                                    ? (shopState.isOnline ? 'En Ligne (Wifi)' : 'Hors-Ligne (Simulé)')
                                    : (shopState.isOnline ? 'Wifi' : 'Hors-L.'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: shopState.isOnline ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          if (isDesktop && _activeTabIdx != 1) ...[
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _activeTabIdx = 1),
                              icon: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                              label: const Text('Nouvelle Vente', style: TextStyle(fontSize: 11, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ] else if (!isDesktop && _activeTabIdx != 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, size: 18, color: Color(0xFFFF6B6B)),
                              onPressed: () => setState(() => _activeTabIdx = 1),
                              tooltip: 'Nouvelle Vente',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Core content area
                Expanded(
                  child: _buildActiveTab(_activeTabIdx),
                ),
              ],
            ),
          )
        ],
      ),

      // Mobile Drawer
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: const Color(0xFF2E3A4B),
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF1E293B)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Poissonnerie Pro',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mode : ${activeRole == UserRole.manager ? "Gérant" : "Caissier"}',
                            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tabs.length,
                      itemBuilder: (context, idx) {
                        final isActive = _activeTabIdx == idx;
                        final tab = _tabs[idx];
                        final isLockedForCashier = activeRole == UserRole.cashier && idx != 1 && idx != 4;

                        return ListTile(
                          leading: Icon(
                            isLockedForCashier ? Icons.lock_outline : tab['icon'],
                            color: isLockedForCashier
                                ? Colors.white30
                                : (isActive ? const Color(0xFFFF6B6B) : Colors.white70),
                          ),
                          trailing: isLockedForCashier
                              ? const Icon(Icons.lock, size: 14, color: Colors.white24)
                              : null,
                          title: Text(
                            tab['label'],
                            style: TextStyle(
                              color: isLockedForCashier
                                  ? Colors.white30
                                  : (isActive ? const Color(0xFFFF6B6B) : Colors.white),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            if (isLockedForCashier) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔒 Section réservée au Gérant (PIN requis).'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setState(() => _activeTabIdx = idx);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ref.read(userRoleProvider.notifier).state = UserRole.none;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
