// ============================================
// Driver Home Screen — Go Online + Accept Rides
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/phone_login_screen.dart';
import 'package:rideshare_app/screens/driver/driver_active_ride_screen.dart';
import 'package:rideshare_app/screens/driver/driver_profile_screen.dart';
import 'package:rideshare_app/screens/driver/driver_trips_screen.dart';
import 'package:rideshare_app/services/location_service.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  int _currentIndex = 0;
  LatLng _currentLocation = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  
  RealtimeChannel? _rideChannel;

  @override
  void dispose() {
    _rideChannel?.unsubscribe();
    LocationService.stopTracking();
    super.dispose();
  }

  void _toggleOnline() async {
    if (!_isOnline) {
      // Going online: check permission & start tracking
      final hasPerm = await Geolocator.requestPermission() != LocationPermission.denied; // simplified for demo
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required to go online')),
          );
        }
        return;
      }
      
      LocationService.startTracking((loc) {
        if (mounted) setState(() => _currentLocation = loc);
      });
      _listenForRides();
    } else {
      // Going offline
      LocationService.stopTracking();
      _rideChannel?.unsubscribe();
      _rideChannel = null;
    }
    
    setState(() => _isOnline = !_isOnline);
  }

  void _listenForRides() {
    _rideChannel = Supabase.instance.client
      .channel('public:rides')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'rides',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'status', value: 'searching'),
        callback: (payload) {
          _showIncomingRequest(payload.newRecord);
        },
      )
      .subscribe();
  }

  void _showIncomingRequest(Map<String, dynamic> ride) {
    if (!mounted) return;
    
    // Circular countdown logic can be complex inside showDialog, using simple dialog for now
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse Ring with Icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('New Ride Request!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Locations
              Row(
                children: [
                  const Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(ride['pickup_address'], style: const TextStyle(color: Colors.white, fontSize: 16))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 20, color: AppTheme.textHint)),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(ride['drop_address'], style: const TextStyle(color: Colors.white, fontSize: 16))),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(color: AppTheme.bgSurface),
              const SizedBox(height: 16),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Est. Fare', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('৳${ride['estimated_fare']}', style: const TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Distance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text('${ride['distance']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.bgSurface),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await ApiService.post('/rides/${ride['id']}/accept');
                          if (mounted) {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DriverActiveRideScreen(rideRequest: ride),
                            ));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting ride: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // Map
        FlutterMap(
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: AppConfig.defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rideshareai.app',
            ),
            MarkerLayer(markers: [
              Marker(
                point: _currentLocation,
                width: 60, height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: (_isOnline ? AppTheme.online : AppTheme.textHint).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.drive_eta, color: _isOnline ? AppTheme.online : AppTheme.textHint, size: 30),
                ),
              ),
            ]),
          ],
        ),

        // Status bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: _isOnline ? AppTheme.online : AppTheme.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? AppTheme.online : AppTheme.textHint,
                      fontWeight: FontWeight.w600, fontSize: 16,
                    ),
                  ),
                ]),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.star, color: AppTheme.warning, size: 18),
                      SizedBox(width: 4),
                      Text('4.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Go online/offline button
        Positioned(
          bottom: 100, left: 16, right: 16,
          child: Column(
            children: [
              // Stats row
              if (_isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Today\'s Earnings', '৳ 1,450'),
                      Container(width: 1, height: 30, color: AppTheme.textHint),
                      _statItem('Trips', '6'),
                      Container(width: 1, height: 30, color: AppTheme.textHint),
                      _statItem('Hours', '4.5'),
                    ],
                  ),
                ),

              // Toggle button
              GestureDetector(
                onTap: _toggleOnline,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _isOnline
                        ? const LinearGradient(colors: [AppTheme.accent, Color(0xFFFF8787)])
                        : const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: (_isOnline ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 8),
                    )],
                  ),
                  child: Center(
                    child: Text(
                      _isOnline ? '🔴  Go Offline' : '🟢  Go Online',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const DriverTripsScreen(),
          const DriverProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.bgCard,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}
