import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/shop_view_model.dart';
import '../../data/models/poissonnerie_models.dart';

class ContactsTabView extends ConsumerStatefulWidget {
  const ContactsTabView({super.key});

  @override
  ConsumerState<ContactsTabView> createState() => _ContactsTabViewState();
}

class _ContactsTabViewState extends ConsumerState<ContactsTabView> {
  String _searchQuery = '';
  ContactType? _selectedType;

  String _formatMoney(double amount, String currency) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    return '${amount < 0 ? '-' : ''}$formatted $currency';
  }

  void _showContactDialog([Contact? contact]) {
    final isEdit = contact != null;
    final nameController =
        TextEditingController(text: isEdit ? contact.name : '');
    final phoneController =
        TextEditingController(text: isEdit ? contact.phone : '');
    final balanceController = TextEditingController(
        text: isEdit ? contact.balance.toStringAsFixed(0) : '0');
    ContactType type = isEdit ? contact.type : ContactType.client;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  isEdit
                      ? 'Modifier la Fiche Contact'
                      : 'Nouveau Client ou Fournisseur',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nom Complet / Enseigne'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Numéro de Téléphone (ex: +225...)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ContactType>(
                      value: type,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Type de Relation'),
                      items: const [
                        DropdownMenuItem(
                            value: ContactType.client, child: Text('Client')),
                        DropdownMenuItem(
                            value: ContactType.fournisseur,
                            child: Text('Fournisseur Grossiste')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => type = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Balance de Compte Initiale (CFA)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B)),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final balance =
                        double.tryParse(balanceController.text) ?? 0.0;

                    if (name.isEmpty) return;

                    final notifier = ref.read(shopViewModelProvider.notifier);
                    if (isEdit) {
                      notifier.updateContact(Contact(
                        id: contact.id,
                        name: name,
                        phone: phone,
                        type: type,
                        balance: balance,
                      ));
                    } else {
                      notifier.addContact(Contact(
                        id: 'cont-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        phone: phone,
                        type: type,
                        balance: balance,
                      ));
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isEdit
                              ? 'Fiche contact actualisée.'
                              : 'Nouveau contact enregistré.')),
                    );
                  },
                  child: Text(isEdit ? 'Enregistrer' : 'Créer',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final currency = state.settings['currency'] ?? 'FCFA';

    final filteredContacts = state.contacts.where((c) {
      final matchesSearch =
          c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || c.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Panel & Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            hintText: 'Rechercher un contact...',
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<ContactType>(
                                    value: _selectedType,
                                    isExpanded: true,
                                    hint: const Text('Tous',
                                        style: TextStyle(fontSize: 11)),
                                    items: const [
                                      DropdownMenuItem(
                                          value: null,
                                          child: Text('Tous',
                                              style: TextStyle(fontSize: 11))),
                                      DropdownMenuItem(
                                          value: ContactType.client,
                                          child: Text('Clients',
                                              style: TextStyle(fontSize: 11))),
                                      DropdownMenuItem(
                                          value: ContactType.fournisseur,
                                          child: Text('Grossistes',
                                              style: TextStyle(fontSize: 11))),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _selectedType = val),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              onPressed: () => _showContactDialog(),
                              icon: const Icon(Icons.person_add_alt_1_rounded,
                                  color: Colors.white, size: 16),
                              label: const Text('Ajouter',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: 'Rechercher un client ou grossiste...',
                              prefixIcon:
                                  const Icon(Icons.search_rounded, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<ContactType>(
                          value: _selectedType,
                          hint: const Text('Tous les contacts',
                              style: TextStyle(fontSize: 12)),
                          items: const [
                            DropdownMenuItem(
                                value: null,
                                child: Text('Tous les contacts',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: ContactType.client,
                                child: Text('Clients uniquement',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: ContactType.fournisseur,
                                child: Text('Fournisseurs uniquement',
                                    style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedType = val),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => _showContactDialog(),
                          icon: const Icon(Icons.person_add_alt_1_rounded,
                              color: Colors.white, size: 16),
                          label: const Text('Ajouter Contact',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        )
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Contacts Table Grid
          Expanded(
            child: isMobile
                ? (filteredContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun contact trouvé',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final c = filteredContacts[index];
                          final isClient = c.type == ContactType.client;
                          final balText = _formatMoney(c.balance, currency);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Color(0xFF2E3A4B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isClient
                                              ? Colors.blue.shade50
                                              : Colors.purple.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isClient ? 'CLIENT' : 'GROSSISTE',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: isClient
                                                ? Colors.blue.shade700
                                                : Colors.purple.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, thickness: 0.5),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          c.phone.isNotEmpty
                                              ? c.phone
                                              : 'Non renseigné',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              size: 14,
                                              color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Solde:',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        balText,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Courier',
                                          color: c.balance == 0
                                              ? Colors.grey
                                              : (isClient
                                                  ? Colors.green
                                                  : Colors.pink),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, thickness: 0.5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_note_rounded,
                                            color: Colors.blue,
                                            size: 18),
                                        onPressed: () => _showContactDialog(c),
                                        tooltip: 'Modifier la fiche',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.pink,
                                            size: 18),
                                        onPressed: () {
                                          ref
                                              .read(shopViewModelProvider
                                                  .notifier)
                                              .deleteContact(c.id);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Contact archivé.')));
                                        },
                                        tooltip: 'Supprimer',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ))
                : Card(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 16,
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(
                                  label: Text('CONSEIL / NOM COMPLET',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text('RELATION TYPE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text('TÉLÉPHONE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text('SOLDE DE COMPTE (CFA)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text('ACTIONS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                            ],
                            rows: filteredContacts.map((c) {
                              final isClient = c.type == ContactType.client;
                              // For suppliers, negative balance means we owe them money (Créditeur)
                              // For clients, positive balance means they owe us money (Débiteur)
                              final balText = _formatMoney(c.balance, currency);

                              return DataRow(
                                cells: [
                                  DataCell(Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isClient
                                            ? Colors.blue.shade50
                                            : Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isClient ? 'CLIENT' : 'GROSSISTE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isClient
                                              ? Colors.blue.shade700
                                              : Colors.purple.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(c.phone,
                                      style: const TextStyle(fontSize: 12))),
                                  DataCell(
                                    Text(
                                      balText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                        color: c.balance == 0
                                            ? Colors.grey
                                            : (isClient
                                                ? Colors.green
                                                : Colors.pink),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_note_rounded,
                                              color: Colors.blue,
                                              size: 18),
                                          onPressed: () =>
                                              _showContactDialog(c),
                                          tooltip: 'Modifier la fiche',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.pink,
                                              size: 18),
                                          onPressed: () {
                                            ref
                                                .read(shopViewModelProvider
                                                    .notifier)
                                                .deleteContact(c.id);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Contact archivé.')));
                                          },
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
