import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/api_service.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.get('/parcels/categories');
      if (mounted) {
        setState(() {
          _categories = res['data'];
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitParcel() async {
    if (_receiverNameCtrl.text.isEmpty || _receiverPhoneCtrl.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      // Mock locations for demo (since we haven't integrated the map selector into this form yet)
      final reqBody = {
        'category_id': _selectedCategoryId,
        'parcel_description': _descriptionCtrl.text,
        'receiver_name': _receiverNameCtrl.text,
        'receiver_phone': _receiverPhoneCtrl.text,
        'pickup_lat': 23.8103,
        'pickup_lng': 90.4125,
        'pickup_address': 'Dhaka',
        'drop_lat': 23.7940,
        'drop_lng': 90.4043,
        'drop_address': 'Banani',
        'estimated_fare': 150,
      };

      final res = await ApiService.post('/parcels', body: reqBody);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📦 Parcel booked! Pickup OTP: ${res['data']['pickup_otp']}'), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a Parcel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            
            _buildTextField('Receiver Name', _receiverNameCtrl, Icons.person),
            const SizedBox(height: 16),
            _buildTextField('Receiver Phone', _receiverPhoneCtrl, Icons.phone),
            const SizedBox(height: 16),
            _buildTextField('Description (Optional)', _descriptionCtrl, Icons.description),
            const SizedBox(height: 24),

            const Text('Parcel Size', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            
            if (_categories.isEmpty)
              const Text('No categories found', style: TextStyle(color: AppTheme.textHint))
            else
              ..._categories.map((cat) => RadioListTile<String>(
                title: Text(cat['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('Max ${cat['max_weight_kg']}kg • Base: ৳${cat['base_fare']}', style: const TextStyle(color: AppTheme.textSecondary)),
                value: cat['id'],
                groupValue: _selectedCategoryId,
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              )),
              
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitParcel,
                child: const Text('Book Delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textHint),
        filled: true,
        fillColor: AppTheme.bgSurface,
      ),
    );
  }
}
