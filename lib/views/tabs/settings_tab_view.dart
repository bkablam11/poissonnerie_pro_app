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
  late TextEditingController _supabaseUrlController;
  late TextEditingController _supabaseAnonKeyController;
  String _selectedInspectKey = 'products';
  final ScrollController _jsonScrollController = ScrollController();

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
    _supabaseUrlController.dispose();
    _supabaseAnonKeyController.dispose();
    _jsonScrollController.dispose();
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
      'supabaseUrl': _supabaseUrlController.text.trim(),
      'supabaseAnonKey': _supabaseAnonKeyController.text.trim(),
    };

    ref.read(shopViewModelProvider.notifier).updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences de la poissonnerie enregistrées avec succès!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final formCard = Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.storefront_rounded, color: Color(0xFFFF6B6B), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profil de la Poissonnerie & Préférences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B)),
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
                          const Text('NOM DE L’ÉTABLISSEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _shopNameController,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
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
                    ],
                  )
                : Row(
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
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
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
                      const SizedBox(height: 16),
                      Column(
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
                    ],
                  )
                : Row(
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
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
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
                      const SizedBox(height: 16),
                      Column(
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
                    ],
                  )
                : Row(
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.cloud_sync_rounded, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Configuration Supabase (Base Centrale)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
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
                const Text('SUPABASE PROJECT URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _supabaseUrlController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'https://xyz.supabase.co',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SUPABASE ANON KEY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _supabaseAnonKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
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
                  child: Text('Queue locale hors-ligne:', style: TextStyle(fontSize: 12)),
                ),
                Text(
                  '${state.pendingCount} transactions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('État du serveur Cloud:', style: TextStyle(fontSize: 12)),
                ),
                Text(
                  state.isOnline 
                      ? ((state.settings['supabaseUrl'] ?? '').isNotEmpty ? 'SUPABASE CONNECTÉ' : 'CONNECTÉ (MOCK)') 
                      : 'HORS-LIGNE',
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
        final dateStr = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
        final debit = entry.type == 'Débit' ? entry.amount.toStringAsFixed(0) : '0';
        final credit = entry.type == 'Crédit' ? entry.amount.toStringAsFixed(0) : '0';
        buffer.writeln('$dateStr;${entry.accountCode};"${entry.label.replaceAll('"', '""')}";$debit;$credit;"${entry.id.replaceAll('"', '""')}"');
      }
      return buffer.toString();
    }

    String getSalesCsv() {
      final buffer = StringBuffer();
      buffer.writeln('Date;Numero Facture;Client;Mode de Reglement;Montant Total;Articles');
      for (var s in state.sales) {
        final dateStr = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')} ${s.date.hour.toString().padLeft(2, '0')}:${s.date.minute.toString().padLeft(2, '0')}';
        final client = s.customerName ?? 'Client Anonyme';
        final payMode = s.paymentMode == PaymentMode.cash ? 'Espèces (571)' : 'Banque (521)';
        final articlesStr = s.items.map((it) => '${it.productName} (${it.quantityKg} Pkts x ${it.unitPrice})').join(' | ');
        buffer.writeln('$dateStr;${s.id};"$client";"$payMode";${s.totalAmount.toStringAsFixed(0)};"$articlesStr"');
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.table_rows_rounded, size: 14),
                    label: const Text('Export Compta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final csv = getLedgerCsv();
                      Clipboard.setData(ClipboardData(text: csv)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Grand Livre copié au format CSV ! Importez-le dans Excel.'),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_bag_rounded, size: 14),
                    label: const Text('Export Ventes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final csv = getSalesCsv();
                      Clipboard.setData(ClipboardData(text: csv)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registre des ventes copié au format CSV ! Importez-le dans Excel.'),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
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
                  buildInspectChip('products', '📦 Produits (${state.products.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('sales', '🧾 Ventes (${state.sales.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('purchases', '🚢 Appros (${state.purchases.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('losses', '📉 Pertes (${state.losses.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('contacts', '👥 Contacts (${state.contacts.length})'),
                  const SizedBox(width: 6),
                  buildInspectChip('ledger', '📖 Compta (${state.ledger.length})'),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copier JSON', style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: getRawJson())).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Données JSON copiées dans le presse-papier !')),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Localisation', style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.folder_open_rounded, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('Où sont stockées les données ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E3A4B)),
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
                dataInspectorCard,
                const SizedBox(height: 16),
                csvExportCard,
                const SizedBox(height: 16),
                dangerCard,
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
                      dataInspectorCard,
                      const SizedBox(height: 16),
                      csvExportCard,
                      const SizedBox(height: 16),
                      dangerCard,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
