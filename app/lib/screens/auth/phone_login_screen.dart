// ============================================
// Phone Login Screen
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  String _selectedRole = 'rider';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11 || !phone.startsWith('01')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 11-digit phone number'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.requestOTP(phone);

    if (success && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OTPScreen(phone: phone, role: _selectedRole, devOTP: auth.devOTP),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to send OTP'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo area
              Center(
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.local_taxi_rounded, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),

              Center(child: Text('RideShare AI Pro', style: Theme.of(context).textTheme.headlineLarge)),
              const SizedBox(height: 8),
              Center(child: Text('Start your journey', style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(height: 48),

              // Role selection
              Text('Who are you?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _roleCard('rider', 'Rider', Icons.person_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _roleCard('driver', 'Driver', Icons.drive_eta_rounded)),
                ],
              ),
              const SizedBox(height: 32),

              // Phone input
              Text('Phone Number', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white),
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇧🇩 +88', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 24, color: AppTheme.textHint),
                      ],
                    ),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send OTP'),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'By logging in, you agree to our Terms & Conditions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: selected ? AppTheme.primary : AppTheme.textHint),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
