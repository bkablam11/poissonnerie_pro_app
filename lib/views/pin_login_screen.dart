import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/shop_view_model.dart';
import 'home_screen.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  final Function(UserRole) onLoginSuccess;

  const PinLoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = "";
  String? _errorMessage;

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _pin = "";
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final settings = ref.read(shopViewModelProvider).settings;
    final cashierPin = settings['cashierPin'] ?? '1111';
    final managerPin = settings['managerPin'] ?? '6465';
    final adminPin = settings['adminPin'] ?? '1007';

    if (_pin == adminPin) {
      // Login as Admin
      _showSuccessSnackBar("Connexion réussie : Mode Administrateur");
      widget.onLoginSuccess(UserRole.admin);
    } else if (_pin == managerPin) {
      // Login as Manager
      _showSuccessSnackBar("Connexion réussie : Mode Gérant");
      widget.onLoginSuccess(UserRole.manager);
    } else if (_pin == cashierPin) {
      // Login as Cashier
      _showSuccessSnackBar("Connexion réussie : Mode Caissier");
      widget.onLoginSuccess(UserRole.cashier);
    } else {
      setState(() {
        _errorMessage = "Code PIN incorrect";
        _pin = "";
      });
      _showErrorSnackBar();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text("Code PIN invalide. Veuillez réessayer.",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildKeypadButton(String label,
      {VoidCallback? onTap, IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: const Color(0xFF2E3A4B), size: 24)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A4B),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Logo
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sailing_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "POISSONNERIE PRO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E3A4B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gestion & Facturation de Pêche",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 32),

                  // Lock Icon & Heading
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_person_rounded,
                          size: 16, color: Color(0xFFFF6B6B)),
                      SizedBox(width: 6),
                      Text(
                        "AUTHENTIFICATION SECURISÉE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B6B),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Saisir votre code PIN à 4 chiffres",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3A4B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final hasDigit = _pin.length > index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasDigit
                              ? const Color(0xFFFF6B6B)
                              : Colors.transparent,
                          border: Border.all(
                            color: _errorMessage != null
                                ? Colors.red
                                : (hasDigit
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFFCBD5E1)),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  SizedBox(height: isCompact ? 16 : 32),

                  // Virtual Keypad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("1",
                              onTap: () => _onKeyPress("1")),
                          _buildKeypadButton("2",
                              onTap: () => _onKeyPress("2")),
                          _buildKeypadButton("3",
                              onTap: () => _onKeyPress("3")),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("4",
                              onTap: () => _onKeyPress("4")),
                          _buildKeypadButton("5",
                              onTap: () => _onKeyPress("5")),
                          _buildKeypadButton("6",
                              onTap: () => _onKeyPress("6")),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("7",
                              onTap: () => _onKeyPress("7")),
                          _buildKeypadButton("8",
                              onTap: () => _onKeyPress("8")),
                          _buildKeypadButton("9",
                              onTap: () => _onKeyPress("9")),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("C",
                              onTap: _onClear, icon: Icons.clear_all_rounded),
                          _buildKeypadButton("0",
                              onTap: () => _onKeyPress("0")),
                          _buildKeypadButton("⌫",
                              onTap: _onDelete, icon: Icons.backspace_outlined),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: isCompact ? 16 : 32),

                  // Production security badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: Color(0xFF2E3A4B), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Accès sécurisé pour le personnel de la poissonnerie (Administrateur / Gérant / Caissier)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A4B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
