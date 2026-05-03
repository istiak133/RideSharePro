// ============================================
// Rider Home Screen — Map + Routing + Search
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/location_service.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:rideshare_app/screens/rider/parcel_screen.dart';
import 'dart:async';

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
  
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  int _durationMins = 0;
  
  int _currentIndex = 0;

  final _pickupController = TextEditingController(text: 'Fetching Location...');
  final _dropController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _currentLocation = loc;
        _pickupLocation = loc;
      });
      _mapController.move(loc, 15.0);
      
      final address = await LocationService.getAddressFromLatLng(loc);
      if (mounted) {
        setState(() => _pickupController.text = _shortenAddress(address));
      }
    } else {
      if (mounted) setState(() => _pickupController.text = 'Your Location');
    }
  }

  String _shortenAddress(String address) {
    final parts = address.split(',');
    if (parts.length > 2) return '${parts[0]}, ${parts[1]}';
    return address;
  }

  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _dropLocation == null) return;

    final routeData = await LocationService.getRoute(_pickupLocation!, _dropLocation!);
    if (routeData != null && mounted) {
      setState(() {
        _routePoints = routeData['points'];
        _distanceKm = routeData['distance'] / 1000;
        _durationMins = (routeData['duration'] / 60).round();
      });
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;
    
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(50),
    ));
  }

  void _openSearchModal(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _LocationSearchSheet(
        isPickup: isPickup,
        onSelect: (name, lat, lng) {
          setState(() {
            if (isPickup) {
              _pickupLocation = LatLng(lat, lng);
              _pickupController.text = _shortenAddress(name);
              _mapController.move(_pickupLocation!, 15.0);
            } else {
              _dropLocation = LatLng(lat, lng);
              _dropController.text = _shortenAddress(name);
              _mapController.move(_dropLocation!, 15.0);
            }
          });
          _calculateRoute();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapTab(),
          const Center(child: Text('Trips - Coming Soon', style: TextStyle(color: Colors.white))),
          const ParcelScreen(),
          const Center(child: Text('Profile - Coming Soon', style: TextStyle(color: Colors.white))),
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

  Widget _buildMapTab() {
    return Stack(
      children: [
        // Map
        FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: AppConfig.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              
              // Route Polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Pickup marker
                  if (_pickupLocation != null)
                    Marker(
                      point: _pickupLocation!,
                      width: 50, height: 50,
                      child: const Icon(Icons.circle, color: AppTheme.secondary, size: 20),
                    ),
                  // Drop marker
                  if (_dropLocation != null)
                    Marker(
                      point: _dropLocation!,
                      width: 50, height: 50,
                      child: const Icon(Icons.location_on, color: AppTheme.accent, size: 40),
                    ),
                  // Current GPS indicator (if no pickup selected, or always show)
                  if (_pickupLocation == null)
                    Marker(
                      point: _currentLocation,
                      width: 50, height: 50,
                      child: Container(
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.my_location, color: AppTheme.primary, size: 30),
                      ),
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
                  _locationRow(Icons.circle, AppTheme.secondary, _pickupController, 'Pickup Point', () => _openSearchModal(true)),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(width: 2, height: 20, color: AppTheme.textHint),
                  ),
                  _locationRow(Icons.location_on, AppTheme.accent, _dropController, 'Where to?', () => _openSearchModal(false)),
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
            
            // Recenter Button
          Positioned(
            bottom: _dropLocation != null ? 180 : 100,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.bgCard,
              onPressed: () {
                _mapController.move(_currentLocation, 15.0);
              },
              child: const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
        ],
      );
  }

  Widget _locationRow(IconData icon, Color color, TextEditingController ctrl, String hint, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ctrl,
                readOnly: true,
                onTap: onTap,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFareEstimate() {
    // Bike Fare calculation: Base 30 + 12 per km
    final fare = 30 + (_distanceKm * 12);
    
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
            const SizedBox(height: 8),
            Text('${_distanceKm.toStringAsFixed(1)} km • $_durationMins mins', style: const TextStyle(color: AppTheme.textHint)),
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
                      child: const Icon(Icons.two_wheeler, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bike', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('1 Seat • Quick', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                  ]),
                  Text('৳ ${fare.round()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                );

                try {
                  final reqBody = {
                    'pickup_lat': _pickupLocation!.latitude,
                    'pickup_lng': _pickupLocation!.longitude,
                    'pickup_address': _pickupController.text,
                    'drop_lat': _dropLocation!.latitude,
                    'drop_lng': _dropLocation!.longitude,
                    'drop_address': _dropController.text,
                    'vehicle_type': 'bike', // hardcoded to bike for now
                    'estimated_fare': fare,
                    'estimated_distance': _distanceKm,
                    'estimated_duration': _durationMins,
                  };
                  
                  final res = await ApiService.post('/rides', body: reqBody);
                  
                  if (mounted) {
                    Navigator.pop(context); // close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🏍️ Ride booked! OTP: ${res['data']['pickup_otp']} (Waiting for driver...)'), backgroundColor: AppTheme.primary),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to book ride: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
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

// -----------------------------------------------------
// Search Bottom Sheet UI
// -----------------------------------------------------
class _LocationSearchSheet extends StatefulWidget {
  final bool isPickup;
  final Function(String name, double lat, double lng) onSelect;

  const _LocationSearchSheet({required this.isPickup, required this.onSelect});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (query.isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isSearching = true);
      final results = await LocationService.searchLocation(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.isPickup ? 'Enter Pickup Location' : 'Enter Destination',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 20),
            if (_isSearching) const CircularProgressIndicator()
            else Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(color: AppTheme.bgSurface),
                itemBuilder: (ctx, i) {
                  final item = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: AppTheme.textHint),
                    title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () {
                      widget.onSelect(item['name'], item['lat'], item['lng']);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
