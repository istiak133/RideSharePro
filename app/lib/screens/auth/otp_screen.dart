// ============================================
// OTP Verification Screen
// ============================================

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/rider/rider_home_screen.dart';
import 'package:rideshare_app/screens/driver/driver_home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String role;
  final String? devOTP;

  const OTPScreen({super.key, required this.phone, required this.role, this.devOTP});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fill OTP in dev mode
    if (widget.devOTP != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _otpController.text = widget.devOTP!;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() async {
    if (_otpController.text.length != 6) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(widget.phone, _otpController.text, widget.role);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => widget.role == 'driver' ? const DriverHomeScreen() : const RiderHomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'OTP সঠিক নয়'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('OTP যাচাই করুন', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              RichText(text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  const TextSpan(text: 'আমরা '),
                  TextSpan(text: '+88${widget.phone}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' নম্বরে একটি ৬ ডিজিটের কোড পাঠিয়েছি'),
                ],
              )),

              if (widget.devOTP != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.developer_mode, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 8),
                    Text('Dev OTP: ${widget.devOTP}', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],

              const SizedBox(height: 40),

              PinCodeTextField(
                appContext: context,
                controller: _otpController,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(14),
                  fieldHeight: 60,
                  fieldWidth: 48,
                  activeFillColor: AppTheme.bgSurface,
                  inactiveFillColor: AppTheme.bgSurface,
                  selectedFillColor: AppTheme.primary.withValues(alpha: 0.1),
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.bgSurface,
                  selectedColor: AppTheme.primary,
                ),
                enableActiveFill: true,
                onCompleted: (_) => _verify(),
                onChanged: (_) {},
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _verify,
                child: auth.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('যাচাই করুন'),
              ),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AuthProvider>().requestOTP(widget.phone),
                  child: const Text('আবার OTP পাঠান', style: TextStyle(color: AppTheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
