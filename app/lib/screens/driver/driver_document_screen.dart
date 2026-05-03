import 'package:flutter/material.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/api_service.dart';

class DriverDocumentScreen extends StatefulWidget {
  const DriverDocumentScreen({super.key});

  @override
  State<DriverDocumentScreen> createState() => _DriverDocumentScreenState();
}

class _DriverDocumentScreenState extends State<DriverDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nidController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  
  bool _isLoading = false;

  void _submitDocuments() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await ApiService.post('/users/driver/documents', body: {
        'nid_front_url': 'https://dummyimage.com/600x400/000/fff&text=NID+Front+${_nidController.text}',
        'nid_back_url': 'https://dummyimage.com/600x400/000/fff&text=NID+Back',
        'license_url': 'https://dummyimage.com/600x400/000/fff&text=License+${_licenseController.text}',
        'vehicle_model': _vehicleModelController.text,
        'registration_number': _vehicleRegController.text,
        'vehicle_photo_url': 'https://dummyimage.com/600x400/000/fff&text=Vehicle',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents Submitted for Verification!'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true); // Return true to refresh profile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Upload Documents'), backgroundColor: AppTheme.bgCard),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Info', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildField(_nidController, 'NID Number'),
              const SizedBox(height: 16),
              _buildField(_licenseController, 'Driving License Number'),
              const SizedBox(height: 32),
              
              const Text('Vehicle Info', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildField(_vehicleModelController, 'Vehicle Model (e.g. Toyota Axio)'),
              const SizedBox(height: 16),
              _buildField(_vehicleRegController, 'Registration Number'),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDocuments,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Documents', style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: AppTheme.bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
