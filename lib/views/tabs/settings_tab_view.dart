import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
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
  late TextEditingController _cashierPinController;
  late TextEditingController _managerPinController;
  late TextEditingController _adminPinController;
  late TextEditingController _supabaseUrlController;
  late TextEditingController _supabaseAnonKeyController;
  String _selectedInspectKey = 'products';
  final ScrollController _jsonScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(shopViewModelProvider);
    _shopNameController = TextEditingController(
        text: state.settings['shopName'] ?? 'Poissonnerie Pro');
    _addressController =
        TextEditingController(text: state.settings['address'] ?? '');
    _phoneController =
        TextEditingController(text: state.settings['phone'] ?? '');
    _taxIdController =
        TextEditingController(text: state.settings['taxId'] ?? '');
    _currencyController =
        TextEditingController(text: state.settings['currency'] ?? 'FCFA');
    _vatRateController =
        TextEditingController(text: state.settings['vatRate'] ?? '18');
    _cashierPinController =
        TextEditingController(text: state.settings['cashierPin'] ?? '1111');
    _managerPinController =
        TextEditingController(text: state.settings['managerPin'] ?? '6465');
    _adminPinController =
        TextEditingController(text: state.settings['adminPin'] ?? '1007');

    // Fallback on env values if settings are empty
    String initialUrl = state.settings['supabaseUrl'] ?? '';
    if (initialUrl.isEmpty) {
      initialUrl = dotenv.env['SUPABASE_URL'] ?? '';
      if (initialUrl == 'https://VOTRE_PROJET_ID.supabase.co') {
        initialUrl = '';
      }
    }
    _supabaseUrlController = TextEditingController(text: initialUrl);

    String initialAnonKey = state.settings['supabaseAnonKey'] ?? '';
    if (initialAnonKey.isEmpty) {
      initialAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (initialAnonKey == 'VOTRE_CLE_API_ANONYME') {
        initialAnonKey = '';
      }
    }
    _supabaseAnonKeyController = TextEditingController(text: initialAnonKey);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    _currencyController.dispose();
    _vatRateController.dispose();
    _cashierPinController.dispose();
    _managerPinController.dispose();
    _adminPinController.dispose();
    _supabaseUrlController.dispose();
    _supabaseAnonKeyController.dispose();
    _jsonScrollController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final cashierPin = _cashierPinController.text.trim();
    final managerPin = _managerPinController.text.trim();
    final adminPin = _adminPinController.text.trim();

    if (cashierPin.length != 4 || int.tryParse(cashierPin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Le code PIN Caissier doit être composé de 4 chiffres.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (managerPin.length != 4 || int.tryParse(managerPin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Le code PIN Gérant doit être composé de 4 chiffres.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (adminPin.length != 4 || int.tryParse(adminPin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Le code PIN Administrateur doit être composé de 4 chiffres.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final Map<String, String> newSettings = {
      'shopName': _shopNameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'taxId': _taxIdController.text.trim(),
      'currency': _currencyController.text.trim(),
      'vatRate': _vatRateController.text.trim(),
      'cashierPin': cashierPin,
      'managerPin': managerPin,
      'adminPin': adminPin,
      'supabaseUrl': _supabaseUrlController.text.trim(),
      'supabaseAnonKey': _supabaseAnonKeyController.text.trim(),
    };

    ref.read(shopViewModelProvider.notifier).updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Préférences et codes PIN de sécurité enregistrés avec succès!'),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final userRole = ref.watch(userRoleProvider);
    final isAdmin = userRole == UserRole.admin;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final formCard = Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.storefront_rounded,
                    color: Color(0xFFFF6B6B), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profil de la Poissonnerie & Préférences',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Shop Name & Currency Row
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NOM DE L’ÉTABLISSEMENT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _shopNameController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DEVISE SYMBOLE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
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
                            const Text('NOM DE L’ÉTABLISSEMENT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _shopNameController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
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
                            const Text('DEVISE SYMBOLE',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _currencyController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // Phone & TaxId
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TÉLÉPHONE CONTACT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('N° ID FISCAL (IFU)',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _taxIdController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TÉLÉPHONE CONTACT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('N° ID FISCAL (IFU)',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _taxIdController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // Address & VAT
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ADRESSE PHYSIQUE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TAUX TVA (%)',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _vatRateController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
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
                            const Text('ADRESSE PHYSIQUE',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
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
                            const Text('TAUX TVA (%)',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _vatRateController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.lock_person_rounded,
                    color: Color(0xFFFF6B6B), size: 20),
                SizedBox(width: 8),
                Text(
                  'Sécurité & Codes PIN d’Accès (4 chiffres)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2E3A4B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isAdmin) ...[
              const Text(
                'Définissez les codes PIN d’accès pour sécuriser l’application selon les 3 rôles d’utilisateurs.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CODE PIN CAISSIER',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _cashierPinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                counterText: '',
                                prefixIcon: Icon(Icons.pin, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CODE PIN GÉRANT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _managerPinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                counterText: '',
                                prefixIcon: Icon(Icons.badge_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CODE PIN ADMINISTRATEUR',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _adminPinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                counterText: '',
                                prefixIcon: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CODE PIN CAISSIER',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _cashierPinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  counterText: '',
                                  prefixIcon: Icon(Icons.pin, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CODE PIN GÉRANT',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _managerPinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  counterText: '',
                                  prefixIcon:
                                      Icon(Icons.badge_rounded, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CODE PIN ADMINISTRATEUR',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _adminPinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  counterText: '',
                                  prefixIcon: Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🔒 La modification des codes PIN d’accès (Caissier, Gérant, Administrateur) est réservée exclusivement à l’Administrateur.',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isAdmin) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Configuration Supabase (Base Centrale)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Renseignez vos identifiants de projet Supabase pour centraliser la base de données et synchroniser plusieurs poissonneries en temps réel.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUPABASE PROJECT URL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _supabaseUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'https://xyz.supabase.co',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUPABASE ANON KEY',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _supabaseAnonKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Enregistrer les Préférences du Profil',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
      ),
    );

    final syncCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.sync_rounded, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Synchronisation & Sauvegardes',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Queue locale hors-ligne:',
                      style: TextStyle(fontSize: 12)),
                ),
                Text(
                  '${state.pendingCount} transactions',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('État du serveur Cloud:',
                      style: TextStyle(fontSize: 12)),
                ),
                Text(
                  state.isOnline
                      ? ((state.settings['supabaseUrl'] ?? '').isNotEmpty
                          ? 'SUPABASE CONNECTÉ'
                          : 'CONNECTÉ (MOCK)')
                      : 'HORS-LIGNE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: state.isOnline ? Colors.green : Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: state.isSyncing
                  ? null
                  : () => ref
                      .read(shopViewModelProvider.notifier)
                      .syncOfflineData(),
              icon: const Icon(Icons.cloud_upload_rounded,
                  size: 16, color: Colors.white),
              label: Text(
                state.isSyncing
                    ? 'Synchronisation...'
                    : 'Forcer la Synchro Cloud',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    Widget buildInspectChip(String key, String label) {
      final isSelected = _selectedInspectKey == key;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFFF6B6B),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedInspectKey = key;
            });
          }
        },
      );
    }

    String getRawJson() {
      dynamic data;
      switch (_selectedInspectKey) {
        case 'products':
          data = state.products.map((e) => e.toMap()).toList();
          break;
        case 'sales':
          data = state.sales.map((e) => e.toMap()).toList();
          break;
        case 'purchases':
          data = state.purchases.map((e) => e.toMap()).toList();
          break;
        case 'losses':
          data = state.losses.map((e) => e.toMap()).toList();
          break;
        case 'contacts':
          data = state.contacts.map((e) => e.toMap()).toList();
          break;
        case 'ledger':
          data = state.ledger.map((e) => e.toMap()).toList();
          break;
        case 'settings':
          data = state.settings;
          break;
        default:
          data = {};
      }
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (e) {
        return "Erreur d'encodage : $e";
      }
    }

    String getLedgerCsv() {
      final buffer = StringBuffer();
      buffer.writeln('Date;Code Compte;Libelle;Debit;Credit;Reference');
      for (var entry in state.ledger) {
        final dateStr =
            '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
        final debit =
            entry.type == 'Débit' ? entry.amount.toStringAsFixed(0) : '0';
        final credit =
            entry.type == 'Crédit' ? entry.amount.toStringAsFixed(0) : '0';
        buffer.writeln(
            '$dateStr;${entry.accountCode};"${entry.label.replaceAll('"', '""')}";$debit;$credit;"${entry.id.replaceAll('"', '""')}"');
      }
      return buffer.toString();
    }

    String getSalesCsv() {
      final buffer = StringBuffer();
      buffer.writeln(
          'Date;Numero Facture;Client;Mode de Reglement;Montant Total;Articles');
      for (var s in state.sales) {
        final dateStr =
            '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')} ${s.date.hour.toString().padLeft(2, '0')}:${s.date.minute.toString().padLeft(2, '0')}';
        final client = s.customerName ?? 'Client Anonyme';
        final payMode = s.paymentMode == PaymentMode.cash
            ? 'Espèces (571)'
            : 'Banque (521)';
        final articlesStr = s.items
            .map((it) =>
                '${it.productName} (${it.quantityKg} Pkts x ${it.unitPrice})')
            .join(' | ');
        buffer.writeln(
            '$dateStr;${s.id};"$client";"$payMode";${s.totalAmount.toStringAsFixed(0)};"$articlesStr"');
      }
      return buffer.toString();
    }

    final csvExportCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_on_rounded, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exportation Professionnelle (Excel / CSV)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Générez et copiez au format standard CSV (séparateur point-virgule) pour importer directement vos données comptables et de caisse dans Microsoft Excel, Google Sheets ou un logiciel tiers.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.table_rows_rounded, size: 14),
                    label: const Text('Export Compta',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final csv = getLedgerCsv();
                      Clipboard.setData(ClipboardData(text: csv)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Grand Livre copié au format CSV ! Importez-le dans Excel.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_bag_rounded, size: 14),
                    label: const Text('Export Ventes',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final csv = getSalesCsv();
                      Clipboard.setData(ClipboardData(text: csv)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Registre des ventes copié au format CSV ! Importez-le dans Excel.'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final dataInspectorCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.storage_rounded, color: Color(0xFFFF6B6B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visualiseur de Base de Données',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Inspectez en temps réel le contenu des fichiers physiques SharedPreferences sauvegardés localement sur cet appareil.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Chips row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildInspectChip(
                      'products', '📦 Produits (${state.products.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip(
                      'sales', '🧾 Ventes (${state.sales.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip(
                      'purchases', '🚢 Appros (${state.purchases.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip(
                      'losses', '📉 Pertes (${state.losses.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip(
                      'contacts', '👥 Contacts (${state.contacts.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip(
                      'ledger', '📖 Compta (${state.ledger.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('settings', '⚙️ Paramètres'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // JSON Output Container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Slate 900
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.shade800),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Scrollbar(
                  controller: _jsonScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _jsonScrollController,
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        getRawJson(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: Color(0xFF38BDF8), // Light Blue
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copier JSON',
                        style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: getRawJson()))
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Données JSON copiées dans le presse-papier !')),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Localisation',
                        style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('Où sont stockées les données ?',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: const Text(
                              'Ce système utilise SharedPreferences (persistance physique locale) :\n\n'
                              '• Android : Enregistré au format XML dans le répertoire interne de l\'application :\n'
                              '  /data/data/com.example.flutter_poissonnerie_pro/shared_prefs/flutter_poissonnerie_pro.xml\n\n'
                              '• iOS : Enregistré au format Plist dans le dossier d\'application :\n'
                              '  Library/Preferences/com.example.flutter-poissonnerie-pro.plist\n\n'
                              '• Web : Stocké directement dans le LocalStorage du navigateur.\n\n'
                              'Ces données persistent même si vous fermez l\'application ou redémarrez votre appareil.',
                              style: TextStyle(fontSize: 11, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final csvImportCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.file_upload_rounded,
                    color: Color(0xFFFF6B6B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Importation de Données (CSV / Excel)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Chargez ou mettez à jour votre base de données à tout moment en important un fichier CSV ou du texte copié depuis Excel (Catalogue de produits ou liste de contacts).',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Ouvrir l’Assistant d’Importation CSV',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const _CsvImportDialog(),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Modèle Produits CSV',
                        style: TextStyle(fontSize: 10.5)),
                    onPressed: () {
                      const sampleProductsCsv =
                          'Nom;Categorie;StockKg;PrixAchat;PrixVente;SeuilAlerte\n'
                          'Capitaine Frais;poissonFrais;50.0;2500;3500;10.0\n'
                          'Thon Congelé (Carton);poissonCongele;120.0;1200;1800;20.0\n'
                          'Crevettes Rose;crustaces;30.0;4000;6000;5.0\n'
                          'Moules de Mer;coquillages;15.0;3000;4500;3.0\n'
                          'Sardines en Boîte;divers;80.0;500;800;15.0';
                      Clipboard.setData(
                              const ClipboardData(text: sampleProductsCsv))
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Exemple de structure CSV Produits copié dans le presse-papier !'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Modèle Contacts CSV',
                        style: TextStyle(fontSize: 10.5)),
                    onPressed: () {
                      const sampleContactsCsv = 'Nom;Type;Telephone;Solde\n'
                          'Poissonnerie du Port;fournisseur;+225 0701020304;0.0\n'
                          'Hôtel Le Lagon;client;+225 0504030201;25000.0\n'
                          'Mme Kouassi;client;+225 0102030405;0.0\n'
                          'Gros Pêcheur Abidjan;fournisseur;+225 0708091011;-50000.0';
                      Clipboard.setData(
                              const ClipboardData(text: sampleContactsCsv))
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Exemple de structure CSV Contacts copié dans le presse-papier !'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final dangerCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.dangerous_rounded, color: Colors.pink, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zone de Danger',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2E3A4B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      title: const Text('Confirmer la réinitialisation ?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      content: const Text(
                          'Toutes les transactions saisies seront écrasées par les données de démonstration d’usine (seed).'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink),
                          onPressed: () {
                            ref
                                .read(shopViewModelProvider.notifier)
                                .resetToSeed();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Base réinitialisée aux valeurs d’usine.')));
                          },
                          child: const Text('Confirmer',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.delete_forever_rounded,
                  size: 16, color: Colors.pink),
              label: const Text('Réinitialiser aux Valeurs d’Usine',
                  style: TextStyle(
                      color: Colors.pink,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.pink),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                formCard,
                const SizedBox(height: 16),
                syncCard,
                const SizedBox(height: 16),
                csvExportCard,
                const SizedBox(height: 16),
                csvImportCard,
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  dataInspectorCard,
                  const SizedBox(height: 16),
                  dangerCard,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: formCard,
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      syncCard,
                      const SizedBox(height: 16),
                      csvExportCard,
                      const SizedBox(height: 16),
                      csvImportCard,
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        dataInspectorCard,
                        const SizedBox(height: 16),
                        dangerCard,
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CsvImportDialog extends ConsumerStatefulWidget {
  const _CsvImportDialog();

  @override
  ConsumerState<_CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends ConsumerState<_CsvImportDialog> {
  String _targetType = 'products'; // 'products' or 'contacts'
  bool _overwrite = false; // false = Merge/Update, true = Overwrite
  final TextEditingController _csvController = TextEditingController();

  List<Product> _parsedProducts = [];
  List<Contact> _parsedContacts = [];
  String? _parseErrorMessage;
  bool _hasAnalyzed = false;

  static const String _sampleProductsCsv =
      'Nom;Categorie;StockKg;PrixAchat;PrixVente;SeuilAlerte\n'
      'Capitaine Frais;poissonFrais;50.0;2500;3500;10.0\n'
      'Thon Congelé (Carton);poissonCongele;120.0;1200;1800;20.0\n'
      'Crevettes Rose;crustaces;30.0;4000;6000;5.0\n'
      'Moules de Mer;coquillages;15.0;3000;4500;3.0\n'
      'Sardines en Boîte;divers;80.0;500;800;15.0';

  static const String _sampleContactsCsv = 'Nom;Type;Telephone;Solde\n'
      'Poissonnerie du Port;fournisseur;+225 0701020304;0.0\n'
      'Hôtel Le Lagon;client;+225 0504030201;25000.0\n'
      'Mme Kouassi;client;+225 0102030405;0.0\n'
      'Gros Pêcheur Abidjan;fournisseur;+225 0708091011;-50000.0';

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  ProductCategory _parseCategory(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.contains('frais')) return ProductCategory.poissonFrais;
    if (clean.contains('congel') ||
        clean.contains('paquet') ||
        clean.contains('carton')) return ProductCategory.poissonCongele;
    if (clean.contains('crustac') ||
        clean.contains('crevette') ||
        clean.contains('homard')) return ProductCategory.crustaces;
    if (clean.contains('coquill') ||
        clean.contains('moule') ||
        clean.contains('huitre')) return ProductCategory.coquillages;
    return ProductCategory.divers;
  }

  ContactType _parseContactType(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.contains('fournis') ||
        clean.contains('supplier') ||
        clean.contains('grossiste')) {
      return ContactType.fournisseur;
    }
    return ContactType.client;
  }

  void _analyzeCsv() {
    final text = _csvController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parseErrorMessage = 'Veuillez coller ou saisir du contenu CSV.';
        _hasAnalyzed = false;
        _parsedProducts = [];
        _parsedContacts = [];
      });
      return;
    }

    final lines = text.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      setState(() {
        _parseErrorMessage = 'Aucune ligne détectée dans le texte.';
        _hasAnalyzed = false;
      });
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    if (_targetType == 'products') {
      final List<Product> products = [];
      int startIndex = 0;

      // Check header row
      final firstLine = lines.first.toLowerCase();
      if (firstLine.contains('nom') ||
          firstLine.contains('categorie') ||
          firstLine.contains('prix')) {
        startIndex = 1; // Skip header
      }

      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final delimiter = line.contains(';') ? ';' : ',';
        final parts = line.split(delimiter);
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          final name = parts[0].trim().replaceAll('"', '');
          final catRaw = parts.length > 1
              ? parts[1].trim().replaceAll('"', '')
              : 'poissonCongele';
          final stockKg = parts.length > 2
              ? (double.tryParse(parts[2].trim().replaceAll('"', '')) ?? 0.0)
              : 0.0;
          final purchasePrice = parts.length > 3
              ? (double.tryParse(parts[3].trim().replaceAll('"', '')) ?? 0.0)
              : 0.0;
          final sellingPrice = parts.length > 4
              ? (double.tryParse(parts[4].trim().replaceAll('"', '')) ?? 0.0)
              : 0.0;
          final minThreshold = parts.length > 5
              ? (double.tryParse(parts[5].trim().replaceAll('"', '')) ?? 5.0)
              : 5.0;

          products.add(
            Product(
              id: 'prod-csv-$now-$i',
              name: name,
              category: _parseCategory(catRaw),
              stockKg: stockKg,
              purchasePrice: purchasePrice,
              sellingPrice: sellingPrice,
              minThresholdKg: minThreshold,
            ),
          );
        }
      }

      setState(() {
        _parsedProducts = products;
        _parsedContacts = [];
        _hasAnalyzed = true;
        _parseErrorMessage = products.isEmpty
            ? 'Aucun produit valide trouvé dans ce CSV.'
            : null;
      });
    } else {
      final List<Contact> contacts = [];
      int startIndex = 0;

      final firstLine = lines.first.toLowerCase();
      if (firstLine.contains('nom') ||
          firstLine.contains('type') ||
          firstLine.contains('telephone')) {
        startIndex = 1;
      }

      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final delimiter = line.contains(';') ? ';' : ',';
        final parts = line.split(delimiter);
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          final name = parts[0].trim().replaceAll('"', '');
          final typeRaw =
              parts.length > 1 ? parts[1].trim().replaceAll('"', '') : 'client';
          final phone =
              parts.length > 2 ? parts[2].trim().replaceAll('"', '') : '';
          final balance = parts.length > 3
              ? (double.tryParse(parts[3].trim().replaceAll('"', '')) ?? 0.0)
              : 0.0;

          contacts.add(
            Contact(
              id: 'contact-csv-$now-$i',
              name: name,
              phone: phone,
              type: _parseContactType(typeRaw),
              balance: balance,
            ),
          );
        }
      }

      setState(() {
        _parsedContacts = contacts;
        _parsedProducts = [];
        _hasAnalyzed = true;
        _parseErrorMessage = contacts.isEmpty
            ? 'Aucun contact valide trouvé dans ce CSV.'
            : null;
      });
    }
  }

  void _confirmImport() {
    final notifier = ref.read(shopViewModelProvider.notifier);

    if (_targetType == 'products') {
      if (_parsedProducts.isEmpty) return;
      notifier.importProducts(_parsedProducts, overwrite: _overwrite);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_parsedProducts.length} produits importés avec succès dans le catalogue !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (_parsedContacts.isEmpty) return;
      notifier.importContacts(_parsedContacts, overwrite: _overwrite);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${_parsedContacts.length} contacts importés avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _targetType == 'products'
        ? _parsedProducts.length
        : _parsedContacts.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_upload_rounded,
                        color: Color(0xFFFF6B6B), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assistant d’Importation CSV',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E3A4B))),
                        Text(
                            'Chargez votre catalogue ou vos contacts en un clic',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Target Selection
              const Text('1. TYPE DE DONNÉES À IMPORTER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _targetType == 'products',
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.set_meal_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Catalogue Produits',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selectedColor: const Color(0xFFFF6B6B),
                      labelStyle: TextStyle(
                          color: _targetType == 'products'
                              ? Colors.white
                              : Colors.black87),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _targetType = 'products';
                            _hasAnalyzed = false;
                            _parsedProducts = [];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      selected: _targetType == 'contacts',
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Contacts (Clients/Grossistes)',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selectedColor: const Color(0xFFFF6B6B),
                      labelStyle: TextStyle(
                          color: _targetType == 'contacts'
                              ? Colors.white
                              : Colors.black87),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _targetType = 'contacts';
                            _hasAnalyzed = false;
                            _parsedContacts = [];
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode Selection
              const Text('2. MODE D’IMPORTATION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        value: false,
                        groupValue: _overwrite,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fusionner / Mettre à jour',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                            'Conserve l’existant et met à jour selon les noms',
                            style:
                                TextStyle(fontSize: 9.5, color: Colors.grey)),
                        onChanged: (val) {
                          if (val != null) setState(() => _overwrite = val);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        value: true,
                        groupValue: _overwrite,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remplacer la liste',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        subtitle: const Text(
                            'Écrase entièrement la liste actuelle',
                            style:
                                TextStyle(fontSize: 9.5, color: Colors.grey)),
                        onChanged: (val) {
                          if (val != null) setState(() => _overwrite = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Header specification & Paste Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _targetType == 'products'
                        ? '3. SAISIE / COLLAGE DU TEXTE CSV (Séparateur ; ou ,)'
                        : '3. SAISIE / COLLAGE DU TEXTE CSV (Séparateur ; ou ,)',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.content_paste_rounded, size: 14),
                    label: const Text('Charger Exemple',
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        _csvController.text = _targetType == 'products'
                            ? _sampleProductsCsv
                            : _sampleContactsCsv;
                        _hasAnalyzed = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Format hint box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _targetType == 'products'
                      ? 'Format requis : Nom;Categorie;StockKg;PrixAchat;PrixVente;SeuilAlerte\n'
                          'Catégories reconnues : poissonFrais, poissonCongele, crustaces, coquillages, divers'
                      : 'Format requis : Nom;Type;Telephone;Solde\n'
                          'Types reconnus : client, fournisseur',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade900,
                      fontFamily: 'monospace',
                      height: 1.3),
                ),
              ),
              const SizedBox(height: 10),

              // Multi-line TextField
              TextField(
                controller: _csvController,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  hintText: _targetType == 'products'
                      ? 'Exemple :\nNom;Categorie;StockKg;PrixAchat;PrixVente;SeuilAlerte\nCapitaine Frais;poissonFrais;50;2500;3500;10\nThon Congelé;poissonCongele;120;1200;1800;20'
                      : 'Exemple :\nNom;Type;Telephone;Solde\nPoissonnerie du Port;fournisseur;+225 0701020304;0\nHôtel Le Lagon;client;+225 0504030201;25000',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) {
                  if (_hasAnalyzed) {
                    setState(() => _hasAnalyzed = false);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Action buttons: Analyse
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text('Analyser & Prévisualiser',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _analyzeCsv,
                    ),
                  ),
                ],
              ),

              if (_parseErrorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_parseErrorMessage!,
                      style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],

              // Analysis Result Preview Table
              if (_hasAnalyzed && count > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$count ${_targetType == 'products' ? 'produit(s)' : 'contact(s)'} prêt(s) à être importé(s) !',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(
                                color: Colors.green.shade200, width: 0.5),
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: Colors.green.shade100),
                                children: _targetType == 'products'
                                    ? const [
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Nom',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Catégorie',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Stock (Kg)',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Prix Vente',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                      ]
                                    : const [
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Nom',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Type',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Téléphone',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                        Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Text('Solde',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10))),
                                      ],
                              ),
                              if (_targetType == 'products')
                                ..._parsedProducts.map(
                                  (p) => TableRow(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(p.category.name,
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text('${p.stockKg} kg',
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                              '${p.sellingPrice.toStringAsFixed(0)} FCFA',
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                    ],
                                  ),
                                )
                              else
                                ..._parsedContacts.map(
                                  (c) => TableRow(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(c.name,
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(c.type.name,
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(c.phone,
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                      Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                              '${c.balance.toStringAsFixed(0)} FCFA',
                                              style: const TextStyle(
                                                  fontSize: 10))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Confirm button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAnalyzed && count > 0
                      ? Colors.green.shade600
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.file_download_done_rounded, size: 18),
                label: Text(
                  _hasAnalyzed && count > 0
                      ? 'Confirmer l’Importation ($count éléments)'
                      : 'Analyser d’abord les données',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed:
                    _hasAnalyzed && count > 0 ? _confirmImport : _analyzeCsv,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
