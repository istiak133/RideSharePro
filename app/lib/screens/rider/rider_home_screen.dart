// ============================================
// Rider Home Screen — Map + Book Ride
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/phone_login_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  int _currentIndex = 0;

  final _pickupController = TextEditingController(text: 'Your Location');
  final _dropController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: AppConfig.defaultZoom,
              onTap: (tapPosition, point) {
                if (_dropLocation == null) {
                  setState(() {
                    _dropLocation = point;
                    _dropController.text = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  Marker(
                    point: _currentLocation,
                    width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: AppTheme.primary, size: 30),
                    ),
                  ),
                  // Drop location marker
                  if (_dropLocation != null)
                    Marker(
                      point: _dropLocation!,
                      width: 50, height: 50,
                      child: const Icon(Icons.location_on, color: AppTheme.accent, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // Top search card
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  _locationRow(Icons.circle, AppTheme.secondary, _pickupController, 'Pickup Point'),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(width: 2, height: 20, color: AppTheme.textHint),
                  ),
                  _locationRow(Icons.location_on, AppTheme.accent, _dropController, 'Where to?'),
                ],
              ),
            ),
          ),

          // Bottom action
          if (_dropLocation != null)
            Positioned(
              bottom: 100, left: 16, right: 16,
              child: ElevatedButton.icon(
                onPressed: _showFareEstimate,
                icon: const Icon(Icons.local_taxi),
                label: const Text('Find Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.bgCard,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Parcel'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, TextEditingController ctrl, String hint) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            readOnly: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  void _showFareEstimate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Fare Estimate', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_car, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Car', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('4 Seats • AC', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                  ]),
                  const Text('৳ 330', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🚗 Looking for a driver...'), backgroundColor: AppTheme.primary),
                );
              },
              child: const Text('Book Ride'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
