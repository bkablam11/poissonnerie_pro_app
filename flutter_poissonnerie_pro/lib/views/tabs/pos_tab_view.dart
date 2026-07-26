import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';
import '../../data/repositories/shop_repository.dart';

class PosTabView extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const PosTabView({super.key, required this.onNavigate});

  @override
  ConsumerState<PosTabView> createState() => _PosTabViewState();
}

class _PosTabViewState extends ConsumerState<PosTabView> {
  final List<SaleItem> _cart = [];
  String? _selectedClientId;
  PaymentMode _paymentMode = PaymentMode.cash;
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  bool _showCartOnMobile = false;

  // Bluetooth printing state variables
  List<BluetoothInfo> _availablePrinters = [];
  bool _isConnected = false;
  String _printerMacAddress = "";

  // Receipt History and Outflow Tracking state variables
  bool _showHistory = false;
  String _historySearchQuery = '';
  PaymentMode? _historyPaymentFilter;
  Sale? _selectedHistorySale;

  @override
  void initState() {
    super.initState();
    _scanBluetoothPrinters();
  }

  // Scan paired Bluetooth printers
  Future<void> _scanBluetoothPrinters() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final int sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 31) {
          // Android 12+ (API 31+) requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
          final statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();

          final isScanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
          final isConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

          if (!isScanGranted || !isConnectGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Veuillez autoriser l'accès aux appareils à proximité dans les paramètres."),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        } else {
          // Android 11 and lower requires location and standard bluetooth permissions
          final statuses = await [
            Permission.bluetooth,
            Permission.location,
          ].request();

          final isLocationGranted = statuses[Permission.location]?.isGranted ?? false;

          if (!isLocationGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Veuillez autoriser l'accès à la localisation pour rechercher des imprimantes."),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
      }

      final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (isBluetoothEnabled) {
        final List<BluetoothInfo> printers = await PrintBluetoothThermal.pairedBluetooths;
        setState(() {
          _availablePrinters = printers;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Le Bluetooth est désactivé. Veuillez l'activer."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur de scan des imprimantes : $e");
    }
  }

  // Connect to thermal printer
  Future<void> _connectToPrinter(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
      setState(() {
        _isConnected = result;
        if (result) _printerMacAddress = macAddress;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? "Connecté à l'imprimante !" : "Échec de la connexion à l'imprimante"),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur de connexion : $e");
    }
  }

  String _sanitizeFrenchForPrinter(String text) {
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Ç', 'C')
        .replaceAll('’', "'")
        .replaceAll('°', ' ');
  }

  // Send raw layout to 80mm thermal printer
  Future<void> _printDirectly({
    required String shopName,
    required String address,
    required String phone,
    required String taxId,
    required String ticketNumber,
    required DateTime date,
    required String clientName,
    required List<SaleItem> items,
    required double total,
    required PaymentMode paymentMode,
    required double amountReceived,
    required double change,
    required String currency,
  }) async {
    if (!_isConnected) {
      if (_printerMacAddress.isNotEmpty) {
        await _connectToPrinter(_printerMacAddress);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez d'abord connecter votre imprimante Bluetooth")),
        );
        return;
      }
    }

    try {
      List<int> bytes = [];

      void addBytes(List<int> b) => bytes.addAll(b);
      void addText(String text) {
        final sanitized = _sanitizeFrenchForPrinter(text);
        addBytes(utf8.encode(sanitized));
      }
      void addTextLine(String text) {
        addText(text + '\n');
      }

      // Initialize printer
      addBytes([27, 64]);

      // Header shopName (Double Width & Height, Centered, Bold)
      addBytes([27, 97, 1]); // Align Center
      addBytes([29, 33, 17]); // Double size
      addBytes([27, 69, 1]); // Bold On
      addTextLine(shopName.toUpperCase());
      addBytes([29, 33, 0]); // Reset size
      addBytes([27, 69, 0]); // Bold Off

      // Shop Metadata
      if (address.isNotEmpty) addTextLine(address);
      if (phone.isNotEmpty) addTextLine('Tel: $phone');
      if (taxId.isNotEmpty) addTextLine('IFU: $taxId');
      addTextLine('=' * 40);

      // Ticket Metadata (Left Align)
      addBytes([27, 97, 0]); // Align Left
      String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      addTextLine('TICKET NO: $ticketNumber');
      addTextLine('DATE:      $dateStr');
      addTextLine('CLIENT:    $clientName');
      addTextLine('REGLEMENT: ${paymentMode == PaymentMode.cash ? "ESPECES (571)" : "BANQUE (521)"}');
      addTextLine('-' * 40);

      // Table Header (Bold)
      addBytes([27, 69, 1]); // Bold On
      addTextLine('PRODUIT             QTE   P.U   TOTAL');
      addBytes([27, 69, 0]); // Bold Off
      addTextLine('-' * 40);

      // Table Body
      for (var item in items) {
        String name = item.productName;
        if (name.length > 18) {
          name = name.substring(0, 18);
        }
        String qty = item.quantityKg.toStringAsFixed(1);
        String pu = item.unitPrice.toStringAsFixed(0);
        String totalStr = item.subtotal.toStringAsFixed(0);

        String line = name.padRight(19) + qty.padRight(5) + pu.padRight(6) + totalStr.padLeft(10);
        addTextLine(line);
      }
      addTextLine('-' * 40);

      // Total Section (Bold)
      addBytes([27, 69, 1]); // Bold On
      String totalLabel = 'TOTAL A PAYER:';
      String totalVal = '${total.toStringAsFixed(0)} $currency';
      int spaces = 40 - totalLabel.length - totalVal.length;
      addTextLine(totalLabel + (' ' * (spaces > 0 ? spaces : 1)) + totalVal);
      addBytes([27, 69, 0]); // Bold Off

      // Monnaie rendering details
      if (amountReceived > total) {
        String labelEnc = 'MONTANT ENCAISSE:';
        String valEnc = '${amountReceived.toStringAsFixed(0)} $currency';
        int sp1 = 40 - labelEnc.length - valEnc.length;
        addTextLine(labelEnc + (' ' * (sp1 > 0 ? sp1 : 1)) + valEnc);

        String labelMon = 'MONNAIE RENDUE:';
        String valMon = '${change.toStringAsFixed(0)} $currency';
        int sp2 = 40 - labelMon.length - valMon.length;
        addTextLine(labelMon + (' ' * (sp2 > 0 ? sp2 : 1)) + valMon);
      }
      addTextLine('=' * 40);

      // Footer
      addBytes([27, 97, 1]); // Align Center
      addTextLine('Merci de votre confiance !');
      addTextLine('Les poissons vendus ne sont ni');
      addTextLine('repris ni echanges.');
      addTextLine('=' * 40);

      // Feed paper and cut (Standard ESC/POS: GS V 66 0)
      addTextLine('\n\n\n\n');
      addBytes([29, 86, 66, 0]); // Cut command

      // Print via raw bytes code units
      bool printStatus = await PrintBluetoothThermal.writeBytes(bytes);
      if (printStatus) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ticket imprimé avec succès !"), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur d'impression physique, vérifiez l'imprimante."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de l'impression : $e");
    }
  }

  String _formatMoney(double amount, String currency) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $currency';
  }

  String _getTicketNumber(Sale sale) {
    if (sale.id.startsWith('sale-')) {
      final timestamp = sale.id.replaceAll('sale-', '');
      if (timestamp.length > 8) {
        return 'FAC-${timestamp.substring(timestamp.length - 8)}';
      }
    }
    return 'FAC-${sale.id.hashCode.abs().toString().padLeft(8, '0')}';
  }

  void _showReceiptDetailDialog(Sale sale, ShopState state) {
    final now = sale.date;
    final clientName = sale.customerName ?? 'Client Comptant';

    final shopName = state.settings['shopName'] ?? 'Poissonnerie Pro';
    final address = state.settings['address'] ?? '12 Port de Pêche, Abidjan, Côte d’Ivoire';
    final phone = state.settings['phone'] ?? '+225 07 45 12 34 56';
    final taxId = state.settings['taxId'] ?? 'CC-9876543-A';
    final currency = state.settings['currency'] ?? 'FCFA';

    final String ticketNumber = _getTicketNumber(sale);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String receiptText = _generateThermalReceiptText(
              shopName: shopName,
              address: address,
              phone: phone,
              taxId: taxId,
              ticketNumber: ticketNumber,
              date: now,
              clientName: clientName,
              items: sale.items,
              total: sale.totalAmount,
              paymentMode: sale.paymentMode,
              amountReceived: sale.totalAmount,
              change: 0.0,
              currency: currency,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B6B)),
                  const SizedBox(width: 8),
                  const Text('Détails du Reçu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'CONNEXION IMPRIMANTE BLUETOOTH',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isConnected
                                        ? "Connecté : ${_availablePrinters.firstWhere((p) => p.macAdress == _printerMacAddress, orElse: () => BluetoothInfo(name: 'Imprimante', macAdress: _printerMacAddress)).name}"
                                        : "Aucune imprimante connectée",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            if (_availablePrinters.isEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.bluetooth_searching, size: 16),
                                label: const Text('Rechercher Imprimantes', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await _scanBluetoothPrinters();
                                  setDialogState(() {});
                                },
                              )
                            else
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: "Sélectionner l'imprimante Bluetooth",
                                  labelStyle: TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                value: _printerMacAddress.isEmpty ? null : _printerMacAddress,
                                items: _availablePrinters.map((printer) {
                                  return DropdownMenuItem<String>(
                                    value: printer.macAdress,
                                    child: Text(
                                      '${printer.name} (${printer.macAdress})',
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (mac) async {
                                  if (mac != null) {
                                    await _connectToPrinter(mac);
                                    setDialogState(() {});
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'APERÇU TICKET (LARGEUR 80MM)',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '-' * 44,
                              style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              receiptText,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF1E293B),
                                height: 1.25,
                              ),
                            ),
                            Text(
                              '-' * 44,
                              style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.blue),
                      tooltip: 'Partager le ticket',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: receiptText)).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ticket copié ! Partagez le sur WhatsApp.')),
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Réimprimer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await _printDirectly(
                          shopName: shopName,
                          address: address,
                          phone: phone,
                          taxId: taxId,
                          ticketNumber: ticketNumber,
                          date: now,
                          clientName: clientName,
                          items: sale.items,
                          total: sale.totalAmount,
                          paymentMode: sale.paymentMode,
                          amountReceived: sale.totalAmount,
                          change: 0.0,
                          currency: currency,
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addToCart(Product prod) {
    if (prod.stockKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rupture de Stock! Impossible de vendre.')),
      );
      return;
    }

    final existingIdx = _cart.indexWhere((item) => item.productId == prod.id);
    if (existingIdx != -1) {
      final currentQty = _cart[existingIdx].quantityKg;
      if (currentQty + 1 > prod.stockKg) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantité maximale atteinte en fonction du stock disponible.')),
        );
        return;
      }
      setState(() {
        _cart[existingIdx] = SaleItem(
          productId: prod.id,
          productName: prod.name,
          quantityKg: currentQty + 1,
          unitPrice: prod.sellingPrice,
        );
      });
    } else {
      setState(() {
        _cart.add(SaleItem(
          productId: prod.id,
          productName: prod.name,
          quantityKg: 1.0,
          unitPrice: prod.sellingPrice,
        ));
      });
    }
  }

  void _updateCartQuantity(int idx, double newQty, double maxStock) {
    if (newQty <= 0) {
      setState(() {
        _cart.removeAt(idx);
      });
      return;
    }
    if (newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock insuffisant pour cette quantité.')),
      );
      return;
    }
    setState(() {
      final item = _cart[idx];
      _cart[idx] = SaleItem(
        productId: item.productId,
        productName: item.productName,
        quantityKg: newQty,
        unitPrice: item.unitPrice,
      );
    });
  }

  double get _cartTotal => _cart.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  void _showReceiptDialog(
    List<SaleItem> soldItems,
    String? clientId,
    PaymentMode paymentMode,
    double total,
    ShopState state,
  ) {
    final now = DateTime.now();
    final clientName = clientId != null
        ? (state.contacts.firstWhere((c) => c.id == clientId, orElse: () => Contact(id: '', name: 'Client Comptant', phone: '', type: ContactType.client)).name)
        : 'Client Comptant';

    final shopName = state.settings['shopName'] ?? 'Poissonnerie Pro';
    final address = state.settings['address'] ?? '12 Port de Pêche, Abidjan, Côte d’Ivoire';
    final phone = state.settings['phone'] ?? '+225 07 45 12 34 56';
    final taxId = state.settings['taxId'] ?? 'CC-9876543-A';
    final currency = state.settings['currency'] ?? 'FCFA';

    final String ticketNumber = 'FAC-${now.millisecondsSinceEpoch.toString().substring(5)}';

    double amountReceived = total;
    double change = 0.0;

    // Trigger auto scan when opening the dialog
    _scanBluetoothPrinters();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Recalculate change
            change = amountReceived - total;
            if (change < 0) change = 0.0;

            // Generate receipt text inside generator helper
            String receiptText = _generateThermalReceiptText(
              shopName: shopName,
              address: address,
              phone: phone,
              taxId: taxId,
              ticketNumber: ticketNumber,
              date: now,
              clientName: clientName,
              items: soldItems,
              total: total,
              paymentMode: paymentMode,
              amountReceived: amountReceived,
              change: change,
              currency: currency,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.print_rounded, color: Color(0xFFFF6B6B)),
                  const SizedBox(width: 8),
                  const Text('Impression Ticket 80mm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Alert banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Vente enregistrée avec succès !',
                                style: TextStyle(color: Colors.green, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // If cash, show Cash Assistant
                      if (paymentMode == PaymentMode.cash) ...[
                        const Text(
                          'ASSISTANT RENDU DE MONNAIE',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Montant Encaissé ($currency)',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null) {
                                    setDialogState(() {
                                      amountReceived = parsed;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('A Rendre:', style: TextStyle(fontSize: 9, color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
                                  Text(
                                    _formatMoney(change, currency),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Printer Connection interface
                      const Text(
                        'CONNEXION IMPRIMANTE BLUETOOTH',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isConnected
                                        ? "Connecté : ${_availablePrinters.firstWhere((p) => p.macAdress == _printerMacAddress, orElse: () => BluetoothInfo(name: 'Imprimante', macAdress: _printerMacAddress)).name}"
                                        : "Aucune imprimante connectée",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            if (_availablePrinters.isEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.bluetooth_searching, size: 16),
                                label: const Text('Rechercher Imprimantes', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await _scanBluetoothPrinters();
                                  setDialogState(() {});
                                },
                              )
                            else
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: "Sélectionner l'imprimante Bluetooth",
                                  labelStyle: TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                value: _printerMacAddress.isEmpty ? null : _printerMacAddress,
                                items: _availablePrinters.map((printer) {
                                  return DropdownMenuItem<String>(
                                    value: printer.macAdress,
                                    child: Text(
                                      '${printer.name} (${printer.macAdress})',
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (mac) async {
                                  if (mac != null) {
                                    await _connectToPrinter(mac);
                                    setDialogState(() {});
                                  }
                                },
                              ),
                            if (_availablePrinters.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                icon: const Icon(Icons.refresh, size: 16, color: Colors.blueGrey),
                                label: const Text('Relancer le scan Bluetooth', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                onPressed: () async {
                                  await _scanBluetoothPrinters();
                                  setDialogState(() {});
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Receipts simulator frame
                      const Text(
                        'APERÇU TICKET (LARGEUR 80MM)',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Dotted tear line at the top
                            Text(
                              '-' * 44,
                              style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                            ),
                            const SizedBox(height: 8),
                            // Receipt simulated text
                            Text(
                              receiptText,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF1E293B),
                                height: 1.25,
                              ),
                            ),
                            // Dotted tear line at the bottom
                            Text(
                              '-' * 44,
                              style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fast Printing action guides
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Conseil : Connectez votre imprimante 80mm une fois pour imprimer instantanément. Vous pouvez aussi copier le texte pour l\'utiliser dans une application tierce.',
                                style: TextStyle(fontSize: 9.5, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.blue),
                      tooltip: 'Partager le ticket',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: receiptText)).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ticket copié ! Partagez le sur WhatsApp / SMS.')),
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Imprimer Direct', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await _printDirectly(
                          shopName: shopName,
                          address: address,
                          phone: phone,
                          taxId: taxId,
                          ticketNumber: ticketNumber,
                          date: now,
                          clientName: clientName,
                          items: soldItems,
                          total: total,
                          paymentMode: paymentMode,
                          amountReceived: amountReceived,
                          change: change,
                          currency: currency,
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _generateThermalReceiptText({
    required String shopName,
    required String address,
    required String phone,
    required String taxId,
    required String ticketNumber,
    required DateTime date,
    required String clientName,
    required List<SaleItem> items,
    required double total,
    required PaymentMode paymentMode,
    required double amountReceived,
    required double change,
    required String currency,
  }) {
    const int cols = 40; // Perfect standard 80mm compact column layout

    String center(String text) {
      if (text.length >= cols) return text.substring(0, cols);
      int spaces = (cols - text.length) ~/ 2;
      return ' ' * spaces + text;
    }

    String justify(String left, String right) {
      int spaces = cols - left.length - right.length;
      if (spaces < 1) spaces = 1;
      return left + ' ' * spaces + right;
    }

    final separatorDouble = '=' * cols;
    final separatorSingle = '-' * cols;

    final sb = StringBuffer();
    sb.writeln(separatorDouble);
    sb.writeln(center(shopName.toUpperCase()));
    if (address.isNotEmpty) sb.writeln(center(address));
    if (phone.isNotEmpty) sb.writeln(center('Tel: $phone'));
    if (taxId.isNotEmpty) sb.writeln(center('IFU: $taxId'));
    sb.writeln(separatorDouble);

    sb.writeln(justify('TICKET NO:', ticketNumber));
    sb.writeln(justify('DATE:', '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'));
    sb.writeln(justify('CLIENT:', clientName));
    sb.writeln(justify('REGLEMENT:', paymentMode == PaymentMode.cash ? 'ESPECES (571)' : 'BANQUE (521)'));
    sb.writeln(separatorSingle);

    // Header of Table
    sb.writeln('PRODUIT             QTE   P.U   TOTAL');
    sb.writeln(separatorSingle);

    for (var item in items) {
      String name = item.productName;
      if (name.length > 18) {
        name = name.substring(0, 18);
      }
      String qty = item.quantityKg.toStringAsFixed(1);
      String pu = item.unitPrice.toStringAsFixed(0);
      String totalStr = item.subtotal.toStringAsFixed(0);

      // Format clean columns: name (19 chars), qty (5 chars), pu (6 chars), total (10 chars)
      sb.writeln(name.padRight(19) + qty.padRight(5) + pu.padRight(6) + totalStr.padLeft(10));
    }

    sb.writeln(separatorSingle);
    sb.writeln(justify('TOTAL À PAYER:', '${_formatMoney(total, currency)}'));
    if (amountReceived > total) {
      sb.writeln(justify('MONTANT ENCAISSÉ:', '${_formatMoney(amountReceived, currency)}'));
      sb.writeln(justify('MONNAIE RENDUE:', '${_formatMoney(change, currency)}'));
    }
    sb.writeln(separatorDouble);
    sb.writeln(center('Merci de votre confiance !'));
    sb.writeln(separatorDouble);

    return sb.toString();
  }

  void _checkout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide.')),
      );
      return;
    }

    final state = ref.read(shopViewModelProvider);
    final soldItems = List<SaleItem>.from(_cart);
    final total = _cartTotal;
    final clientId = _selectedClientId;
    final paymentMode = _paymentMode;

    // Register sale
    ref.read(shopViewModelProvider.notifier).addSale(
          items: soldItems,
          clientId: clientId,
          paymentMode: paymentMode,
          total: total,
        );

    // Clear cart first so the UI doesn't look busy
    setState(() {
      _cart.clear();
      _selectedClientId = null;
      _paymentMode = PaymentMode.cash;
      _showCartOnMobile = false;
    });

    // Open printing ticket dialog with cash assistant
    _showReceiptDialog(soldItems, clientId, paymentMode, total, state);
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showHistory = false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_showHistory ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_showHistory
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 16,
                      color: !_showHistory ? const Color(0xFFFF6B6B) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nouvelle Vente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !_showHistory ? const Color(0xFF1E293B) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showHistory = true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _showHistory ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _showHistory
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: _showHistory ? const Color(0xFFFF6B6B) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Suivi des Reçus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _showHistory ? const Color(0xFF1E293B) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    // Filtered Products
    final filteredProducts = state.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Clients
    final clients = state.contacts.where((c) => c.type == ContactType.client).toList();

    // History filtering
    final filteredSales = state.sales.where((sale) {
      final ticketNum = _getTicketNumber(sale).toLowerCase();
      final customer = (sale.customerName ?? '').toLowerCase();
      final matchesSearch = ticketNum.contains(_historySearchQuery.toLowerCase()) ||
                            customer.contains(_historySearchQuery.toLowerCase());
      
      final matchesPayment = _historyPaymentFilter == null || sale.paymentMode == _historyPaymentFilter;
      return matchesSearch && matchesPayment;
    }).toList();

    double totalHistoryAmount = 0.0;
    double totalHistoryVolume = 0.0;
    for (var sale in filteredSales) {
      totalHistoryAmount += sale.totalAmount;
      for (var item in sale.items) {
        totalHistoryVolume += item.quantityKg;
      }
    }

    if (_selectedHistorySale == null && filteredSales.isNotEmpty) {
      _selectedHistorySale = filteredSales.first;
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    final productPanel = Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Search & Category Filters Row
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Rechercher un poisson...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  // Horizontal Categories
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: const Text('Tout'),
                          selected: _selectedCategory == null,
                          onSelected: (_) => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        ...ProductCategory.values.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat.label),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Products list grid
          Expanded(
            child: GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, idx) {
                final p = filteredProducts[idx];
                return Card(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => _addToCart(p),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  p.category.label,
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatMoney(p.sellingPrice, currency),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                      ),
                                    ),
                                    Text(
                                      'Stock: ${p.stockKg.toStringAsFixed(0)} Paquets',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: p.stockKg <= p.minThresholdKg ? Colors.pink : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFFFF6B6B),
                                child: const Icon(Icons.add, color: Colors.white, size: 13),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    final cartPanel = Column(
      children: [
        // Cart Header
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (!isDesktop) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => setState(() => _showCartOnMobile = false),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFFFF6B6B), size: 18),
                  const SizedBox(width: 8),
                  const Text('Panier de Vente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${_cart.length} items',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Cart item list
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Votre panier est vide', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _cart.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, idx) {
                    final item = _cart[idx];
                    final prod = state.products.firstWhere((p) => p.id == item.productId);
                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                                      onPressed: () => _updateCartQuantity(idx, item.quantityKg - 1, prod.stockKg),
                                    ),
                                    Text(
                                      '${item.quantityKg.toStringAsFixed(0)} Paquets',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 16),
                                      onPressed: () => _updateCartQuantity(idx, item.quantityKg + 1, prod.stockKg),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatMoney(item.subtotal, currency),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Billing customer selection & Action section
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Dropdown selection
              const Text('CLIENT DE LA TRANSACTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedClientId,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
                hint: const Text('Client Comptant (Anonyme)', style: TextStyle(fontSize: 11)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Client Comptant', style: TextStyle(fontSize: 11)),
                  ),
                  ...clients.map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(fontSize: 11)),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedClientId = val),
              ),
              const SizedBox(height: 12),

              // Payment Mode Toggle Switch
              const Text('RÈGLEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('ESPÈCES (571)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                      selected: _paymentMode == PaymentMode.cash,
                      onSelected: (_) => setState(() => _paymentMode = PaymentMode.cash),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('BANQUE (521)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                      selected: _paymentMode == PaymentMode.bank,
                      onSelected: (_) => setState(() => _paymentMode = PaymentMode.bank),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Calculation Block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL À PAYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E3A4B))),
                  Text(
                    _formatMoney(_cartTotal, currency),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submission checkout button
              ElevatedButton(
                onPressed: _cart.isEmpty ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Valider & Imprimer Facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        )
      ],
    );

    final historyPanel = Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL DES VENTES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          _formatMoney(totalHistoryAmount, currency),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.green, fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SORTIES PHYSIQUES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${totalHistoryVolume.toStringAsFixed(1)} Paquets',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REÇUS ÉMIS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredSales.length} Reçu(s)',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.blueGrey, fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search and filters
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      hintText: 'Rechercher un ticket ou client...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (val) => setState(() => _historySearchQuery = val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Mode : ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Tous', style: TextStyle(fontSize: 10)),
                        selected: _historyPaymentFilter == null,
                        onSelected: (_) => setState(() => _historyPaymentFilter = null),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Espèces', style: TextStyle(fontSize: 10)),
                        selected: _historyPaymentFilter == PaymentMode.cash,
                        onSelected: (_) => setState(() => _historyPaymentFilter = PaymentMode.cash),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Banque', style: TextStyle(fontSize: 10)),
                        selected: _historyPaymentFilter == PaymentMode.bank,
                        onSelected: (_) => setState(() => _historyPaymentFilter = PaymentMode.bank),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List of tickets
          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Aucun ticket trouvé', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSales.length,
                    itemBuilder: (context, idx) {
                      final sale = filteredSales[idx];
                      final isSelected = _selectedHistorySale?.id == sale.id;
                      final ticketNo = _getTicketNumber(sale);
                      final client = sale.customerName ?? 'Client Comptant';
                      final dateStr = '${sale.date.day.toString().padLeft(2, '0')}/${sale.date.month.toString().padLeft(2, '0')}/${sale.date.year} ${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}';
                      
                      final itemsSummary = sale.items.map((it) => '${it.productName} (x${it.quantityKg.toStringAsFixed(0)})').join(', ');

                      return Card(
                        color: isSelected ? const Color(0xFFFF6B6B).withOpacity(0.05) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFF6B6B) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _selectedHistorySale = sale;
                            });
                            if (!isDesktop) {
                              _showReceiptDetailDialog(sale, state);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFFFF6B6B)),
                                        const SizedBox(width: 6),
                                        Text(
                                          ticketNo,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sale.paymentMode == PaymentMode.cash ? Colors.orange.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sale.paymentMode == PaymentMode.cash ? 'ESPÈCES' : 'BANQUE',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: sale.paymentMode == PaymentMode.cash ? Colors.orange.shade800 : Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Client : $client',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatMoney(sale.totalAmount, currency),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 12),
                                Text(
                                  itemsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    final selectedReceiptPreviewPanel = Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B6B), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Aperçu du Ticket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3A4B)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedHistorySale == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Sélectionnez un reçu dans l\'historique pour l\'afficher et le réimprimer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final sale = _selectedHistorySale!;
                    final now = sale.date;
                    final clientName = sale.customerName ?? 'Client Comptant';

                    final shopName = state.settings['shopName'] ?? 'Poissonnerie Pro';
                    final address = state.settings['address'] ?? '12 Port de Pêche, Abidjan, Côte d’Ivoire';
                    final phone = state.settings['phone'] ?? '+225 07 45 12 34 56';
                    final taxId = state.settings['taxId'] ?? 'CC-9876543-A';
                    final currency = state.settings['currency'] ?? 'FCFA';

                    final String ticketNumber = _getTicketNumber(sale);

                    String receiptText = _generateThermalReceiptText(
                      shopName: shopName,
                      address: address,
                      phone: phone,
                      taxId: taxId,
                      ticketNumber: ticketNumber,
                      date: now,
                      clientName: clientName,
                      items: sale.items,
                      total: sale.totalAmount,
                      paymentMode: sale.paymentMode,
                      amountReceived: sale.totalAmount,
                      change: 0.0,
                      currency: currency,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '-' * 44,
                                  style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  receiptText,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    color: Color(0xFF1E293B),
                                    height: 1.25,
                                  ),
                                ),
                                Text(
                                  '-' * 44,
                                  style: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 10, height: 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: receiptText)).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Ticket copié ! Partagez le sur WhatsApp.')),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.share_rounded, size: 14),
                                  label: const Text('Partager', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _printDirectly(
                                      shopName: shopName,
                                      address: address,
                                      phone: phone,
                                      taxId: taxId,
                                      ticketNumber: ticketNumber,
                                      date: now,
                                      clientName: clientName,
                                      items: sale.items,
                                      total: sale.totalAmount,
                                      paymentMode: sale.paymentMode,
                                      amountReceived: sale.totalAmount,
                                      change: 0.0,
                                      currency: currency,
                                    );
                                  },
                                  icon: const Icon(Icons.print, size: 14),
                                  label: const Text('Réimprimer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B6B),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildModeSelector(),
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _showHistory ? historyPanel : productPanel,
                      ),
                      Container(
                        width: 320,
                        color: Colors.white,
                        child: _showHistory ? selectedReceiptPreviewPanel : cartPanel,
                      ),
                    ],
                  )
                : (_showHistory
                    ? historyPanel
                    : (_showCartOnMobile ? cartPanel : productPanel)),
          ),
        ],
      ),
      floatingActionButton: (!isDesktop && !_showHistory && !_showCartOnMobile)
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showCartOnMobile = true),
              backgroundColor: const Color(0xFFFF6B6B),
              icon: Badge(
                label: Text('${_cart.length}', style: const TextStyle(color: Colors.white)),
                child: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
              ),
              label: const Text('Panier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
