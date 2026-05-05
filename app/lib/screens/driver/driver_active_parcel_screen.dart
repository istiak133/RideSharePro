// ============================================
// Driver Active Parcel Screen — Transit & OTPs
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class DriverActiveParcelScreen extends StatefulWidget {
  final Map<String, dynamic> parcelRequest;

  const DriverActiveParcelScreen({super.key, required this.parcelRequest});

  @override
  State<DriverActiveParcelScreen> createState() => _DriverActiveParcelScreenState();
}

class _DriverActiveParcelScreenState extends State<DriverActiveParcelScreen> {
  late Map<String, dynamic> _parcel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _parcel = widget.parcelRequest;
    _fetchParcelDetails();
  }

  Future<void> _fetchParcelDetails() async {
    try {
      final res = await ApiService.get('/parcels/${_parcel['id']}');
      if (mounted) setState(() => _parcel = res['data']);
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> _updateStatus(String endpoint) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.put('/parcels/${_parcel['id']}/$endpoint');
      setState(() => _parcel = res['data']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPDialog(bool isPickup) {
    String otp = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isPickup ? 'Enter Pickup OTP' : 'Enter Delivery OTP', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(isPickup ? 'Ask the sender for the 4-digit code' : 'Ask the receiver for the 4-digit code', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: 4,
                obscureText: false,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 60,
                  fieldWidth: 50,
                  activeFillColor: AppTheme.bgSurface,
                  inactiveFillColor: AppTheme.bgSurface,
                  selectedFillColor: AppTheme.primary.withValues(alpha: 0.2),
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.transparent,
                  selectedColor: AppTheme.primary,
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 24),
                enableActiveFill: true,
                onChanged: (v) => otp = v,
                onCompleted: (v) async {
                  Navigator.pop(ctx);
                  _verifyOTP(isPickup, v);
                },
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOTP(bool isPickup, String otp) async {
    setState(() => _isLoading = true);
    try {
      final endpoint = isPickup ? 'verify-pickup' : 'verify-delivery';
      final res = await ApiService.post('/parcels/${_parcel['id']}/$endpoint', body: {'otp': otp});
      
      if (!isPickup) {
        // Show delivery success
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: AppTheme.bgCard,
              title: const Text('🎉 Delivery Complete!', style: TextStyle(color: Colors.white)),
              content: Text('You earned ৳${res['data']['driver_earning']}', style: const TextStyle(color: AppTheme.success, fontSize: 18)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to home
                  },
                  child: const Text('Done'),
                )
              ],
            )
          );
        }
      } else {
        setState(() => _parcel = res['data']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _parcel['status'] ?? 'pending';
    final pickupLat = _parcel['pickup_lat'] is String ? double.tryParse(_parcel['pickup_lat']) ?? AppConfig.defaultLat : (_parcel['pickup_lat'] ?? AppConfig.defaultLat);
    final pickupLng = _parcel['pickup_lng'] is String ? double.tryParse(_parcel['pickup_lng']) ?? AppConfig.defaultLng : (_parcel['pickup_lng'] ?? AppConfig.defaultLng);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(pickupLat, pickupLng),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(pickupLat, pickupLng),
                  width: 50, height: 50,
                  child: const Icon(Icons.location_on, color: AppTheme.primary, size: 40),
                )
              ])
            ],
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${status.toUpperCase()}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('৳${_parcel['estimated_fare']}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // People Info based on status
                  if (status == 'driver_assigned' || status == 'pickup_arrived') ...[
                    _buildContactRow('Sender', _parcel['pickup_contact_name'] ?? 'Sender', _parcel['pickup_contact_phone'] ?? ''),
                    const Divider(color: AppTheme.bgSurface, height: 24),
                    _buildLocationRow(Icons.my_location, 'Pickup', _parcel['pickup_address']),
                  ] else ...[
                    _buildContactRow('Receiver', _parcel['receiver_name'] ?? 'Receiver', _parcel['receiver_phone'] ?? ''),
                    const Divider(color: AppTheme.bgSurface, height: 24),
                    _buildLocationRow(Icons.location_on, 'Dropoff', _parcel['drop_address']),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (status == 'driver_assigned') _updateStatus('pickup-arrived');
                        else if (status == 'pickup_arrived') _showOTPDialog(true);
                        else if (status == 'picked_up') _updateStatus('in-transit');
                        else if (status == 'in_transit') _showOTPDialog(false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_getButtonText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactRow(String title, String name, String phone) {
    return Row(
      children: [
        const CircleAvatar(backgroundColor: AppTheme.bgSurface, child: Icon(Icons.person, color: Colors.white)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone, color: AppTheme.success),
          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
        )
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              Text(address, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _getButtonText(String status) {
    switch(status) {
      case 'driver_assigned': return 'Arrived at Pickup';
      case 'pickup_arrived': return 'Verify Pickup OTP';
      case 'picked_up': return 'Start Transit';
      case 'in_transit': return 'Verify Delivery OTP';
      default: return 'Processing...';
    }
  }
}
