import React, { useState, useMemo } from 'react';
import { DBState, Contact } from '../types';
import { 
  Users, 
  Search, 
  Plus, 
  Edit, 
  Trash2, 
  Phone, 
  Mail, 
  MapPin, 
  FileText, 
  X, 
  Save,
  Tag
} from 'lucide-react';

interface ContactsTabProps {
  state: DBState;
  onAddContact: (contact: Omit<Contact, 'id' | 'updatedAt' | 'isSynced'>) => void;
  onUpdateContact: (contact: Contact) => void;
  onDeleteContact: (id: string) => void;
}

export function ContactsTab({ state, onAddContact, onUpdateContact, onDeleteContact }: ContactsTabProps) {
  const { contacts, settings } = state;

  // Search & Filter state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState('All'); // All, Client, Fournisseur

  // Sidebar Form Editor
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<Contact | null>(null);

  // Form Fields
  const [name, setName] = useState('');
  const [type, setType] = useState<Contact['type']>('Client');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [email, setEmail] = useState('');
  const [notes, setNotes] = useState('');
  const [balance, setBalance] = useState(0);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'decimal' }).format(val) + ` ${settings.currency || 'FCFA'}`;
  };

  // Open add form
  const handleOpenAdd = () => {
    setEditingContact(null);
    setName('');
    setType('Client');
    setPhone('');
    setAddress('');
    setEmail('');
    setNotes('');
    setBalance(0);
    setIsFormOpen(true);
  };

  // Open edit form
  const handleOpenEdit = (c: Contact) => {
    setEditingContact(c);
    setName(c.name);
    setType(c.type);
    setPhone(c.phone);
    setAddress(c.address);
    setEmail(c.email);
    setNotes(c.notes);
    setBalance(c.balance);
    setIsFormOpen(true);
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    const payload = {
      name,
      type,
      phone,
      address,
      email,
      notes,
      balance: Number(balance)
    };

    if (editingContact) {
      onUpdateContact({
        ...editingContact,
        ...payload
      });
    } else {
      onAddContact(payload);
    }
    setIsFormOpen(false);
  };

  const handleDelete = (id: string) => {
    if (window.confirm("Êtes-vous sûr de vouloir supprimer ce partenaire d'affaires ?")) {
      onDeleteContact(id);
    }
  };

  // Filtered List
  const filteredContacts = useMemo(() => {
    return contacts.filter((c) => {
      const matchesType = selectedType === 'All' || c.type === selectedType || c.type === 'Deux';
      const matchesSearch = c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                            c.phone.includes(searchQuery) ||
                            c.notes.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    });
  }, [contacts, selectedType, searchQuery]);

  return (
    <div className="space-y-6" id="contacts-tab">
      
      {/* Search Header panel */}
      <div className="bg-white p-5 rounded-[24px] border border-gray-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        <div className="flex flex-col sm:flex-row sm:items-center gap-3 w-full max-w-2xl">
          {/* Live Search */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 transform -translate-y-1/2" />
            <input
              type="text"
              placeholder="Rechercher par raison sociale, téléphone..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#F8FAFC] border border-gray-100 pl-10 pr-4 py-2 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-[#FF6B6B]/20"
            />
          </div>

          {/* Type filters */}
          <select
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
            className="bg-[#F8FAFC] border border-gray-100 px-4 py-2 rounded-xl text-xs font-semibold focus:outline-hidden text-gray-600"
          >
            <option value="All">-- Tous les Partenaires --</option>
            <option value="Client">Clients uniquement</option>
            <option value="Fournisseur">Fournisseurs uniquement</option>
          </select>
        </div>

        {/* Add Contact Button */}
        <button
          onClick={handleOpenAdd}
          className="bg-[#FF6B6B] hover:bg-coral-dark text-white px-5 py-2.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-xs hover:shadow-md transition active:scale-98"
        >
          <Plus className="w-4 h-4" /> Nouveau Contact
        </button>

      </div>

      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
        
        {/* Table list - Col Span 8 or 12 depending on if Form is open */}
        <div className={`${isFormOpen ? 'xl:col-span-8' : 'xl:col-span-12'} bg-white rounded-[24px] border border-gray-100 shadow-sm overflow-hidden transition-all duration-300`}>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50/75 border-b border-gray-100 text-gray-400 text-xxs font-bold uppercase tracking-wider">
                  <th className="p-4 pl-6">Partenaire</th>
                  <th className="p-4">Type</th>
                  <th className="p-4">Coordonnées</th>
                  <th className="p-4">Notes</th>
                  <th className="p-4 text-right">Créance / Dette</th>
                  <th className="p-4 text-right pr-6">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 text-xs">
                {filteredContacts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-12 text-center text-gray-400">
                      <Users className="w-10 h-10 mx-auto opacity-30 mb-2" />
                      Aucun contact enregistré. Cliquez sur "Nouveau Contact" pour ajouter des partenaires.
                    </td>
                  </tr>
                ) : (
                  filteredContacts.map((c) => {
                    const isClient = c.type === 'Client' || c.type === 'Deux';
                    const isSupplier = c.type === 'Fournisseur' || c.type === 'Deux';
                    
                    return (
                      <tr key={c.id} className="hover:bg-slate-50/50 transition">
                        {/* Name */}
                        <td className="p-4 pl-6 font-bold text-gray-800">
                          <span className="flex items-center gap-1.5">
                            {c.name}
                            {!c.isSynced && (
                              <span className="inline-block w-1.5 h-1.5 rounded-full bg-orange-400" title="Non synchronisé"></span>
                            )}
                          </span>
                        </td>

                        {/* Type Badge */}
                        <td className="p-4">
                          <span className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full uppercase ${
                            c.type === 'Client' 
                              ? 'bg-blue-100 text-blue-700' 
                              : c.type === 'Fournisseur' 
                                ? 'bg-orange-100 text-orange-700' 
                                : 'bg-purple-100 text-purple-700'
                          }`}>
                            {c.type}
                          </span>
                        </td>

                        {/* Contact info details */}
                        <td className="p-4 space-y-1">
                          {c.phone && (
                            <span className="flex items-center gap-1 text-[11px] text-gray-600">
                              <Phone className="w-3.5 h-3.5 text-gray-400" /> {c.phone}
                            </span>
                          )}
                          {c.email && (
                            <span className="flex items-center gap-1 text-[11px] text-gray-400">
                              <Mail className="w-3.5 h-3.5 text-gray-400" /> {c.email}
                            </span>
                          )}
                        </td>

                        {/* Notes snippet */}
                        <td className="p-4 text-gray-400 font-medium max-w-[200px] truncate">
                          {c.notes || '—'}
                        </td>

                        {/* Debt Balance */}
                        <td className="p-4 text-right">
                          <div className="flex flex-col items-end">
                            <span className={`font-mono font-bold text-sm ${
                              c.balance > 0 
                                ? isClient 
                                  ? 'text-blue-600' // Clients owe us
                                  : 'text-orange-600' // We owe suppliers
                                : 'text-gray-400'
                            }`}>
                              {formatMoney(c.balance)}
                            </span>
                            <span className="text-[9px] text-gray-400 mt-0.5 uppercase tracking-wider">
                              {c.balance > 0 
                                ? isClient 
                                  ? "Créance (VIP)" 
                                  : "Dette d'achat" 
                                : "Solde à jour"}
                            </span>
                          </div>
                        </td>

                        {/* Actions */}
                        <td className="p-4 text-right pr-6">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleOpenEdit(c)}
                              className="p-1.5 bg-slate-100 text-slate-600 hover:bg-[#FF6B6B]/10 hover:text-[#FF6B6B] rounded-lg transition"
                            >
                              <Edit className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleDelete(c.id)}
                              className="p-1.5 bg-slate-100 text-slate-400 hover:bg-pink-100 hover:text-pink-600 rounded-lg transition"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>

                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Sidebar Form Panel */}
        {isFormOpen && (
          <div className="xl:col-span-4 bg-white rounded-[24px] border border-gray-100 shadow-sm p-5 space-y-4 animate-slideIn">
            
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="font-bold text-gray-900 text-sm">
                {editingContact ? 'Modifier le Partenaire' : 'Créer un Partenaire'}
              </h3>
              <button 
                onClick={() => setIsFormOpen(false)}
                className="p-1.5 bg-slate-50 hover:bg-slate-100 text-gray-400 hover:text-gray-600 rounded-lg"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleFormSubmit} className="space-y-4 text-xs">
              
              {/* Partner Name */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Raison sociale / Nom complet *</label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Mme Diallo Fatoumata"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold"
                />
              </div>

              {/* Type Choice */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Type d'Activité</label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value as any)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs font-semibold text-gray-700"
                >
                  <option value="Client">Client (Acheteur régulier)</option>
                  <option value="Fournisseur">Fournisseur (Grossiste/Pêcheur)</option>
                  <option value="Deux">Double Statut (Client + Fournisseur)</option>
                </select>
              </div>

              {/* Coordonnées */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Téléphone</label>
                  <input
                    type="text"
                    placeholder="Ex: +225 07..."
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs"
                  />
                </div>

                <div className="space-y-1">
                  <label className="font-bold text-gray-500 uppercase tracking-wider block">Courriel</label>
                  <input
                    type="email"
                    placeholder="Ex: client@domain.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs"
                  />
                </div>
              </div>

              {/* Address */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Adresse Géographique</label>
                <input
                  type="text"
                  placeholder="Ex: Riviera 3, Abidjan"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs"
                />
              </div>

              {/* Starting balance debt */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">
                  {type === 'Client' ? "Arriérés d'achat VIP de départ" : "Dette de démarrage d'achat"} ({settings.currency})
                </label>
                <input
                  type="number"
                  placeholder="Ex: 0"
                  value={balance || ''}
                  onChange={(e) => setBalance(Number(e.target.value))}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-sm font-semibold font-mono"
                />
              </div>

              {/* Notes */}
              <div className="space-y-1">
                <label className="font-bold text-gray-500 uppercase tracking-wider block">Notes sur le Partenaire</label>
                <textarea
                  placeholder="Conditions de règlement, préférences..."
                  rows={3}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-gray-200 p-2.5 rounded-xl text-xs focus:outline-hidden"
                />
              </div>

              {/* Save Button */}
              <button
                type="submit"
                className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl flex items-center justify-center gap-1.5 shadow-sm transition active:scale-98"
              >
                <Save className="w-4 h-4" /> Enregistrer le Contact
              </button>

            </form>

          </div>
        )}

      </div>

    </div>
  );
}
