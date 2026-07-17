import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class SettingsTabView extends ConsumerStatefulWidget {
  const SettingsTabView({super.key});

  @override
  ConsumerState<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends ConsumerState<SettingsTabView> {
  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _taxIdController;
  late TextEditingController _currencyController;
  late TextEditingController _vatRateController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(shopViewModelProvider);
    _shopNameController = TextEditingController(text: state.settings['shopName'] ?? 'Poissonnerie Pro');
    _addressController = TextEditingController(text: state.settings['address'] ?? '');
    _phoneController = TextEditingController(text: state.settings['phone'] ?? '');
    _taxIdController = TextEditingController(text: state.settings['taxId'] ?? '');
    _currencyController = TextEditingController(text: state.settings['currency'] ?? 'FCFA');
    _vatRateController = TextEditingController(text: state.settings['vatRate'] ?? '18');
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    _currencyController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final Map<String, String> newSettings = {
      'shopName': _shopNameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'taxId': _taxIdController.text.trim(),
      'currency': _currencyController.text.trim(),
      'vatRate': _vatRateController.text.trim(),
    };

    ref.read(shopViewModelProvider.notifier).updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences de la poissonnerie enregistrées avec succès!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column Profile Preferences Form
          Expanded(
            flex: 7,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: Color(0xFFFF6B6B), size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Profil de la Poissonnerie & Préférences',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Shop Name & Currency Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NOM DE L’ÉTABLISSEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _shopNameController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEVISE SYMBOLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _currencyController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone & TaxId
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TÉLÉPHONE CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _phoneController,
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
                              const Text('N° ID FISCAL (IFU)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _taxIdController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address & VAT
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ADRESSE PHYSIQUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TAUX TVA (%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _vatRateController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Enregistrer les Préférences du Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Right Column: Sync & Seed utility Card
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Synchronisation Engine card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sync_rounded, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Synchronisation & Sauvegardes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B))),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Queue locale hors-ligne:', style: TextStyle(fontSize: 12)),
                            Text(
                              '${state.pendingCount} transactions en attente',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('État du serveur Cloud:', style: TextStyle(fontSize: 12)),
                            Text(
                              state.isOnline ? 'CONNECTÉ' : 'HORS-LIGNE SIMULÉ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: state.isOnline ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: state.isSyncing
                              ? null
                              : () => ref.read(shopViewModelProvider.notifier).syncOfflineData(),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 16, color: Colors.white),
                          label: Text(
                            state.isSyncing ? 'Synchronisation...' : 'Forcer la Synchro Cloud',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            disabledBackgroundColor: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Database Seed & Reset utility card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.dangerous_rounded, color: Colors.pink, size: 20),
                            SizedBox(width: 8),
                            Text('Zone de Danger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B))),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          'En réinitialisant les données locales, vous écraserez tous les stocks actuels, toutes vos factures de ventes de poissons, ainsi que les journaux de caisse.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Confirmer la réinitialisation ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  content: const Text('Toutes les transactions saisies seront écrasées par les données de démonstration d’usine (seed).'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                                      onPressed: () {
                                        ref.read(shopViewModelProvider.notifier).resetToSeed();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base réinitialisée aux valeurs d’usine.')));
                                      },
                                      child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.pink),
                          label: const Text('Réinitialiser aux Valeurs d’Usine', style: TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.pink),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
