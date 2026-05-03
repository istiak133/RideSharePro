import 'package:flutter/material.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/screens/rider/rating_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final double fareAmount;

  const PaymentScreen({
    super.key,
    required this.rideId,
    required this.fareAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'bkash';

  void _processPayment() {
    if (_selectedMethod == 'bkash') {
      _showBkashSimulator();
    } else {
      // Simulate cash/card payment
      _showSuccessAndNavigate();
    }
  }

  void _showBkashSimulator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: const Color(0xFFE2136E), // bKash Pink
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Fake bKash Header
            const Text('bKash Payment', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('RideShare AI Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Amount: ৳${widget.fareAmount.round()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE2136E))),
                  const SizedBox(height: 24),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Your bKash Account Number',
                      filled: true,
                      fillColor: Color(0xFFF2F2F2),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter PIN',
                      filled: true,
                      fillColor: Color(0xFFF2F2F2),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showSuccessAndNavigate();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2136E), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 80),
              const SizedBox(height: 20),
              const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Thank you for riding with us.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  // Navigate to Rating Screen (Replace current payment screen)
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => RatingScreen(rideId: widget.rideId),
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.bgSurface, width: 2),
              ),
              child: Column(
                children: [
                  const Text('Total Fare', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('৳${widget.fareAmount.round()}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.bgSurface),
                  const SizedBox(height: 16),
                  _buildReceiptRow('Base Fare', '৳30'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Distance & Time', '৳${(widget.fareAmount - 30).round()}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Methods
            _buildMethodOption('bkash', 'bKash Mobile Menu', Icons.account_balance_wallet, const Color(0xFFE2136E)),
            _buildMethodOption('cash', 'Cash to Driver', Icons.money, AppTheme.success),
            _buildMethodOption('card', 'Credit/Debit Card', Icons.credit_card, AppTheme.primary),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processPayment,
                child: Text('Pay ৳${widget.fareAmount.round()}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMethodOption(String id, String title, IconData icon, Color color) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppTheme.bgSurface, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
